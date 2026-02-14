import React, { useState } from 'react';
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
  const [isGamesExpanded, setIsGamesExpanded] = useState(false);

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
          <div className="border border-slate-700/50 rounded-xl overflow-hidden bg-slate-900/20">
            <button 
              onClick={() => setIsGamesExpanded(!isGamesExpanded)}
              className="w-full flex items-center justify-between p-3 text-sm font-medium text-slate-400 hover:bg-slate-700/30 transition-colors"
            >
              <div className="flex items-center gap-2">
                <span>Filter by Games</span>
                {selectedGameIds.length > 0 && (
                  <span className="bg-indigo-600 text-white text-[10px] px-1.5 py-0.5 rounded-full font-bold">
                    {selectedGameIds.length}
                  </span>
                )}
              </div>
              <svg 
                className={`w-4 h-4 transition-transform duration-300 ${isGamesExpanded ? 'rotate-180' : ''}`} 
                fill="none" 
                stroke="currentColor" 
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>

            {isGamesExpanded && (
              <div className="p-3 border-t border-slate-700/50">
                <div className="max-h-[260px] overflow-y-auto pr-1 custom-scrollbar">
                  <div className="grid grid-cols-3 gap-2">
                    {POPULAR_GAMES.map((game) => {
                      const isSelected = selectedGameIds.includes(game.id);
                      return (
                        <button
                          key={game.id}
                          onClick={() => toggleGameId(game.id)}
                          className={`relative flex flex-col items-center p-2 rounded-xl border-2 transition-all group ${
                            isSelected
                              ? 'bg-indigo-600/20 border-indigo-500 ring-2 ring-indigo-500/20'
                              : 'bg-slate-700/50 border-slate-600 hover:border-slate-500 hover:bg-slate-700'
                          }`}
                        >
                          <div className="h-10 w-full flex items-center justify-center mb-1.5 overflow-hidden">
                            <img 
                              src={game.imageUrl} 
                              alt={game.name} 
                              className={`max-h-full max-w-full object-contain transition-transform duration-300 ${
                                isSelected ? 'scale-110 drop-shadow-[0_0_8px_rgba(99,102,241,0.8)]' : 'opacity-70 group-hover:opacity-100'
                              }`}
                            />
                          </div>
                          <span className={`text-[9px] text-center font-bold leading-tight line-clamp-2 uppercase tracking-tighter ${
                            isSelected ? 'text-indigo-300' : 'text-slate-500 group-hover:text-slate-300'
                          }`}>
                            {game.name}
                          </span>
                          
                          {isSelected && (
                            <div className="absolute -top-1 -right-1 bg-indigo-500 text-white rounded-full p-0.5 shadow-lg z-10">
                              <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 20 20">
                                <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                              </svg>
                            </div>
                          )}
                        </button>
                      );
                    })}
                  </div>
                </div>
              </div>
            )}
          </div>

          <button
            onClick={onSearch}
            disabled={loading || !location}
            className={`w-full py-4 rounded-xl font-black text-sm uppercase tracking-widest transition-all ${
              loading || !location
                ? 'bg-slate-600 text-slate-400 cursor-not-allowed'
                : 'bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-900/40 transform active:scale-[0.98]'
            }`}
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Scanning...
              </span>
            ) : 'Locate Tournaments'}
          </button>
        </div>
      </div>
      
      <div className="mt-auto text-[10px] text-slate-500 border-t border-slate-700 pt-4 flex justify-between items-center">
        <span>API v1.5</span>
        <span className="font-mono opacity-50 uppercase tracking-widest italic">Start.gg Hybrid Engine</span>
      </div>

      <style dangerouslySetInnerHTML={{ __html: `
        .custom-scrollbar::-webkit-scrollbar {
          width: 4px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: rgba(30, 41, 59, 0.5);
          border-radius: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: rgba(99, 102, 241, 0.5);
          border-radius: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: rgba(99, 102, 241, 0.8);
        }
      `}} />
    </div>
  );
};

export default SearchPanel;
