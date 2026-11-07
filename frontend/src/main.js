import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores/useAuthStore'
import './assets/styles/tokens.css'
import './assets/styles/base.css'

const app = createApp(App)
const pinia = createPinia()
app.use(pinia)

// Restore the Supabase session BEFORE installing Vue Router. Installing the
// router starts its initial navigation and runs auth guards immediately.
// If that happens before getSession() completes, a valid user can be sent to
// /login on every refresh even though persistSession is enabled.
const auth = useAuthStore(pinia)
await auth.initialize()

app.use(router)
await router.isReady()
app.mount('#app')

if ('serviceWorker' in navigator && import.meta.env.PROD) {
  window.addEventListener('load', () => navigator.serviceWorker.register('/sw.js').catch((error) => console.warn('Service worker registration failed:', error)))
}
