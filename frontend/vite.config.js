import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// Em modo real (VITE_USE_MOCK=false), as chamadas /api vao para o BFF.
export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    proxy: { '/api': { target: process.env.VITE_BFF_URL || 'http://localhost:3000', changeOrigin: true } }
  }
})
