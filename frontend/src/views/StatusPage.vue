<script setup>
import { useRouter } from 'vue-router'
import { session } from '../store/session'
import { inicioDe } from '../utils'

const props = defineProps({ icone: String, titulo: String, texto: String, acao: String, destino: String })
const router = useRouter()
const ir = () => router.push(props.destino === 'inicio' ? inicioDe(session.user?.perfil) : props.destino)
</script>

<template>
  <main class="status-page">
    <div class="icone">{{ icone }}</div>
    <h1>{{ titulo }}</h1>
    <p>{{ texto }}</p>
    <button class="btn big" @click="ir">{{ acao }}</button>
  </main>
</template>
