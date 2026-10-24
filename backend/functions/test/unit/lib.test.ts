import { describe, expect, it } from 'vitest';

import { DAILY_PROMPTS } from '../../src/decks.js';
import { INVITE_ALPHABET, dayKey, formatInviteCode, isPublicKey, newInviteCode, normalizeInviteCode, stableIndex } from '../../src/lib.js';

describe('invite codes', () => {
  it('are 8 unambiguous characters', () => {
    for (let i = 0; i < 200; i++) {
      const code = newInviteCode();
      expect(code).toHaveLength(8);
      expect([...code].every((c) => INVITE_ALPHABET.includes(c))).toBe(true);
    }
    expect(INVITE_ALPHABET).not.toMatch(/[01OIL]/);
  });

  it('format and normalise', () => {
    expect(formatInviteCode('ABCD2345')).toBe('ABCD-2345');
    expect(normalizeInviteCode('abcd-2345')).toBe('ABCD2345');
    expect(normalizeInviteCode(' ABCD 2345 ')).toBe('ABCD2345');
    expect(normalizeInviteCode('ABCD-234')).toBeNull();
    expect(normalizeInviteCode('ABCD-0000')).toBeNull();
    expect(normalizeInviteCode(42)).toBeNull();
  });
});

describe('public keys', () => {
  it('accept 32-byte base64 keys only', () => {
    expect(isPublicKey(Buffer.alloc(32, 7).toString('base64'))).toBe(true);
    expect(isPublicKey(Buffer.alloc(31, 7).toString('base64'))).toBe(false);
    expect(isPublicKey(Buffer.alloc(33, 7).toString('base64'))).toBe(false);
    expect(isPublicKey('not a key')).toBe(false);
    expect(isPublicKey(undefined)).toBe(false);
  });
});

describe('daily questions', () => {
  it('use the UTC day as id', () => {
    expect(dayKey(new Date('2026-10-24T23:30:00Z'))).toBe('2026-10-24');
  });

  it('pick the same prompt for the same couple and day', () => {
    expect(stableIndex('c1:2026-10-24', 40)).toBe(stableIndex('c1:2026-10-24', 40));
    const spread = new Set(Array.from({ length: 50 }, (_, i) => stableIndex(`c${i}:2026-10-24`, DAILY_PROMPTS.length)));
    expect(spread.size).toBeGreaterThan(15);
  });

  it('deck has unique questions', () => {
    expect(new Set(DAILY_PROMPTS).size).toBe(DAILY_PROMPTS.length);
    expect(DAILY_PROMPTS.every((p) => p.endsWith('?') && p.length < 140)).toBe(true);
  });
});
