<script setup>
import { defineProps } from 'vue'
import BaseCard from '@/components/base/BaseCard.vue'
import EmptyState from './EmptyState.vue'

defineProps({
  eyebrow: { type: String, default: '' },
  title: { type: String, required: true },
  description: { type: String, default: '' },
  icon: { type: [Object, Function], default: null },
  tone: { type: String, default: 'blue' },
  planned: { type: Array, default: () => [] },
  testId: { type: String, default: 'placeholder-page' }
})
</script>

<template>
  <div class="placeholder" :data-testid="testId">
    <header class="page-head">
      <span v-if="eyebrow" class="page-head__eyebrow">{{ eyebrow }}</span>
      <h1 class="page-head__title">{{ title }}</h1>
      <p v-if="description" class="page-head__desc">{{ description }}</p>
    </header>

    <slot />

    <BaseCard class="placeholder__card">
      <EmptyState :icon="icon" :tone="tone" title="Segera hadir" description="Halaman ini sedang disiapkan dan akan tersedia pada pengembangan berikutnya." />
      <div v-if="planned.length" class="placeholder__planned">
        <h2 class="placeholder__planned-title">Rencana fitur</h2>
        <ul>
          <li v-for="item in planned" :key="item">{{ item }}</li>
        </ul>
      </div>
    </BaseCard>
  </div>
</template>

<style scoped>
.placeholder__card {
  display: flex;
  flex-direction: column;
}

.placeholder__planned {
  border-top: 1px dashed var(--c-border);
  padding-top: var(--space-4);
}

.placeholder__planned-title {
  font-size: 13px;
  font-weight: 800;
  margin-bottom: var(--space-3);
  color: var(--c-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.placeholder__planned ul {
  margin: 0;
  padding: 0;
  list-style: none;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.placeholder__planned li {
  font-size: 13px;
  font-weight: 600;
  padding: 6px 12px;
  border-radius: var(--radius-pill);
  background: var(--c-gray);
  color: var(--c-text);
}
</style>
