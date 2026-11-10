<script setup>
import { ref } from 'vue'
import { api } from '../services/api'
import { useLoad } from '../composables'
import { TIPOS } from '../utils'

const { data: s, erro, recarregar } = useLoad(() => api.adminEstado())
const msg = ref(''), ok = ref(true)
async function acao(fn, texto) {
  try { await fn(); msg.value = texto; ok.value = true; await recarregar() } catch (e) { msg.value = e.message; ok.value = false }
}
</script>

<template>
  <main class="page">
    <h1>Administração</h1>
    <p v-if="msg" :class="ok ? 'up' : 'down'">{{ msg }}</p>
    <p v-if="erro" class="down">{{ erro }}</p>
    <p v-else-if="!s" class="muted">Carregando…</p>
    <template v-else>
      <div class="card">
        <h2>Modo seguro</h2>
        <p class="muted">Bloqueia novas ordens (indisponibilidade controlada). Ordens já enviadas continuam sendo processadas.</p>
        <label class="toggle"><input type="checkbox" :checked="s.modoSeguro" @change="acao(() => api.setModoSeguro($event.target.checked), 'Modo seguro atualizado.')" /> {{ s.modoSeguro ? 'Ativado' : 'Desativado' }}</label>
      </div>

      <div class="card">
        <h2>Mercado por ativo</h2>
        <div class="tablewrap"><table>
          <thead><tr><th>Ativo</th><th>Tipo</th><th>Mercado</th><th></th></tr></thead>
          <tbody>
            <tr v-for="a in s.ativos" :key="a.ticker">
              <td><strong>{{ a.ticker }}</strong></td><td>{{ TIPOS[a.tipo] }}</td>
              <td><span class="badge" :class="a.mercado === 'ABERTO' ? 'up' : 'muted'">{{ a.mercado === 'ABERTO' ? 'Aberto' : 'Fechado' }}</span></td>
              <td><button class="btn ghost" @click="acao(() => api.setMercado(a.ticker, a.mercado === 'ABERTO' ? 'FECHADO' : 'ABERTO'), `Mercado de ${a.ticker} atualizado.`)">{{ a.mercado === 'ABERTO' ? 'Fechar' : 'Abrir' }}</button></td>
            </tr>
          </tbody>
        </table></div>
      </div>

      <div class="card">
        <h2>Limites de risco por investidor</h2>
        <div v-for="i in s.investidores" :key="i.id" style="margin-bottom:1.2rem">
          <strong>{{ i.nome }}</strong> <span class="muted small">{{ i.email }}</span>
          <div class="filters" style="margin:.5rem 0">
            <label class="small muted">Por ordem (R$)<input v-model.number="i.limites.porOrdem" type="number" class="input" /></label>
            <label class="small muted">Diário (R$)<input v-model.number="i.limites.diario" type="number" class="input" /></label>
            <label class="small muted">Ordens/dia<input v-model.number="i.limites.ordensDia" type="number" class="input" /></label>
            <button class="btn" style="align-self:end" @click="acao(() => api.setLimites(i.id, i.limites), `Limites de ${i.nome} salvos.`)">Salvar</button>
          </div>
        </div>
      </div>
    </template>
  </main>
</template>
