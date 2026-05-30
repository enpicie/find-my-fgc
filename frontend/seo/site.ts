/** Production site URL (no trailing slash). Override at build time via VITE_SITE_URL. */
export const SITE_URL =
  (typeof process !== 'undefined' && process.env.VITE_SITE_URL) ||
  'https://www.findmyfgc.cc';

export const SITE_NAME = 'FindMyFGC';

/** Default OG/Twitter image (served from site root). */
export const OG_IMAGE_PATH = '/logo.png';

export function absoluteUrl(path = ''): string {
  const normalized = path.startsWith('/') ? path : path ? `/${path}` : '';
  return `${SITE_URL}${normalized}`;
}
