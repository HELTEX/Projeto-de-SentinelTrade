<script setup>
import { ref } from 'vue'
import { api } from '../services/api'

const email = ref(''), msg = ref(''), carregando = ref(false)
async function enviar() {
  carregando.value = true
  try { msg.value = (await api.esqueciSenha(email.value.trim())).mensagem } catch { msg.value = 'Não foi possível enviar agora. Tente novamente.' } finally { carregando.value = false }
}
</script>

<template>
  <div class="auth-wrap">
    <RouterLink to="/" class="auth-logo">Sentinel Trade</RouterLink>
    <div class="auth-main">
      <form class="auth-card" @submit.prevent="enviar">
        <p style="margin:0">Recuperar senha</p>
        <label for="email">Email:</label>
        <input id="email" v-model="email" type="email" class="input" required />
        <div v-if="msg" class="alert ok">{{ msg }}</div>
        <button class="btn" :disabled="carregando">{{ carregando ? 'Enviando…' : 'Enviar instruções' }}</button>
        <div style="text-align:center;margin-top:.8rem"><RouterLink to="/login" class="link">Voltar ao login</RouterLink></div>
      </form>
    </div>
  </div>
</template>
