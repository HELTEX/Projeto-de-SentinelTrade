import { createApp } from 'vue'
import '@fontsource/cormorant-garamond/400.css'
import '@fontsource/cormorant-garamond/500.css'
import '@fontsource/cormorant-garamond/600.css'
import './styles.css'
import App from './App.vue'
import router from './router'
import { hooks } from './services/api'
import { clearSession } from './store/session'

hooks.unauthorized = () => { clearSession(); router.push({ path: '/login', query: { expirou: '1' } }) }
hooks.forbidden = () => router.push('/403')
hooks.unavailable = () => router.push('/indisponivel')

createApp(App).use(router).mount('#app')
