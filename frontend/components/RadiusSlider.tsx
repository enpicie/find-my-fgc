import React from 'react';
import { useTranslation } from 'react-i18next';

interface RadiusSliderProps {
  value: number;
  onChange: (val: number) => void;
}

const RadiusSlider: React.FC<RadiusSliderProps> = ({ value, onChange }) => {
  const { t } = useTranslation();
  return (
  <div>
    <label className="block text-sm font-medium text-slate-400 mb-1">
      <span className="text-indigo-400 font-bold">{t('radius.label', { value })}</span>
    </label>
    <input
      type="range"
      min="5"
      max="200"
      step="5"
      value={value}
      onChange={(e) => onChange(parseInt(e.target.value))}
      className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-indigo-500"
    />
  </div>
  );
};

export default RadiusSlider;