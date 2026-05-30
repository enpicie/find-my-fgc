import { useEffect, useState } from 'react';

export type AppPage = 'home' | 'faq';

function pageFromPathname(): AppPage {
  const path = window.location.pathname.replace(/\/$/, '') || '/';
  return path === '/faq' ? 'faq' : 'home';
}

function scrollTargetFromHash(): string | undefined {
  const id = window.location.hash.slice(1);
  return id || undefined;
}

/** Migrate bookmarks from `/#faq` to `/faq`. */
function redirectLegacyHashRoute() {
  if (window.location.hash.slice(1) !== 'faq') return;
  const path = window.location.pathname.replace(/\/$/, '') || '/';
  if (path !== '/') return;
  window.history.replaceState(null, '', '/faq');
}

export function usePathRoute() {
  const [page, setPage] = useState<AppPage>(() => {
    redirectLegacyHashRoute();
    return pageFromPathname();
  });
  const [faqScrollTarget, setFaqScrollTarget] = useState<string | undefined>(() =>
    pageFromPathname() === 'faq' ? scrollTargetFromHash() : undefined
  );

  useEffect(() => {
    const sync = () => {
      setPage(pageFromPathname());
      setFaqScrollTarget(pageFromPathname() === 'faq' ? scrollTargetFromHash() : undefined);
    };
    window.addEventListener('popstate', sync);
    window.addEventListener('hashchange', sync);
    return () => {
      window.removeEventListener('popstate', sync);
      window.removeEventListener('hashchange', sync);
    };
  }, []);

  const navigate = (to: '/' | '/faq', scrollTarget?: string) => {
    const url = scrollTarget && to === '/faq' ? `/faq#${scrollTarget}` : to;
    window.history.pushState(null, '', url);
    setPage(pageFromPathname());
    setFaqScrollTarget(pageFromPathname() === 'faq' ? scrollTargetFromHash() : undefined);
  };

  return { page, navigate, faqScrollTarget };
}
