import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'node:path'

export default defineConfig({
  plugins: [react()],
  resolve: { alias: { '@business-login-entry': resolve(process.cwd(), 'src/v2/business-login-main.jsx') } },
  build: {
    rollupOptions: {
      input: {
        index: resolve(process.cwd(), 'v2-preview.html'),
        businessLogin: resolve(process.cwd(), 'business-login.html'),
      },
      output: {
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash][extname]',
      },
    },
  },
})
