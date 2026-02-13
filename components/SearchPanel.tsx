
import React from 'react';
import { POPULAR_GAMES } from '../types';

interface SearchPanelProps {
  location: string;
  setLocation: (val: string) => void;
  radius: number;
  setRadius: (val: number) => void;
  selectedGameIds: number[];
  toggleGameId: (id: number) => void;
  onSearch: () => void;
  loading: boolean;
}

const SearchPanel: React.FC<SearchPanelProps> = ({
  location,
  setLocation,
  radius,
  setRadius,
  selectedGameIds,
  toggleGameId,
  onSearch,
  loading
}) => {
  return (
    <div className="bg-slate-800 p-6 rounded-xl shadow-xl flex flex-col gap-6">
      <div>
        <h2 className="text-xl font-bold mb-4 text-indigo-400">Search Tournaments</h2>
        <div className="space-y-6">
          {/* Location Input */}
          <div>
            <label className="block text-sm font-medium text-slate-400 mb-1">Your Location</label>
            <input
              type="text"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              placeholder="Zip code, City, or State..."
              className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-all"
            />
          </div>

          {/* Radius Slider */}
          <div>
            <label className="block text-sm font-medium text-slate-400 mb-1">
              Search Radius: <span className="text-indigo-400 font-bold">{radius} miles</span>
            </label>
            <input
              type="range"
              min="5"
              max="200"
              step="5"
              value={radius}
              onChange={(e) => setRadius(parseInt(e.target.value))}
              className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-indigo-500"
            />
          </div>

          {/* Game Selection */}
          <div>
            <label className="block text-sm font-medium text-slate-400 mb-2">Filter by Games (Optional)</label>
            <div className="flex flex-wrap gap-2">
              {POPULAR_GAMES.map((game) => {
                const isSelected = selectedGameIds.includes(game.id);
                return (
                  <button
                    key={game.id}
                    onClick={() => toggleGameId(game.id)}
                    className={`text-xs px-3 py-1.5 rounded-full border transition-all flex items-center gap-1.5 ${
                      isSelected
                        ? 'bg-indigo-600 border-indigo-500 text-white shadow-md shadow-indigo-900/40'
                        : 'bg-slate-700 border-slate-600 text-slate-300 hover:border-slate-500'
                    }`}
                  >
                    <span>{game.emoji}</span>
                    {game.name}
                  </button>
                );
              })}
            </div>
          </div>

          <button
            onClick={onSearch}
            disabled={loading || !location}
            className={`w-full py-3 rounded-lg font-bold transition-all ${
              loading || !location
                ? 'bg-slate-600 text-slate-400 cursor-not-allowed'
                : 'bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-900/20'
            }`}
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Searching...
              </span>
            ) : 'Find Events'}
          </button>
        </div>
      </div>
      
      <div className="mt-auto text-xs text-slate-500 border-t border-slate-700 pt-4">
        Powered by start.gg & Gemini
      </div>
    </div>
  );
};

export default SearchPanel;
