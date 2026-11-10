<script setup>
import { api } from '../services/api'
import { useLoad } from '../composables'
import { dt } from '../utils'

const { data: lista, erro, carregando, recarregar } = useLoad(() => api.notificacoes(), 3000)
async function abrir(n) {
  if (!n.lida) { await api.marcarLida(n.id); recarregar() }
}
</script>

<template>
  <main class="page">
    <h1>Notificações</h1>
    <p v-if="erro" class="down">{{ erro }}</p>
    <p v-else-if="carregando" class="muted">Carregando…</p>
    <p v-else-if="!lista.length" class="muted">Nenhuma notificação por enquanto.</p>
    <div v-for="n in lista" :key="n.id" class="card" :style="{ opacity: n.lida ? .65 : 1 }" @click="abrir(n)">
      <div class="row between">
        <span><span v-if="!n.lida" class="dot">novo</span> {{ n.mensagem }}</span>
        <span class="muted small">{{ dt(n.criadaEm) }}</span>
      </div>
      <RouterLink v-if="n.ordemId" :to="`/ordens/${n.ordemId}`" class="link small">Ver ordem {{ n.ordemId }}</RouterLink>
    </div>
  </main>
</template>
