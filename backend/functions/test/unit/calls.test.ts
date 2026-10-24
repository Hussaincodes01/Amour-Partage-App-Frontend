import { describe, expect, it } from 'vitest';

import { callToken } from '../../src/calls.js';

function claims(jwt: string): Record<string, unknown> {
  return JSON.parse(Buffer.from(jwt.split('.')[1], 'base64url').toString('utf8'));
}

describe('LiveKit call tokens', () => {
  it('grant only the couple’s own room', async () => {
    const jwt = await callToken('c1', 'alice', 'Alice', 'APIkey', 'a-secret-that-is-long-enough-for-signing');
    const c = claims(jwt);
    expect(c.sub).toBe('alice');
    expect(c.name).toBe('Alice');
    expect(c.video).toMatchObject({ room: 'couple_c1', roomJoin: true, canPublish: true, canSubscribe: true });
    const lifetime = (c.exp as number) - (c.nbf as number);
    expect(lifetime).toBeLessThanOrEqual(4 * 60 * 60);
  });
});
