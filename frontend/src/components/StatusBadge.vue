<script setup>
import { STATUS } from '../utils'
defineProps({ status: String })
</script>

<template>
  <span class="badge" :class="STATUS[status]?.[1]">{{ STATUS[status]?.[0] || status }}</span>
</template>
