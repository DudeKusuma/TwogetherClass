<script setup>
import { Search } from 'lucide-vue-next'
// Visual-only for now: search is intentionally not implemented.
</script>

<template>
  <button type="button" class="search-btn" aria-label="Pencarian (segera hadir)" title="Pencarian segera hadir" data-testid="header-search-button">
    <Search :size="20" :stroke-width="2" />
  </button>
</template>

<style scoped>
.search-btn {
  width: 42px;
  height: 42px;
  display: grid;
  place-items: center;
  border-radius: var(--radius-pill);
  border: 1px solid var(--c-border);
  background: var(--c-white);
  color: var(--c-text);
  cursor: default;
}
</style>
