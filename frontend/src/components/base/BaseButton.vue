<script setup>
import { defineProps } from 'vue'
defineProps({
  variant: { type: String, default: 'primary' },
  size: { type: String, default: 'md' },
  type: { type: String, default: 'button' },
  block: { type: Boolean, default: false }
})
</script>

<template>
  <button :type="type" class="btn" :class="[`btn--${variant}`, `btn--${size}`, { 'btn--block': block }]">
    <slot />
  </button>
</template>

<style scoped>
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: 1px solid transparent;
  border-radius: var(--radius-pill);
  font-weight: 700;
  white-space: nowrap;
  transition: background-color 0.18s ease, color 0.18s ease, transform 0.18s var(--ease), box-shadow 0.18s ease;
}

.btn:active {
  transform: scale(0.97);
}

.btn:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.btn--md {
  height: 46px;
  padding: 0 22px;
  font-size: 14px;
}

.btn--sm {
  height: 36px;
  padding: 0 14px;
  font-size: 13px;
}

.btn--block {
  width: 100%;
}

.btn--primary {
  background: var(--c-primary);
  color: var(--c-white);
  box-shadow: 0 6px 16px rgba(23, 105, 245, 0.24);
}
.btn--primary:hover {
  background: var(--c-primary-dark);
}

.btn--secondary {
  background: var(--c-blue-soft);
  color: var(--c-primary);
}
.btn--secondary:hover {
  background: #dce9ff;
}

.btn--ghost {
  background: var(--c-white);
  border-color: var(--c-border);
  color: var(--c-text);
}
.btn--ghost:hover {
  background: var(--c-gray);
}

.btn--danger {
  background: var(--c-danger-soft);
  color: var(--c-danger);
}
.btn--danger:hover {
  background: #ffdfe4;
}

.btn--danger-solid {
  background: var(--c-danger);
  color: var(--c-white);
}
</style>
