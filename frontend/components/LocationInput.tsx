import React from 'react';
import { useTranslation } from 'react-i18next';

interface LocationInputProps {
  value: string;
  onChange: (val: string) => void;
}

const LocationInput: React.FC<LocationInputProps> = ({ value, onChange }) => {
  const { t } = useTranslation();
  return (
    <div>
      <label htmlFor="location-input" className="block text-sm font-medium text-slate-400 mb-1">{t('location.label')}</label>
      <input
        id="location-input"
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={t('location.placeholder')}
        className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-all"
      />
    </div>
  );
};

export default LocationInput;