import React, { useState } from 'react';
import { POPULAR_GAMES } from '../types';

interface GameFilterProps {
  selectedGameIds: number[];
  toggleGameId: (id: number) => void;
}

const GameFilter: React.FC<GameFilterProps> = ({ selectedGameIds, toggleGameId }) => {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <div className="border border-slate-700/50 rounded-xl overflow-hidden bg-slate-900/20">
      <button 
        onClick={() => setIsExpanded(!isExpanded)}
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
          className={`w-4 h-4 transition-transform duration-300 ${isExpanded ? 'rotate-180' : ''}`} 
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isExpanded && (
        <div className="p-3 border-t border-slate-700/50">
          <div className="max-h-[260px] overflow-y-auto pr-1 game-filter-scroll">
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
      <style dangerouslySetInnerHTML={{ __html: `
        .game-filter-scroll::-webkit-scrollbar { width: 4px; }
        .game-filter-scroll::-webkit-scrollbar-track { background: rgba(30, 41, 59, 0.5); border-radius: 10px; }
        .game-filter-scroll::-webkit-scrollbar-thumb { background: rgba(99, 102, 241, 0.5); border-radius: 10px; }
        .game-filter-scroll::-webkit-scrollbar-thumb:hover { background: rgba(99, 102, 241, 0.8); }
      `}} />
    </div>
  );
};

export default GameFilter;