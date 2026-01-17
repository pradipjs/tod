import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    // Reduce memory usage during build
    chunkSizeWarningLimit: 1000,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
        },
      },
    },
    // Reduce parallel processing to avoid memory issues in Docker
    minify: 'esbuild',
    target: 'esnext',
  },
  esbuild: {
    // Reduce esbuild's resource usage
    logOverride: { 'this-is-undefined-in-esm': 'silent' },
  },
})
