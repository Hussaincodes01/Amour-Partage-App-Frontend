import type Anthropic from '@anthropic-ai/sdk';
import { HttpsError } from 'firebase-functions/https';
import { describe, expect, it, vi } from 'vitest';

import { cleanQuestions, writeQuestions } from '../../src/ai.js';

/** A stand-in client whose beta.messages.create returns [response]. */
function fakeClient(response: Record<string, unknown>) {
  const create = vi.fn().mockResolvedValue(response);
  return { client: { beta: { messages: { create } } } as unknown as Anthropic, create };
}

describe('cleanQuestions', () => {
  it('keeps short, new questions only', () => {
    const out = cleanQuestions(
      ['  What makes you  smile? ', 'What makes you smile?', 'Too short?', 'Not a question.', 'Which city should we explore next?', 'x'.repeat(170) + '?'],
      ['Which city should we explore next?'],
      5,
    );
    expect(out).toEqual(['What makes you smile?']);
  });

  it('stops at the requested count', () => {
    const many = Array.from({ length: 10 }, (_, i) => `What is our favourite thing number ${i}?`);
    expect(cleanQuestions(many, [], 3)).toHaveLength(3);
  });
});

describe('writeQuestions', () => {
  it('asks for structured JSON with a server-side fallback and parses it', async () => {
    const { client, create } = fakeClient({
      stop_reason: 'end_turn',
      content: [{ type: 'text', text: JSON.stringify({ questions: ['What song reminds you of our first date?', 'Where should we go this summer?'] }) }],
    });
    const out = await writeQuestions(client, 'claude-opus-5-5', 'fun', 2, ['Old question?']);
    expect(out).toEqual(['What song reminds you of our first date?', 'Where should we go this summer?']);
    const params = create.mock.calls[0][0];
    expect(params.model).toBe('claude-opus-5-5');
    expect(params.fallbacks).toBe('default');
    expect(params.betas).toEqual(['server-side-fallback-2026-07-01']);
    expect(params.output_config.format.type).toBe('json_schema');
    expect(params.messages[0].content).toContain('Old question?');
    // Only the theme and earlier prompts are ever sent.
    expect(JSON.stringify(params.messages)).not.toMatch(/answer|message text/i);
  });

  it('reports refusals and bad output as user-facing errors', async () => {
    await expect(writeQuestions(fakeClient({ stop_reason: 'refusal', content: [] }).client, 'm', 'deep', 3, [])).rejects.toBeInstanceOf(HttpsError);
    await expect(
      writeQuestions(fakeClient({ stop_reason: 'end_turn', content: [{ type: 'text', text: 'not json' }] }).client, 'm', 'deep', 3, []),
    ).rejects.toBeInstanceOf(HttpsError);
  });
});
