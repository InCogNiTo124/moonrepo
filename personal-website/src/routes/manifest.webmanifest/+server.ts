import { icon192, icon512 } from 'personal-reusables';

/**
 * Served as a route rather than a file in static/ so the icons resolve to the
 * hashed URLs Vite emits for personal-reusables' assets, instead of needing a
 * second copy of the PNGs in this project's static/ directory.
 */
export const prerender = true;

/** @type {import('./$types').RequestHandler} */
export function GET(): Response {
  const manifest = {
    name: "Marijan Smetko's Personal Site",
    short_name: "Smetko's Site",
    start_url: '/',
    display: 'minimal-ui',
    background_color: '#ffffff',
    theme_color: '#333333',
    icons: [
      { src: icon192, sizes: '192x192', type: 'image/png' },
      { src: icon512, sizes: '512x512', type: 'image/png' }
    ]
  };

  return new Response(JSON.stringify(manifest), {
    headers: { 'content-type': 'application/manifest+json' }
  });
}
