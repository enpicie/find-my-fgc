import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath } from 'url';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, '.', '');
  return {
    server: {
      port: 3000,
      host: '0.0.0.0',
    },
    plugins: [react()],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./frontend', import.meta.url)),
      },
    },
    define: {
      // GOOGLE_MAPS_API_KEY is backend-only — never expose it in the browser bundle.
      'process.env.VITE_BACKEND_URL': JSON.stringify(env.VITE_BACKEND_URL),
      'process.env.VITE_APP_VERSION': JSON.stringify(env.VITE_APP_VERSION ?? 'local'),
    },
  };
});
