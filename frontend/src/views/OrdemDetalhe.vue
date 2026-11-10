<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../services/api'
import { useLoad } from '../composables'
import { brl, dt, STATUS, CANCELAVEIS, TIMELINE } from '../utils'
import StatusBadge from '../components/StatusBadge.vue'

const route = useRoute()
const { data: o, erro, recarregar } = useLoad(() => api.ordem(route.params.id), 1500)
const msg = ref('')

// Passos do ciclo de vida: feitos, atual e pendentes
const passos = computed(() => {
  if (!o.value) return []
  const feitos = Object.fromEntries(o.value.eventos.map((e) => [e.status, e]))
  const base = TIMELINE.map((s) => ({ s, e: feitos[s] }))
  const extras = o.value.eventos.filter((e) => !TIMELINE.includes(e.status)).map((e) => ({ s: e.status, e }))
  const lista = [...base.filter((p) => p.e), ...extras.filter((p) => p.s !== 'REJEITADA' || true)]
  const final = ['REJEITADA', 'CANCELADA'].includes(o.value.status)
  return final ? lista : [...lista, ...base.filter((p) => !p.e)]
})
const classe = (p) => (!p.e ? '' : p.s === 'REJEITADA' || p.s === 'CANCELADA' ? 'bad' : p.e === o.value.eventos.at(-1) && o.value.status !== 'EXECUTADA' ? 'now' : 'done')

async function cancelar() {
  if (!confirm('Cancelar esta ordem?')) return
  try { await api.cancelarOrdem(o.value.id); msg.value = ''; await recarregar() } catch (e) { msg.value = e.message }
}
</script>

<template>
  <main class="page">
    <RouterLink to="/ordens" class="link small">← Ordens</RouterLink>
    <p v-if="erro" class="down">{{ erro }}</p>
    <p v-else-if="!o" class="muted">Carregando…</p>
    <template v-else>
      <div class="row between">
        <h1>{{ o.id }} · {{ o.tipo === 'COMPRA' ? 'Compra' : 'Venda' }} de {{ o.ticker }}</h1>
        <StatusBadge :status="o.status" />
      </div>
      <div v-if="o.motivoRejeicao" class="card alert err">Motivo da rejeição: {{ o.motivoRejeicao }}</div>
      <div class="grid3">
        <div class="card"><span class="muted small">QUANTIDADE</span><div class="kpi">{{ o.quantidadeExecutada }}/{{ o.quantidade }}</div></div>
        <div class="card"><span class="muted small">PREÇO LIMITE</span><div class="kpi">{{ brl(o.precoLimite) }}</div></div>
        <div class="card"><span class="muted small">PREÇO DE EXECUÇÃO</span><div class="kpi">{{ o.precoExecucao ? brl(o.precoExecucao) : '—' }}</div></div>
      </div>
      <div class="card">
        <h2>Ciclo de vida</h2>
        <ul class="tl">
          <li v-for="p in passos" :key="p.s" :class="classe(p)">
            <strong>{{ STATUS[p.s][0] }}</strong>
            <div v-if="p.e" class="muted small">{{ dt(p.e.em) }}<span v-if="p.e.detalhe"> · {{ p.e.detalhe }}</span></div>
            <div v-else class="muted small">Aguardando…</div>
          </li>
        </ul>
        <p v-if="msg" class="down">{{ msg }}</p>
        <button v-if="CANCELAVEIS.includes(o.status)" class="btn danger" @click="cancelar">Cancelar ordem</button>
      </div>
      <p class="muted small">Criada em {{ dt(o.criadoEm) }}</p>
    </template>
  </main>
</template>
