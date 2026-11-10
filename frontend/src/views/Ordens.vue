<script setup>
import { ref, watch } from 'vue'
import { api } from '../services/api'
import { useLoad } from '../composables'
import { dt, brl, STATUS, CANCELAVEIS } from '../utils'
import StatusBadge from '../components/StatusBadge.vue'

const aba = ref('todas'), status = ref(''), tipo = ref(''), msg = ref('')
const { data: lista, erro, carregando, recarregar } = useLoad(() => api.ordens({ aba: aba.value, status: status.value, tipo: tipo.value }), 2500)
watch([aba, status, tipo], recarregar)

async function cancelar(o) {
  if (!confirm(`Cancelar a ordem ${o.id}?`)) return
  msg.value = ''
  try { await api.cancelarOrdem(o.id); await recarregar() } catch (e) { msg.value = e.message }
}
</script>

<template>
  <main class="page">
    <h1>Ordens</h1>
    <div class="tabs">
      <button :class="{ on: aba === 'todas' }" @click="aba = 'todas'">Todas</button>
      <button :class="{ on: aba === 'andamento' }" @click="aba = 'andamento'">Em andamento</button>
      <button :class="{ on: aba === 'historico' }" @click="aba = 'historico'">Histórico</button>
    </div>
    <div class="filters">
      <select v-model="status" class="input"><option value="">Todos os status</option><option v-for="(s, k) in STATUS" :key="k" :value="k">{{ s[0] }}</option></select>
      <select v-model="tipo" class="input"><option value="">Compra e venda</option><option value="COMPRA">Compra</option><option value="VENDA">Venda</option></select>
    </div>
    <p v-if="msg" class="down">{{ msg }}</p>
    <p v-if="erro" class="down">{{ erro }}</p>
    <p v-else-if="carregando" class="muted">Carregando…</p>
    <div v-else class="card tablewrap"><table>
      <thead><tr><th>Ordem</th><th>Ativo</th><th>Tipo</th><th class="r">Executado</th><th class="r">Preço limite</th><th>Status</th><th>Data</th><th></th></tr></thead>
      <tbody>
        <tr v-for="o in lista" :key="o.id">
          <td><RouterLink :to="`/ordens/${o.id}`" class="link">{{ o.id }}</RouterLink></td>
          <td>{{ o.ticker }}</td><td :class="o.tipo === 'COMPRA' ? 'up' : 'down'">{{ o.tipo }}</td>
          <td class="r">{{ o.quantidadeExecutada }}/{{ o.quantidade }}</td><td class="r">{{ brl(o.precoLimite) }}</td>
          <td><StatusBadge :status="o.status" /></td><td class="muted">{{ dt(o.criadoEm) }}</td>
          <td><button v-if="CANCELAVEIS.includes(o.status)" class="btn ghost" @click="cancelar(o)">Cancelar</button></td>
        </tr>
        <tr v-if="!lista?.length"><td colspan="8" class="muted">Nenhuma ordem encontrada.</td></tr>
      </tbody>
    </table></div>
  </main>
</template>
