import React from 'react';
import { useTranslation } from 'react-i18next';
import LocationInput from './LocationInput';
import RadiusSlider from './RadiusSlider';
import GameFilter from './GameFilter';
import SearchButton from './SearchButton';

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
  const { t } = useTranslation();
  return (
    <div className="bg-slate-800 p-6 rounded-xl shadow-xl flex flex-col gap-6">
      <div>
        <h2 className="text-xl font-bold mb-4 text-indigo-400">{t('search.heading')}</h2>
        <div className="space-y-6">
          <LocationInput value={location} onChange={setLocation} />
          <RadiusSlider value={radius} onChange={setRadius} />
          <GameFilter selectedGameIds={selectedGameIds} toggleGameId={toggleGameId} />
          <SearchButton onClick={onSearch} disabled={loading || !location} loading={loading} />
        </div>
      </div>
      <div className="mt-auto text-[10px] text-slate-500 border-t border-slate-700 pt-4 flex justify-between items-center">
        <span>{process.env.VITE_APP_VERSION}</span>
        <a href="#faq" className="hover:text-indigo-400 transition-colors uppercase tracking-widest font-mono font-bold text-slate-400">{t('search.faq')}</a>
      </div>
    </div>
  );
};

export default SearchPanel;
