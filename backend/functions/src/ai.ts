import Anthropic from '@anthropic-ai/sdk';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/https';
import { defineSecret, defineString } from 'firebase-functions/params';
import { z } from 'zod';

import { db } from './admin.js';
import { rateLimit, requireCouple, requireUid } from './lib.js';

const anthropicKey = defineSecret('ANTHROPIC_API_KEY');
const aiModel = defineString('AI_MODEL', { default: 'claude-opus-5-5', description: 'Claude model that writes question decks' });

export const THEMES = ['fun', 'deep', 'future', 'memories'] as const;
export type Theme = (typeof THEMES)[number];

const THEME_HINTS: Record<Theme, string> = {
  fun: 'light, playful questions that make both people laugh',
  deep: 'warm, thoughtful questions about feelings, values and what matters to them',
  future: 'hopeful questions about plans, dreams and the life they are building',
  memories: 'nostalgic questions that invite them to relive shared moments',
};

const SYSTEM = `You write "question of the day" prompts for a private couples app.
Both partners answer the same question privately; answers are revealed when both have replied.

Write questions that:
- are addressed to one partner about the two of them ("we", "us", "me", "you");
- fit on one phone line or two (under 140 characters) and end with a question mark;
- are kind and inclusive: no assumptions about gender, marriage, children, money or living together;
- are safe for work: nothing sexual, no therapy-style probing of conflict or trauma.

Return only the JSON object described by the schema.`;

/** JSON schema for structured output: `{ "questions": string[] }`. */
const OUTPUT_SCHEMA = {
  type: 'object',
  properties: { questions: { type: 'array', items: { type: 'string' } } },
  required: ['questions'],
  additionalProperties: false,
} as const;

const Deck = z.object({ questions: z.array(z.string()) });

/** Trims, de-duplicates and drops anything that isn't a short question. */
export function cleanQuestions(raw: string[], avoid: Iterable<string>, max: number): string[] {
  const seen = new Set([...avoid].map((q) => q.trim().toLowerCase()));
  const out: string[] = [];
  for (const q of raw) {
    const text = q.replace(/\s+/g, ' ').trim();
    const key = text.toLowerCase();
    if (text.length < 12 || text.length > 160 || !text.endsWith('?') || seen.has(key)) continue;
    seen.add(key);
    out.push(text);
    if (out.length === max) break;
  }
  return out;
}

/**
 * Asks Claude for [count] questions on [theme]. Only the theme and earlier
 * prompts are sent: never messages, answers or anything personal.
 */
export async function writeQuestions(client: Anthropic, model: string, theme: Theme, count: number, avoid: string[]): Promise<string[]> {
  const response = await client.beta.messages.create({
    model,
    max_tokens: 16000,
    // A declined request is retried on Anthropic's recommended fallback model.
    betas: ['server-side-fallback-2026-07-01'],
    fallbacks: 'default',
    output_config: { effort: 'low', format: { type: 'json_schema', schema: OUTPUT_SCHEMA } },
    system: SYSTEM,
    messages: [
      {
        role: 'user',
        content: [
          `Write ${count} questions. Theme: ${theme} (${THEME_HINTS[theme]}).`,
          avoid.length > 0 ? `Don't repeat or closely paraphrase these recent questions:\n${avoid.map((q) => `- ${q}`).join('\n')}` : '',
        ]
          .filter(Boolean)
          .join('\n\n'),
      },
    ],
  });
  if (response.stop_reason === 'refusal') throw new HttpsError('unavailable', 'Couldn’t write new questions right now. Try another theme.');
  if (response.stop_reason === 'max_tokens') throw new HttpsError('internal', 'The question writer ran out of room. Try again.');
  const text = response.content.map((block) => (block.type === 'text' ? block.text : '')).join('');
  let parsed: z.infer<typeof Deck>;
  try {
    parsed = Deck.parse(JSON.parse(text));
  } catch (e) {
    logger.error('Unexpected question deck output', { error: String(e) });
    throw new HttpsError('internal', 'Couldn’t read the new questions. Try again.');
  }
  return cleanQuestions(parsed.questions, avoid, count);
}

/**
 * Queues fresh AI-written daily questions for the couple (max 3 decks a day).
 * Request: `{ theme }`. Response: `{ questions }`.
 */
export const generateQuestions = onCall<{ theme?: unknown }>({ secrets: [anthropicKey], timeoutSeconds: 120 }, async (request) => {
  const uid = requireUid(request);
  const couple = await requireCouple(uid);
  const theme = request.data?.theme;
  if (typeof theme !== 'string' || !(THEMES as readonly string[]).includes(theme)) {
    throw new HttpsError('invalid-argument', `Pick a theme: ${THEMES.join(', ')}.`);
  }
  const coupleRef = db.collection('couples').doc(couple.id);
  await rateLimit(coupleRef, 'ai', 3, 24 * 60 * 60 * 1000);
  const recent = [...((couple.data.recentPrompts ?? []) as string[]), ...((couple.data.promptQueue ?? []) as string[])].slice(-40);

  const client = new Anthropic({ apiKey: anthropicKey.value() });
  let questions: string[];
  try {
    questions = await writeQuestions(client, aiModel.value(), theme as Theme, 7, recent);
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    if (e instanceof Anthropic.RateLimitError) throw new HttpsError('resource-exhausted', 'Lots of couples are asking right now. Try again in a minute.');
    if (e instanceof Anthropic.AuthenticationError) {
      logger.error('Anthropic API key rejected');
      throw new HttpsError('failed-precondition', 'AI questions aren’t set up on the server yet.');
    }
    if (e instanceof Anthropic.APIConnectionError) throw new HttpsError('unavailable', 'Couldn’t reach the question writer. Try again.');
    if (e instanceof Anthropic.APIError) {
      logger.error('Anthropic API error', { status: e.status, message: e.message });
      throw new HttpsError('internal', 'Couldn’t write new questions right now.');
    }
    throw e;
  }
  if (questions.length === 0) throw new HttpsError('internal', 'Couldn’t write new questions right now.');

  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(coupleRef);
    const queue = (fresh.get('promptQueue') ?? []) as string[];
    tx.update(coupleRef, { promptQueue: [...queue, ...questions].slice(0, 30) });
  });
  return { questions };
});
