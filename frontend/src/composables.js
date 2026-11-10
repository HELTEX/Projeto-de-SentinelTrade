import { ref, onMounted, onUnmounted } from 'vue'

// Carrega dados e, opcionalmente, atualiza a cada `ms` (polling).
export function useLoad(fn, ms = 0) {
  const data = ref(null), erro = ref(''), carregando = ref(true)
  let t
  async function carregar() {
    try { data.value = await fn(); erro.value = '' }
    catch (e) { erro.value = e.message || 'Erro ao carregar' }
    finally { carregando.value = false }
  }
  onMounted(() => { carregar(); if (ms) t = setInterval(carregar, ms) })
  onUnmounted(() => clearInterval(t))
  return { data, erro, carregando, recarregar: carregar }
}
