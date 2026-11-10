<script setup>
import NavBar from './components/NavBar.vue'
</script>

<template>
  <NavBar v-if="!$route.meta.bare" />
  <RouterView />
</template>
