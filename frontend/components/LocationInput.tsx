import React from 'react';

interface LocationInputProps {
  value: string;
  onChange: (val: string) => void;
}

const LocationInput: React.FC<LocationInputProps> = ({ value, onChange }) => (
  <div>
    <label className="block text-sm font-medium text-slate-400 mb-1">Your Location</label>
    <input
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder="Zip code, City, or State..."
      className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-all"
    />
  </div>
);

export default LocationInput;