import { describe, it, expect, vi, beforeEach } from 'vitest';
import { TournamentService } from '../../frontend/services/tournamentService';

describe('TournamentService', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  it('should call fetch with correct parameters', async () => {
    const mockResponse = {
      tournaments: [],
      center: { lat: 0, lng: 0 },
      displayName: 'Test City'
    };

    (fetch as any).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve(mockResponse)
    });

    const params = { query: 'San Francisco', radius: 50, gameIds: [1, 2] };
    await TournamentService.search(params);

    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining('/tournaments'),
      expect.objectContaining({
        method: 'POST'
      })
    );
  });
});