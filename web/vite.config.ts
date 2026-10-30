import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// The catalog site (docs/beaconkit.md › Site): public/ holds what `npm run collect` writes (data, renders).
export default defineConfig({
  plugins: [react()],
  server: { port: 5180, open: false },
})
