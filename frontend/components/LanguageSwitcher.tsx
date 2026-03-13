import React from 'react';
import { useTranslation } from 'react-i18next';
import { SUPPORTED_LANGUAGES } from '../i18n';

const LanguageSwitcher: React.FC = () => {
  const { i18n } = useTranslation();

  const currentLang = SUPPORTED_LANGUAGES.find(
    (l) => l.code === i18n.resolvedLanguage || i18n.language.startsWith(l.code)
  ) ?? SUPPORTED_LANGUAGES[0];

  return (
    <div className="relative">
      <select
        value={currentLang.code}
        onChange={(e) => i18n.changeLanguage(e.target.value)}
        aria-label="Select language"
        className="appearance-none bg-slate-800 border border-slate-700 text-slate-300 hover:text-white text-xs font-medium rounded-lg pl-2.5 pr-5 py-1.5 cursor-pointer transition-colors hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
      >
        {SUPPORTED_LANGUAGES.map((lang) => (
          <option key={lang.code} value={lang.code}>
            {lang.label}
          </option>
        ))}
      </select>
      <svg
        className="pointer-events-none absolute right-1.5 top-1/2 -translate-y-1/2 w-3 h-3 text-slate-500"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
      </svg>
    </div>
  );
};

export default LanguageSwitcher;
