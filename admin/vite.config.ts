import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    chunkSizeWarningLimit: 1000,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
        },
      },
      // Limit parallel processing
      maxParallelFileOps: 1,
    },
    minify: 'esbuild',
    target: 'esnext',
    sourcemap: false,
  },
  esbuild: {
    logOverride: { 'this-is-undefined-in-esm': 'silent' },
    // Use single core for low-resource servers
    loader: { '.js': 'jsx', '.ts': 'tsx' },
  },
})
