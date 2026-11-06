<script setup>
import { RouterLink } from 'vue-router'
import { ArrowLeft } from 'lucide-vue-next'
</script>

<template>
  <RouterLink to="/admin-power" class="back" data-testid="admin-back-link">
    <ArrowLeft :size="16" /> Admin Power
  </RouterLink>
</template>

<style scoped>
.back {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-bottom: var(--space-4);
  font-size: 13px;
  font-weight: 700;
  color: var(--c-primary);
}
</style>
