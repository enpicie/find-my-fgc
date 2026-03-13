import React, { createContext, useContext, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import { useTranslation } from 'react-i18next';

import faqEn from '../content/faq.en.md?raw';
import faqEs from '../content/faq.es.md?raw';
import faqPtBR from '../content/faq.pt-BR.md?raw';
import faqFr from '../content/faq.fr.md?raw';
import faqDe from '../content/faq.de.md?raw';
import faqKo from '../content/faq.ko.md?raw';
import faqJa from '../content/faq.ja.md?raw';
import faqZhCN from '../content/faq.zh-CN.md?raw';
import faqZhTW from '../content/faq.zh-TW.md?raw';

const FAQ_CONTENT: Record<string, string> = {
  en:      faqEn,
  es:      faqEs,
  'pt-BR': faqPtBR,
  fr:      faqFr,
  de:      faqDe,
  ko:      faqKo,
  ja:      faqJa,
  'zh-CN': faqZhCN,
  'zh-TW': faqZhTW,
};

interface FAQProps {
  onBack: () => void;
  scrollTo?: string;
}

function slugify(text: string): string {
  return String(text).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

const InsideBlockquote = createContext(false);

const FAQ: React.FC<FAQProps> = ({ onBack, scrollTo }) => {
  const { t, i18n } = useTranslation();

  const faqContent = FAQ_CONTENT[i18n.resolvedLanguage ?? 'en'] ?? faqEn;

  useEffect(() => {
    if (scrollTo) {
      const el = document.getElementById(scrollTo);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
        el.classList.add('heading-highlight');
        el.addEventListener('animationend', () => el.classList.remove('heading-highlight'), { once: true });
      }
    } else {
      window.scrollTo(0, 0);
    }
  }, []);

  return (
    <>
      <div className="sticky top-[84px] md:top-0 z-30 bg-slate-950 border-b border-slate-800 px-4 py-2.5">
        <div className="max-w-2xl mx-auto">
          <button
            onClick={onBack}
            className="flex items-center gap-1.5 text-xs text-slate-400 hover:text-indigo-400 transition-colors"
          >
            <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
            {t('faq.back')}
          </button>
        </div>
      </div>
      <main className="flex-grow flex justify-center px-4 py-8 md:py-12 overflow-y-auto">
      <article className="w-full max-w-2xl">
        <ReactMarkdown
          components={{
            h2: ({ children }) => {
              const id = slugify(String(children));
              return (
                <h2 id={id} className="text-xl font-bold mt-8 mb-3 text-indigo-400 first:mt-0">{children}</h2>
              );
            },
            p: ({ children }) => {
              const inBlockquote = useContext(InsideBlockquote);
              return (
                <p className={`text-sm leading-relaxed ${inBlockquote ? 'text-slate-300' : 'text-slate-300 mb-4'}`}>
                  {children}
                </p>
              );
            },
            em: ({ children }) => (
              <em className="text-slate-500 not-italic text-xs">{children}</em>
            ),
            blockquote: ({ children }) => (
              <InsideBlockquote.Provider value={true}>
                <div className="my-4 rounded-lg bg-slate-800/50 border border-slate-700/60 overflow-hidden">
                  <div className="px-4 py-2 border-b border-slate-700/60 flex items-center gap-2">
                    <span className="text-[10px] font-mono uppercase tracking-widest text-indigo-400/60">{t('faq.noteFrom')}</span>
                  </div>
                  <div className="px-4 py-3 space-y-3">
                    {children}
                  </div>
                </div>
              </InsideBlockquote.Provider>
            ),
            ul: ({ children }) => (
              <ul className="mb-4 space-y-1.5 pl-4">{children}</ul>
            ),
            li: ({ children }) => (
              <li className="text-sm text-slate-300 leading-relaxed list-disc list-inside">{children}</li>
            ),
            strong: ({ children }) => (
              <strong className="text-slate-100 font-semibold">{children}</strong>
            ),
            a: ({ href, children }) => (
              <a
                href={href}
                target="_blank"
                rel="noopener noreferrer"
                className="text-indigo-400 hover:text-indigo-300 underline underline-offset-2 transition-colors"
              >
                {children}
              </a>
            ),
          }}
        >
          {faqContent}
        </ReactMarkdown>
      </article>
      </main>
    </>
  );
};

export default FAQ;
