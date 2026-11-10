<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../services/api'
import { brl, pct, cor, TIPOS } from '../utils'
import OrdemModal from '../components/OrdemModal.vue'

const route = useRoute()
const a = ref(null), saldo = ref(0), erro = ref(''), modal = ref(null)
let parar

async function carregar() {
  try {
    const [ativo, cart] = await Promise.all([api.ativo(route.params.ticker), api.carteira()])
    a.value = ativo; saldo.value = cart.saldoDisponivel
  } catch (e) { erro.value = e.message }
}
onMounted(async () => {
  await carregar()
  parar = api.subscribeCotacoes((l) => {
    const n = l.find((x) => x.ticker === route.params.ticker)
    if (n && a.value) { a.value = { ...a.value, preco: n.preco, variacao: n.variacao, mercado: n.mercado }; a.value.serie = [...a.value.serie.slice(1), n.preco] }
  })
})
onUnmounted(() => parar?.())

const pontos = computed(() => {
  const s = a.value?.serie || []; if (!s.length) return ''
  const min = Math.min(...s), max = Math.max(...s), w = 600, h = 140
  return s.map((v, i) => `${(i / (s.length - 1)) * w},${h - ((v - min) / (max - min || 1)) * (h - 10) - 5}`).join(' ')
})
</script>

<template>
  <main class="page">
    <RouterLink to="/cotacoes" class="link small">← Cotações</RouterLink>
    <p v-if="erro" class="down">{{ erro }}</p>
    <p v-else-if="!a" class="muted">Carregando…</p>
    <template v-else>
      <div class="row between">
        <div><h1>{{ a.ticker }} <span class="badge muted">{{ TIPOS[a.tipo] }}</span></h1><div class="muted">{{ a.nome }}</div></div>
        <div style="text-align:right"><div class="kpi">{{ brl(a.preco) }}</div><div :class="cor(a.variacao)">{{ pct(a.variacao) }}</div>
          <span class="badge" :class="a.mercado === 'ABERTO' ? 'up' : 'muted'">Mercado {{ a.mercado === 'ABERTO' ? 'aberto' : 'fechado' }}</span></div>
      </div>

      <div class="card" style="margin-top:1rem">
        <h3>Últimos 30 pregões</h3>
        <svg viewBox="0 0 600 140" style="width:100%;height:160px" role="img" aria-label="Gráfico de preço">
          <polyline :points="pontos" fill="none" :stroke="a.variacao >= 0 ? '#4ade80' : '#f87171'" stroke-width="2" />
        </svg>
      </div>

      <div class="card">
        <h3>Sua posição</h3>
        <p v-if="!a.posicao" class="muted">Você não possui este ativo.</p>
        <p v-else>{{ a.posicao.quantidade }} unidades · preço médio {{ brl(a.posicao.precoMedio) }} · valor {{ brl(a.posicao.quantidade * a.preco) }}</p>
        <div class="row">
          <button class="btn" @click="modal = 'COMPRA'">Comprar</button>
          <button class="btn ghost" :disabled="!a.posicao" @click="modal = 'VENDA'">Vender</button>
        </div>
      </div>
      <OrdemModal v-if="modal" :ativo="a" :posicao="a.posicao?.quantidade || 0" :saldo="saldo" :tipo-inicial="modal" @fechar="modal = null" @enviada="carregar" />
    </template>
  </main>
</template>
