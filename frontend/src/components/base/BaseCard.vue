<script setup>
import { defineProps } from 'vue'
defineProps({
  tone: { type: String, default: 'white' },
  tag: { type: String, default: 'div' },
  padded: { type: Boolean, default: true }
})
</script>

<template>
  <component :is="tag" class="card" :class="[`card--${tone}`, { 'card--padded': padded }]">
    <slot />
  </component>
</template>

<style scoped>
.card {
  border-radius: var(--radius-lg);
  background: var(--c-white);
  box-shadow: var(--shadow-sm);
  border: 1px solid rgba(231, 235, 243, 0.7);
}

.card--padded {
  padding: var(--space-5);
}

.card--blue { background: var(--c-blue-soft); border-color: transparent; box-shadow: none; }
.card--yellow { background: var(--c-yellow); border-color: transparent; box-shadow: none; }
.card--mint { background: var(--c-mint); border-color: transparent; box-shadow: none; }
.card--pink { background: var(--c-pink); border-color: transparent; box-shadow: none; }
.card--lavender { background: var(--c-lavender); border-color: transparent; box-shadow: none; }
.card--peach { background: var(--c-peach); border-color: transparent; box-shadow: none; }
</style>
