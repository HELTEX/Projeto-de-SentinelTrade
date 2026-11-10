<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../services/api'
import { session, setSession } from '../store/session'
import { inicioDe } from '../utils'

const route = useRoute(), router = useRouter()
const codigo = ref(''), erro = ref(''), carregando = ref(false)

async function verificar() {
  erro.value = ''; carregando.value = true
  try {
    const r = await api.verificarMfa(session.mfaToken, codigo.value)
    setSession(r.token, r.usuario)
    router.push(route.query.redirect || inicioDe(r.usuario.perfil))
  } catch (e) { erro.value = e.message; codigo.value = '' } finally { carregando.value = false }
}
</script>

<template>
  <div class="auth-wrap">
    <RouterLink to="/" class="auth-logo">Sentinel Trade</RouterLink>
    <div class="auth-main">
      <form class="auth-card" @submit.prevent="verificar">
        <p style="margin:0">Verificação em duas etapas</p>
        <p class="small" style="margin:.2rem 0 0;opacity:.8">Digite o código de 6 dígitos do seu aplicativo autenticador ({{ session.email }}).</p>
        <label for="cod">Código:</label>
        <input id="cod" v-model="codigo" class="input code" inputmode="numeric" maxlength="6" pattern="\d{6}" autocomplete="one-time-code" required />
        <div v-if="erro" class="alert err">{{ erro }}</div>
        <button class="btn" :disabled="carregando || codigo.length !== 6">{{ carregando ? 'Verificando…' : 'Verificar' }}</button>
        <div style="text-align:center;margin-top:.8rem"><RouterLink to="/login" class="link">Voltar</RouterLink></div>
        <p class="demo">Demonstração: qualquer código de 6 dígitos, exceto 000000.</p>
      </form>
    </div>
  </div>
</template>
