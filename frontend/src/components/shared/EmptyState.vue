<script setup>
import { defineProps } from 'vue'
defineProps({
  icon: { type: [Object, Function], default: null },
  title: { type: String, required: true },
  description: { type: String, default: '' },
  tone: { type: String, default: 'blue' },
  compact: { type: Boolean, default: false }
})
</script>

<template>
  <div class="empty" :class="{ 'empty--compact': compact }" data-testid="empty-state">
    <span v-if="icon" class="empty__icon" :class="`empty__icon--${tone}`">
      <component :is="icon" :size="compact ? 20 : 26" :stroke-width="2" />
    </span>
    <h3 class="empty__title">{{ title }}</h3>
    <p v-if="description" class="empty__desc">{{ description }}</p>
    <slot />
  </div>
</template>

<style scoped>
.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: var(--space-2);
  padding: var(--space-7) var(--space-4);
}

.empty--compact {
  padding: var(--space-5) var(--space-3);
}

.empty__icon {
  width: 60px;
  height: 60px;
  display: grid;
  place-items: center;
  border-radius: var(--radius-md);
  margin-bottom: var(--space-2);
  color: var(--c-primary);
  background: var(--c-blue-soft);
}

.empty--compact .empty__icon {
  width: 44px;
  height: 44px;
  border-radius: 14px;
}

.empty__icon--yellow { background: var(--c-yellow); color: #a17a10; }
.empty__icon--mint { background: var(--c-mint); color: #1f8a56; }
.empty__icon--pink { background: var(--c-pink); color: #d0465b; }
.empty__icon--lavender { background: var(--c-lavender); color: #6a4fd6; }
.empty__icon--peach { background: var(--c-peach); color: #c46b12; }

.empty__title {
  font-size: 16px;
  font-weight: 800;
}

.empty--compact .empty__title {
  font-size: 14px;
}

.empty__desc {
  font-size: 13px;
  color: var(--c-text-muted);
  max-width: 40ch;
}
</style>
