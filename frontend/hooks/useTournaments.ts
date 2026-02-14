import { useState, useCallback } from 'react';
import { Tournament, UnifiedSearchResponse } from '../types';
import { TournamentService } from '../services/tournamentService';

export const useTournaments = () => {
  const [query, setQuery] = useState('');
  const [radius, setRadius] = useState(50);
  const [selectedGameIds, setSelectedGameIds] = useState<number[]>([]);
  const [loading, setLoading] = useState(false);
  const [tournaments, setTournaments] = useState<Tournament[]>([]);
  const [center, setCenter] = useState<[number, number]>([37.7749, -122.4194]);
  const [locationName, setLocationName] = useState('San Francisco, CA');
  const [error, setError] = useState<string | null>(null);

  const toggleGameId = useCallback((id: number) => {
    setSelectedGameIds(prev => 
      prev.includes(id) ? prev.filter(gid => gid !== id) : [...prev, id]
    );
  }, []);

  const handleSearch = useCallback(async () => {
    if (!query) return;
    setLoading(true);
    setError(null);

    try {
      const response = await TournamentService.search({
        query: query,
        radius: radius,
        gameIds: selectedGameIds.length > 0 ? selectedGameIds : undefined
      });

      setCenter([response.center.lat, response.center.lng]);
      setLocationName(response.displayName);
      
      const sorted = response.tournaments.sort((a, b) => parseInt(a.date) - parseInt(b.date));
      setTournaments(sorted);
      
      if (window.innerWidth < 768) {
        setTimeout(() => {
          document.getElementById('results-heading')?.scrollIntoView({ behavior: 'smooth' });
        }, 150);
      }
    } catch (err: any) {
      setError(err.message || "Failed to find tournaments.");
      setTournaments([]);
    } finally {
      setLoading(false);
    }
  }, [query, radius, selectedGameIds]);

  return {
    query, setQuery,
    radius, setRadius,
    selectedGameIds, toggleGameId,
    loading, tournaments,
    center, locationName,
    error, handleSearch
  };
};