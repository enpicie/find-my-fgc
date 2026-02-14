
import React, { useState, useCallback } from 'react';
import { Tournament } from './types';
import { performUnifiedSearch } from './services/backendService';
import SearchPanel from './components/SearchPanel';
import TournamentCard from './components/TournamentCard';
import Map from './components/Map';

const App: React.FC = () => {
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
      // Single call to the backend which handles everything
      const response = await performUnifiedSearch({
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
      console.error("Search failed:", err);
      setError(err.message || "Failed to find tournaments.");
      setTournaments([]);
    } finally {
      setLoading(false);
    }
  }, [query, radius, selectedGameIds]);

  return (
    <div className="flex flex-col min-h-screen md:h-screen md:overflow-hidden bg-slate-950 font-sans">
      <header className="bg-slate-900 border-b border-slate-800 p-4 shrink-0 flex items-center justify-between z-40 sticky top-0 md:relative">
        <div className="flex items-center gap-3">
          <div className="bg-indigo-600 p-1.5 rounded-lg text-white font-bold text-lg leading-none">FG</div>
          <div>
            <h1 className="text-lg md:text-2xl font-black bg-clip-text text-transparent bg-gradient-to-r from-indigo-400 to-purple-400 tracking-tight">
              FindMyFGC
            </h1>
            <div className="text-[10px] text-slate-500 font-mono flex items-center gap-1 uppercase">
              Secure Cloud Mode
            </div>
          </div>
        </div>
      </header>

      <main className="flex flex-col md:flex-row flex-grow min-h-0 relative">
        <div className="w-full md:w-96 flex flex-col border-r border-slate-800 bg-slate-900 md:overflow-y-auto p-4 md:p-6 gap-6 shrink-0 z-20 shadow-2xl order-2 md:order-1">
          <SearchPanel 
            location={query}
            setLocation={setQuery}
            radius={radius}
            setRadius={setRadius}
            selectedGameIds={selectedGameIds}
            toggleGameId={toggleGameId}
            onSearch={handleSearch}
            loading={loading}
          />

          {error && (
            <div className="bg-red-900/20 border border-red-500/50 p-3 rounded-lg text-red-400 text-xs">
              {error}
            </div>
          )}

          <div className="flex flex-col gap-4 pb-24 md:pb-4">
            <div id="results-heading" className="flex justify-between items-center scroll-mt-20">
              <h2 className="text-lg font-bold text-slate-300">Events ({tournaments.length})</h2>
            </div>
            
            {tournaments.length === 0 && !loading && (
              <div className="bg-slate-800/50 border border-dashed border-slate-700 rounded-lg p-8 text-center flex flex-col items-center">
                <div className="text-3xl mb-3 opacity-30">📍</div>
                <p className="text-slate-400 text-sm">Search for a location.</p>
              </div>
            )}

            {loading && (
              <div className="space-y-4 animate-pulse">
                {[1, 2, 3].map(i => <div key={i} className="bg-slate-800 h-32 rounded-lg border border-slate-700" />)}
              </div>
            )}

            <div className="space-y-4">
              {tournaments.map((t) => <TournamentCard key={t.id} tournament={t} />)}
            </div>
          </div>
        </div>

        <div className="h-[300px] md:h-full w-full md:flex-grow relative z-10 order-1 md:order-2 border-b md:border-b-0 border-slate-800 shrink-0">
          <div className="absolute top-3 left-3 z-[1000] bg-slate-900/90 border border-slate-700 px-3 py-1.5 rounded-full shadow-lg text-[10px] md:text-xs font-bold text-indigo-300 flex items-center gap-2 pointer-events-none">
            <span className="w-1.5 h-1.5 bg-indigo-500 rounded-full animate-pulse"></span>
            {locationName}
          </div>
          <Map center={center} zoom={11} tournaments={tournaments} />
        </div>
      </main>
    </div>
  );
};

export default App;
