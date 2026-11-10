<script setup>
import { api } from '../services/api'
import { useLoad } from '../composables'
import { brl, pct, num, cor } from '../utils'

const { data: c, erro } = useLoad(() => api.carteira(), 3000)
</script>

<template>
  <main class="page">
    <h1>Carteira</h1>
    <p v-if="erro" class="down">{{ erro }}</p>
    <p v-else-if="!c" class="muted">Carregando…</p>
    <template v-else>
      <div class="grid3">
        <div class="card"><span class="muted small">SALDO DISPONÍVEL</span><div class="kpi">{{ brl(c.saldoDisponivel) }}</div></div>
        <div class="card"><span class="muted small">SALDO BLOQUEADO</span><div class="kpi">{{ brl(c.saldoBloqueado) }}</div><div class="muted small">Reservado em ordens abertas</div></div>
      </div>
      <div class="card">
        <h2>Posições</h2>
        <p v-if="!c.posicoes.length" class="muted">Você ainda não possui ativos.</p>
        <div v-else class="tablewrap"><table>
          <thead><tr><th>Ativo</th><th class="r">Qtd</th><th class="r">Preço médio</th><th class="r">Preço atual</th><th class="r">Valor atual</th><th class="r">Resultado</th></tr></thead>
          <tbody>
            <tr v-for="p in c.posicoes" :key="p.ticker" class="click" @click="$router.push(`/ativos/${p.ticker}`)">
              <td><strong>{{ p.ticker }}</strong> <span class="muted small">{{ p.nome }}</span></td>
              <td class="r">{{ p.quantidade }}</td><td class="r">{{ brl(p.precoMedio) }}</td><td class="r">{{ brl(p.precoAtual) }}</td>
              <td class="r">{{ brl(p.valorAtual) }}</td><td class="r" :class="cor(p.resultado)">{{ brl(p.resultado) }} ({{ pct(p.resultadoPct) }})</td>
            </tr>
          </tbody>
        </table></div>
      </div>
      <div class="card">
        <h2>Limites de risco</h2>
        <p class="muted">Máximo por ordem: <strong>{{ brl(c.limites.porOrdem) }}</strong> · Máximo diário: <strong>{{ brl(c.limites.diario) }}</strong> · Ordens por dia: <strong>{{ num(c.limites.ordensDia, 0) }}</strong></p>
      </div>
    </template>
  </main>
</template>
