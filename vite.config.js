import { defineConfig } from 'vite';
export default defineConfig({
  base: './',                        // works on Vercel, subpaths, and file://
  build: { target: 'es2020', outDir: 'dist', sourcemap: true, assetsInlineLimit: 4096 },
  server: { host: true, port: 5173 }
});
