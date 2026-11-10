<script setup>
import { ref, computed } from 'vue'
import { api } from '../services/api'
import { brl } from '../utils'
import StatusBadge from './StatusBadge.vue'

const props = defineProps({ ativo: Object, posicao: Number, saldo: Number, tipoInicial: { type: String, default: 'COMPRA' } })
const emit = defineEmits(['fechar', 'enviada'])

const tipo = ref(props.tipoInicial)
const quantidade = ref(1)
const preco = ref(props.ativo.preco)
// Uma chave por tentativa: reenvios da mesma ordem nunca duplicam (RNF02)
const chave = crypto.randomUUID()
const enviando = ref(false)
const resultado = ref(null)
const erro = ref('')

const total = computed(() => (Number(quantidade.value) || 0) * (Number(preco.value) || 0))
const avisos = computed(() => {
  const a = []
  if (props.ativo.mercado !== 'ABERTO') a.push('Mercado fechado para este ativo.')
  if (tipo.value === 'COMPRA' && total.value > props.saldo) a.push(`Saldo disponível (${brl(props.saldo)}) menor que o total.`)
  if (tipo.value === 'VENDA' && quantidade.value > props.posicao) a.push(`Você possui apenas ${props.posicao} ${props.ativo.ticker}.`)
  return a
})

async function enviar() {
  erro.value = ''; enviando.value = true
  try {
    resultado.value = await api.criarOrdem({ ticker: props.ativo.ticker, tipo: tipo.value, quantidade: Number(quantidade.value), precoLimite: Number(preco.value) }, chave)
    emit('enviada')
  } catch (e) { erro.value = e.message } finally { enviando.value = false }
}
</script>

<template>
  <div class="overlay" @click.self="emit('fechar')">
    <div class="modal">
      <template v-if="!resultado">
        <h2>Nova ordem · {{ ativo.ticker }}</h2>
        <div class="seg">
          <button :class="['buy', { on: tipo === 'COMPRA' }]" @click="tipo = 'COMPRA'">Comprar</button>
          <button :class="['sell', { on: tipo === 'VENDA' }]" @click="tipo = 'VENDA'">Vender</button>
        </div>
        <label>Quantidade</label>
        <input v-model.number="quantidade" type="number" min="1" step="1" class="input" />
        <label>Preço limite (R$)</label>
        <input v-model.number="preco" type="number" min="0.01" step="0.01" class="input" />
        <p class="row between" style="margin:1rem 0 .3rem"><span class="muted">Total estimado</span><strong>{{ brl(total) }}</strong></p>
        <p class="muted small">Saldo disponível: {{ brl(saldo) }} · Sua posição: {{ posicao }}</p>
        <div v-for="a in avisos" :key="a" class="alert warn">{{ a }}</div>
        <div v-if="erro" class="alert err">{{ erro }}</div>
        <p class="muted small">A validação final de saldo, posição, limites e mercado é feita pelo servidor.</p>
        <div class="row between">
          <button class="btn ghost" @click="emit('fechar')">Cancelar</button>
          <button class="btn" :disabled="enviando || !quantidade || !preco" @click="enviar">{{ enviando ? 'Enviando…' : 'Confirmar ordem' }}</button>
        </div>
      </template>
      <template v-else>
        <h2>Ordem {{ resultado.id }}</h2>
        <p><StatusBadge :status="resultado.status" /></p>
        <div v-if="resultado.status === 'REJEITADA'" class="alert err">{{ resultado.motivoRejeicao }}</div>
        <p v-else class="muted">Ordem recebida. Acompanhe o andamento em tempo real.</p>
        <div class="row between">
          <button class="btn ghost" @click="emit('fechar')">Fechar</button>
          <RouterLink class="btn" :to="`/ordens/${resultado.id}`">Ver ordem</RouterLink>
        </div>
      </template>
    </div>
  </div>
</template>
