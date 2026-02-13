
import React, { useState, useCallback } from 'react';
import { Tournament, GeocodeResult } from './types';
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

  const toggleGameId = useCallback((id: number) => {
    setSelectedGameIds(prev => 
      prev.includes(id) ? prev.filter(gid => gid !== id) : [...prev, id]
    );
  }, []);

  const handleSearch = useCallback(async () => {
    if (!query) return;
    setLoading(true);

    try {
      // 1. Geocode with Gemini
      const geocode = await geocodeLocation(query);
      setCenter([geocode.lat, geocode.lng]);
      setLocationName(geocode.displayName);

      // 2. Fetch from start.gg via Swift Backend
      const results = await fetchTournaments({
        lat: geocode.lat,
        lng: geocode.lng,
        radius: radius,
        gameIds: selectedGameIds.length > 0 ? selectedGameIds : undefined
      });

      // Sort by date (ascending)
      const sorted = results.sort((a, b) => parseInt(a.date) - parseInt(b.date));
      setTournaments(sorted);
    } catch (err) {
      console.error("Search failed:", err);
      setTournaments([]);
    } finally {
      setLoading(false);
    }
  }, [query, radius, selectedGameIds]);

  return (
    <div className="flex flex-col h-screen max-h-screen overflow-hidden">
      {/* Header */}
      <header className="bg-slate-900 border-b border-slate-800 p-4 shrink-0 flex items-center justify-between z-10">
        <div className="flex items-center gap-3">
          <div className="bg-indigo-600 p-2 rounded-lg text-white font-bold text-xl leading-none">FG</div>
          <h1 className="text-2xl font-black bg-clip-text text-transparent bg-gradient-to-r from-indigo-400 to-purple-400 tracking-tight">
            FindMyFGC
          </h1>
        </div>
        <div className="text-slate-500 text-sm hidden md:block">
          Discover local tournaments on <span className="text-indigo-400 font-bold">start.gg</span>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-grow flex flex-col md:flex-row overflow-hidden relative">
        
        {/* Left Sidebar: Controls & List */}
        <div className="w-full md:w-96 flex flex-col border-r border-slate-800 bg-slate-900 overflow-y-auto p-4 gap-6 scrollbar-hide shrink-0 z-20 shadow-2xl">
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

          <div className="flex flex-col gap-4">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-bold text-slate-300">Events found ({tournaments.length})</h2>
              {tournaments.length > 0 && <span className="text-xs text-slate-500">Sorted by date</span>}
            </div>
            
            {tournaments.length === 0 && !loading && (
              <div className="bg-slate-800/50 border border-dashed border-slate-700 rounded-lg p-10 text-center flex flex-col items-center">
                <div className="text-4xl mb-4">📍</div>
                <p className="text-slate-400 text-sm">Enter a location to find gaming events in your area.</p>
              </div>
            )}

            {loading && (
              <div className="space-y-4 animate-pulse">
                {[1, 2, 3].map(i => (
                  <div key={i} className="bg-slate-800 h-32 rounded-lg" />
                ))}
              </div>
            )}

            <div className="space-y-4">
              {tournaments.map((t) => (
                <TournamentCard key={t.id} tournament={t} />
              ))}
            </div>
          </div>
        </div>

        {/* Center/Right: Map View */}
        <div className="flex-grow relative z-0">
          <div className="absolute top-4 left-4 z-[400] bg-slate-900/90 border border-slate-700 px-4 py-2 rounded-full shadow-lg text-xs font-bold text-indigo-300 flex items-center gap-2">
            <span className="w-2 h-2 bg-indigo-500 rounded-full animate-pulse"></span>
            Viewing: {locationName}
          </div>
          <Map 
            center={center} 
            zoom={11} 
            tournaments={tournaments} 
          />
        </div>
      </main>
    </div>
  );
};

export default App;
