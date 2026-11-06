<script setup>
import { defineEmits } from 'vue'
import { X, BellOff } from 'lucide-vue-next'
import EmptyState from '@/components/shared/EmptyState.vue'
import { useAnnouncementStore } from '@/stores/useAnnouncementStore'

const emit = defineEmits(['close'])
const store = useAnnouncementStore()
const fmt = new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })
</script>

<template>
  <div class="panel" role="dialog" aria-label="Pengumuman" data-notif-root data-testid="notification-panel">
    <div class="panel__head">
      <div>
        <h2 class="panel__title">Pengumuman</h2>
        <p class="panel__sub">{{ store.active.length }} pengumuman aktif</p>
      </div>
      <button type="button" class="panel__close" aria-label="Tutup" data-testid="notification-panel-close" @click="emit('close')">
        <X :size="18" />
      </button>
    </div>

    <ul v-if="store.active.length" class="panel__list">
      <li v-for="a in store.active" :key="a.id" class="panel__item" data-testid="notification-item">
        <span class="panel__dot" />
        <div class="panel__content">
          <h3 class="panel__item-title">{{ a.title }}</h3>
          <p class="panel__item-body">{{ a.body }}</p>
          <time class="panel__item-time">{{ fmt.format(new Date(a.updatedAt)) }}</time>
        </div>
      </li>
    </ul>
    <EmptyState
      v-else
      compact
      :icon="BellOff"
      title="Belum ada pengumuman"
      description="Pengumuman aktif dari admin kelas akan muncul di sini."
    />
  </div>
</template>

<style scoped>
.panel {
  position: absolute;
  top: calc(100% - 4px);
  left: var(--space-3);
  right: var(--space-3);
  z-index: 60;
  max-height: min(70vh, 520px);
  overflow-y: auto;
  background: var(--c-white);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  border: 1px solid var(--c-border);
  padding: var(--space-4);
}

@media (min-width: 640px) {
  .panel {
    left: auto;
    right: var(--space-6);
    width: 380px;
  }
}

.panel__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: var(--space-3);
}

.panel__title {
  font-size: 16px;
  font-weight: 800;
}

.panel__sub {
  font-size: 12px;
  color: var(--c-text-muted);
}

.panel__close {
  width: 34px;
  height: 34px;
  display: grid;
  place-items: center;
  border: none;
  border-radius: 50%;
  background: var(--c-gray);
}

.panel__list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.panel__item {
  display: flex;
  gap: var(--space-3);
  padding: var(--space-3);
  border-radius: var(--radius-md);
  background: var(--c-gray);
}

.panel__dot {
  width: 8px;
  height: 8px;
  margin-top: 7px;
  border-radius: 50%;
  background: var(--c-primary);
  flex-shrink: 0;
}

.panel__content {
  min-width: 0;
}

.panel__item-title {
  font-size: 14px;
  font-weight: 800;
  overflow-wrap: anywhere;
}

.panel__item-body {
  font-size: 13px;
  color: var(--c-text-muted);
  white-space: pre-line;
  overflow-wrap: anywhere;
  margin-top: 2px;
}

.panel__item-time {
  display: block;
  margin-top: 6px;
  font-size: 11px;
  font-weight: 600;
  color: var(--c-text-soft);
}
</style>
