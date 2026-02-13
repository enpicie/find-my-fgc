
import React, { useState, useCallback } from 'react';
import { Tournament } from './types';
import { geocodeLocation } from './services/geminiService';
import { fetchTournaments } from './services/backendService';
import SearchPanel from './components/SearchPanel';
import TournamentCard from './components/TournamentCard';
import Map from './components/Map';

const App: React.FC = () => {
  const [query, setQuery] = useState('');
  const [radius, setRadius] = useState(50);
  const [selectedGameIds, setSelectedGameIds] = useState<number[]>([]);
  const [loading, setLoading] = useState(false);
  const [tournaments, setTournaments] = useState<Tournament[]>([]);
  const [center, setCenter] = useState<[number, number]>([37.7749, -122.4194]); // Default SF
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
      const geocode = await geocodeLocation(query);
      setCenter([geocode.lat, geocode.lng]);
      setLocationName(geocode.displayName);

      const results = await fetchTournaments({
        lat: geocode.lat,
        lng: geocode.lng,
        radius: radius,
        gameIds: selectedGameIds.length > 0 ? selectedGameIds : undefined
      });

      const sorted = results.sort((a, b) => parseInt(a.date) - parseInt(b.date));
      setTournaments(sorted);
    } catch (err: any) {
      console.error("Search failed:", err);
      setError(err.message || "Failed to find tournaments.");
      setTournaments([]);
    } finally {
      setLoading(false);
    }
  }, [query, radius, selectedGameIds]);

  return (
    <div className="flex flex-col h-screen max-h-screen overflow-hidden bg-slate-950">
      {/* Header */}
      <header className="bg-slate-900 border-b border-slate-800 p-4 shrink-0 flex items-center justify-between z-40">
        <div className="flex items-center gap-3">
          <div className="bg-indigo-600 p-1.5 md:p-2 rounded-lg text-white font-bold text-lg md:text-xl leading-none">FG</div>
          <h1 className="text-lg md:text-2xl font-black bg-clip-text text-transparent bg-gradient-to-r from-indigo-400 to-purple-400 tracking-tight">
            FindMyFGC
          </h1>
        </div>
        <div className="text-slate-500 text-xs md:text-sm hidden sm:block">
          Events via <span className="text-indigo-400 font-bold">start.gg</span>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-grow flex flex-col md:flex-row overflow-hidden relative">
        
        {/* Map View: Top on mobile, Right on desktop */}
        <div className="flex-none h-[250px] sm:h-[300px] md:h-full w-full md:flex-grow relative z-10 order-1 md:order-2 border-b md:border-b-0 border-slate-800">
          <div className="absolute top-3 left-3 z-[1000] bg-slate-900/90 border border-slate-700 px-3 py-1.5 rounded-full shadow-lg text-[10px] md:text-xs font-bold text-indigo-300 flex items-center gap-2 pointer-events-none">
            <span className="w-1.5 h-1.5 bg-indigo-500 rounded-full animate-pulse"></span>
            {locationName}
          </div>
          <Map 
            center={center} 
            zoom={11} 
            tournaments={tournaments} 
          />
        </div>

        {/* Sidebar: Bottom on mobile, Left on desktop */}
        <div className="flex-grow md:flex-none w-full md:w-96 flex flex-col border-r border-slate-800 bg-slate-900 overflow-y-auto p-4 gap-6 scrollbar-thin scrollbar-thumb-slate-700 shrink-0 z-20 shadow-2xl order-2 md:order-1">
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

          <div className="flex flex-col gap-4">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-bold text-slate-300">Events ({tournaments.length})</h2>
              {tournaments.length > 0 && <span className="text-[10px] uppercase tracking-wider text-slate-500 font-bold">Upcoming</span>}
            </div>
            
            {tournaments.length === 0 && !loading && (
              <div className="bg-slate-800/50 border border-dashed border-slate-700 rounded-lg p-8 text-center flex flex-col items-center">
                <div className="text-3xl mb-3 opacity-30">📍</div>
                <p className="text-slate-400 text-sm">Enter a location to see events.</p>
              </div>
            )}

            {loading && (
              <div className="space-y-4 animate-pulse">
                {[1, 2, 3].map(i => (
                  <div key={i} className="bg-slate-800 h-32 rounded-lg border border-slate-700" />
                ))}
              </div>
            )}

            <div className="space-y-4 pb-8">
              {tournaments.map((t) => (
                <TournamentCard key={t.id} tournament={t} />
              ))}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default App;
