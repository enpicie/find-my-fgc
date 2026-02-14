import React from 'react';

interface SearchButtonProps {
  onClick: () => void;
  disabled: boolean;
  loading: boolean;
}

const SearchButton: React.FC<SearchButtonProps> = ({ onClick, disabled, loading }) => (
  <button
    onClick={onClick}
    disabled={disabled}
    className={`w-full py-4 rounded-xl font-black text-sm uppercase tracking-widest transition-all ${
      disabled
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
);

export default SearchButton;