import React from 'react';
import { Tournament } from '../types';

interface TournamentCardProps {
  tournament: Tournament;
}

const TournamentCard: React.FC<TournamentCardProps> = ({ tournament }) => {
  const dateObj = new Date(parseInt(tournament.date) * 1000);
  const formattedDate = dateObj.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  });

  return (
    <div className="bg-slate-800 border border-slate-700 rounded-lg overflow-hidden flex flex-col sm:flex-row gap-4 hover:border-indigo-500/50 transition-colors group">
      <div className="w-full sm:w-32 h-32 flex-shrink-0 relative bg-slate-900">
        {tournament.image ? (
          <img src={tournament.image} alt={tournament.name} className="w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-slate-600 text-4xl">🎮</div>
        )}
      </div>
      <div className="p-4 flex flex-col justify-between flex-grow">
        <div>
          <h3 className="text-lg font-bold text-white group-hover:text-indigo-400 transition-colors line-clamp-1">{tournament.name}</h3>
          <p className="text-sm text-indigo-300 font-medium mb-1">{formattedDate}</p>
          <p className="text-sm text-slate-400 line-clamp-1">{tournament.location}</p>
          {tournament.games && (
            <p className="text-xs text-indigo-400/80 mt-1 font-semibold line-clamp-1">
              Games: {tournament.games}
            </p>
          )}
          <p className="text-xs text-slate-500 line-clamp-1 italic mt-1">{tournament.venueAddress}</p>
        </div>
        <div className="mt-4 flex justify-end">
          <a 
            href={tournament.externalUrl} 
            target="_blank" 
            rel="noopener noreferrer"
            className="text-xs bg-slate-700 hover:bg-slate-600 text-slate-200 px-3 py-1.5 rounded transition-colors"
          >
            Details
          </a>
        </div>
      </div>
    </div>
  );
};

export default TournamentCard;
