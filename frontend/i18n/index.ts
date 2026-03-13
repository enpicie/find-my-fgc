import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

import en from './locales/en/translation.json';
import es from './locales/es/translation.json';
import ptBR from './locales/pt-BR/translation.json';
import fr from './locales/fr/translation.json';
import ko from './locales/ko/translation.json';
import ja from './locales/ja/translation.json';
import zhCN from './locales/zh-CN/translation.json';
import zhTW from './locales/zh-TW/translation.json';
import de from './locales/de/translation.json';

export const SUPPORTED_LANGUAGES = [
  { code: 'en',    label: 'English'   },
  { code: 'es',    label: 'Español'   },
  { code: 'pt-BR', label: 'Português' },
  { code: 'fr',    label: 'Français'  },
  { code: 'de',    label: 'Deutsch'   },
  { code: 'ko',    label: '한국어'     },
  { code: 'ja',    label: '日本語'     },
  { code: 'zh-CN', label: '简体中文'   },
  { code: 'zh-TW', label: '繁體中文'   },
] as const;

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      en:      { translation: en },
      es:      { translation: es },
      'pt-BR': { translation: ptBR },
      fr:      { translation: fr },
      de:      { translation: de },
      ko:      { translation: ko },
      ja:      { translation: ja },
      'zh-CN': { translation: zhCN },
      'zh-TW': { translation: zhTW },
    },
    fallbackLng: 'en',
    supportedLngs: ['en', 'es', 'pt-BR', 'fr', 'de', 'ko', 'ja', 'zh-CN', 'zh-TW'],
    // Map regional variants to supported languages (e.g. pt-PT → pt-BR)
    nonExplicitSupportedLngs: false,
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
    },
    interpolation: {
      // React already escapes values — no double-escaping needed
      escapeValue: false,
    },
  });

// Keep the HTML lang attribute in sync for accessibility and SEO
i18n.on('languageChanged', (lng) => {
  document.documentElement.lang = lng;
});

export default i18n;
