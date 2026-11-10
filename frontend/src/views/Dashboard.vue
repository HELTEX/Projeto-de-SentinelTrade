<script setup>
import { api } from '../services/api'
import { session } from '../store/session'
import { useLoad } from '../composables'
import { brl, pct, dt, cor } from '../utils'
import StatusBadge from '../components/StatusBadge.vue'

const { data: d, erro } = useLoad(() => api.dashboard(), 3000)
</script>

<template>
  <main class="page">
    <h1>Olá, {{ session.user?.nome }}</h1>
    <p v-if="erro" class="down">{{ erro }}</p>
    <p v-else-if="!d" class="muted">Carregando…</p>
    <template v-else>
      <div class="grid3">
        <div class="card"><span class="muted small">PATRIMÔNIO</span><div class="kpi">{{ brl(d.patrimonio) }}</div></div>
        <div class="card"><span class="muted small">SALDO DISPONÍVEL</span><div class="kpi">{{ brl(d.saldoDisponivel) }}</div></div>
        <div class="card"><span class="muted small">SALDO BLOQUEADO</span><div class="kpi">{{ brl(d.saldoBloqueado) }}</div></div>
      </div>

      <div class="card">
        <div class="row between"><h2>Ordens recentes</h2><RouterLink to="/ordens" class="link">Ver todas</RouterLink></div>
        <p v-if="!d.ordensRecentes.length" class="muted">Você ainda não enviou ordens.</p>
        <div v-else class="tablewrap"><table>
          <thead><tr><th>Ordem</th><th>Ativo</th><th>Tipo</th><th class="r">Qtd</th><th>Status</th><th>Data</th></tr></thead>
          <tbody>
            <tr v-for="o in d.ordensRecentes" :key="o.id" class="click" @click="$router.push(`/ordens/${o.id}`)">
              <td>{{ o.id }}</td><td>{{ o.ticker }}</td><td :class="o.tipo === 'COMPRA' ? 'up' : 'down'">{{ o.tipo }}</td>
              <td class="r">{{ o.quantidade }}</td><td><StatusBadge :status="o.status" /></td><td class="muted">{{ dt(o.criadoEm) }}</td>
            </tr>
          </tbody>
        </table></div>
      </div>

      <div class="card">
        <div class="row between"><h2>Em destaque</h2><RouterLink to="/cotacoes" class="link">Ver cotações</RouterLink></div>
        <div class="grid3">
          <RouterLink v-for="a in d.destaques" :key="a.ticker" :to="`/ativos/${a.ticker}`" class="card" style="margin:0">
            <h3>{{ a.ticker }}</h3><div>{{ brl(a.preco) }}</div><div :class="cor(a.variacao)">{{ pct(a.variacao) }}</div>
          </RouterLink>
        </div>
      </div>
    </template>
  </main>
</template>
