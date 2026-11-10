<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { session, clearSession } from '../store/session'
import { api } from '../services/api'

const router = useRouter()
const q = ref('')
const naoLidas = ref(0)
const logado = computed(() => !!session.token)
const perfil = computed(() => session.user?.perfil)
let t

async function carregar() {
  if (!logado.value || perfil.value !== 'INVESTIDOR') return (naoLidas.value = 0)
  try { naoLidas.value = (await api.notificacoes()).filter((n) => !n.lida).length } catch {}
}
onMounted(() => { carregar(); t = setInterval(carregar, 4000) })
onUnmounted(() => clearInterval(t))

function buscar() {
  if (!logado.value || perfil.value !== 'INVESTIDOR') return router.push('/login')
  router.push({ path: '/cotacoes', query: { q: q.value } })
}
async function sair() {
  try { await api.logout() } catch {}
  clearSession(); router.push('/')
}
</script>

<template>
  <header class="nav">
    <RouterLink v-if="logado" to="/" class="nav-logo">Sentinel Trade</RouterLink>
    <form class="nav-search" @submit.prevent="buscar">
      <input v-model="q" class="input" placeholder="Pesquisar" aria-label="Pesquisar" />
    </form>

    <nav v-if="!logado" class="nav-links">
      <RouterLink :to="{ path: '/', hash: '#produtos' }">Produtos</RouterLink>
      <RouterLink :to="{ path: '/', hash: '#mercados' }">Mercados</RouterLink>
      <RouterLink :to="{ path: '/', hash: '#corretoras' }">Corretoras</RouterLink>
      <RouterLink :to="{ path: '/', hash: '#mais' }">Mais</RouterLink>
    </nav>
    <nav v-else class="nav-links">
      <template v-if="perfil === 'INVESTIDOR'">
        <RouterLink to="/dashboard">Dashboard</RouterLink>
        <RouterLink to="/cotacoes">Cotações</RouterLink>
        <RouterLink to="/ordens">Ordens</RouterLink>
        <RouterLink to="/carteira">Carteira</RouterLink>
        <RouterLink to="/notificacoes">Notificações<span v-if="naoLidas" class="dot">{{ naoLidas }}</span></RouterLink>
      </template>
      <RouterLink v-if="perfil === 'AUDITOR' || perfil === 'ADMIN'" to="/auditoria">Auditoria</RouterLink>
      <RouterLink v-if="perfil === 'ADMIN'" to="/admin">Administração</RouterLink>
    </nav>

    <RouterLink v-if="!logado" to="/login" class="btn">Entrar</RouterLink>
    <div v-else class="nav-user">
      <span class="muted small">{{ session.user?.nome }}</span>
      <button class="btn" @click="sair">Sair</button>
    </div>
  </header>
</template>
