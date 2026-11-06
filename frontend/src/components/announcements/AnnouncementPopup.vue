<script setup>
import { computed } from 'vue'
import { Megaphone } from 'lucide-vue-next'
import BaseButton from '@/components/base/BaseButton.vue'
import { useAuthStore } from '@/stores/useAuthStore'
import { useAnnouncementStore } from '@/stores/useAnnouncementStore'

// Students see active, not-yet-dismissed announcements one by one.
const auth = useAuthStore()
const store = useAnnouncementStore()

const queue = computed(() => (auth.isAuthenticated && !auth.isAdmin ? store.undismissed : []))
const current = computed(() => queue.value[0] ?? null)
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="current" class="overlay" data-testid="announcement-popup-overlay">
        <div class="popup" role="dialog" aria-modal="true" aria-labelledby="popup-title" data-testid="announcement-popup">
          <div class="popup__top">
            <span class="popup__icon"><Megaphone :size="22" /></span>
            <span v-if="queue.length > 1" class="chip chip--gray" data-testid="announcement-popup-count">1 dari {{ queue.length }}</span>
          </div>
          <span class="popup__eyebrow">Pengumuman kelas</span>
          <h2 id="popup-title" class="popup__title" data-testid="announcement-popup-title">{{ current.title }}</h2>
          <p class="popup__body" data-testid="announcement-popup-body">{{ current.body }}</p>
          <p class="popup__hint">Pengumuman ini tetap bisa dibaca lewat lonceng notifikasi.</p>
          <BaseButton block data-testid="announcement-popup-dismiss" @click="store.dismiss(current.id)">
            {{ queue.length > 1 ? 'Tutup & lihat berikutnya' : 'Tutup' }}
          </BaseButton>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: rgba(34, 43, 58, 0.4);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  padding: var(--space-3);
}

@media (min-width: 640px) {
  .overlay {
    align-items: center;
  }
}

.popup {
  width: 100%;
  max-width: 440px;
  max-height: calc(100vh - 32px);
  overflow-y: auto;
  background: var(--c-white);
  border-radius: var(--radius-xl);
  padding: var(--space-5);
  box-shadow: var(--shadow-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.popup__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-2);
}

.popup__icon {
  width: 48px;
  height: 48px;
  border-radius: 16px;
  display: grid;
  place-items: center;
  background: var(--c-yellow);
  color: #a17a10;
}

.popup__eyebrow {
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--c-primary);
}

.popup__title {
  font-size: 21px;
  font-weight: 800;
  line-height: 1.25;
  overflow-wrap: anywhere;
}

.popup__body {
  font-size: 14px;
  color: var(--c-text-muted);
  white-space: pre-line;
  overflow-wrap: anywhere;
}

.popup__hint {
  font-size: 12px;
  color: var(--c-text-soft);
  margin: var(--space-2) 0 var(--space-3);
}
</style>
