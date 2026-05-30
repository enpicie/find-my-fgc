import { useEffect } from 'react';
import { absoluteUrl, OG_IMAGE_PATH, SITE_NAME, SITE_URL } from './site';

export interface PageSeo {
  title: string;
  description: string;
  /** Path segment after origin, e.g. `faq` for `/faq`. Omit for home. */
  path?: string;
  noindex?: boolean;
}

function upsertMeta(
  selector: string,
  create: () => HTMLMetaElement,
  content: string
) {
  let el = document.querySelector<HTMLMetaElement>(selector);
  if (!el) {
    el = create();
    document.head.appendChild(el);
  }
  el.content = content;
}

function upsertLink(rel: string, href: string) {
  let el = document.querySelector<HTMLLinkElement>(`link[rel="${rel}"]`);
  if (!el) {
    el = document.createElement('link');
    el.rel = rel;
    document.head.appendChild(el);
  }
  el.href = href;
}

export function usePageSeo({ title, description, path, noindex = false }: PageSeo) {
  useEffect(() => {
    const canonical = absoluteUrl(path ? `/${path}` : '/');
    const image = absoluteUrl(OG_IMAGE_PATH);

    document.title = title;

    upsertMeta('meta[name="description"]', () => {
      const m = document.createElement('meta');
      m.name = 'description';
      return m;
    }, description);

    upsertMeta('meta[name="robots"]', () => {
      const m = document.createElement('meta');
      m.name = 'robots';
      return m;
    }, noindex ? 'noindex, nofollow' : 'index, follow');

    upsertLink('canonical', canonical);

    const og = (property: string, content: string) =>
      upsertMeta(`meta[property="${property}"]`, () => {
        const m = document.createElement('meta');
        m.setAttribute('property', property);
        return m;
      }, content);

    og('og:type', 'website');
    og('og:site_name', SITE_NAME);
    og('og:title', title);
    og('og:description', description);
    og('og:url', canonical);
    og('og:image', image);

    upsertMeta('meta[name="twitter:card"]', () => {
      const m = document.createElement('meta');
      m.name = 'twitter:card';
      return m;
    }, 'summary');

    upsertMeta('meta[name="twitter:title"]', () => {
      const m = document.createElement('meta');
      m.name = 'twitter:title';
      return m;
    }, title);

    upsertMeta('meta[name="twitter:description"]', () => {
      const m = document.createElement('meta');
      m.name = 'twitter:description';
      return m;
    }, description);

    upsertMeta('meta[name="twitter:image"]', () => {
      const m = document.createElement('meta');
      m.name = 'twitter:image';
      return m;
    }, image);
  }, [title, description, path, noindex]);
}

/** JSON-LD for crawlers (injected into document head, not visible on page). */
export function getWebApplicationJsonLd(description: string): string {
  return JSON.stringify({
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'WebSite',
        '@id': `${SITE_URL}/#website`,
        url: SITE_URL,
        name: SITE_NAME,
        description,
        inLanguage: 'en',
      },
      {
        '@type': 'WebApplication',
        '@id': `${SITE_URL}/#app`,
        name: SITE_NAME,
        url: SITE_URL,
        description,
        applicationCategory: 'GameApplication',
        operatingSystem: 'Web',
        offers: {
          '@type': 'Offer',
          price: '0',
          priceCurrency: 'USD',
        },
        featureList: [
          'Find local FGC events near you',
          'Map view of fighting game tournaments',
          'Filter by game title',
          'Search radius by miles',
        ],
      },
    ],
  });
}
