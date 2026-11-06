<script setup>
import { computed, ref, onMounted, onBeforeUnmount } from 'vue'
import { RouterLink } from 'vue-router'
import { Bell } from 'lucide-vue-next'
import logo from '@/assets/icons/logo XI B2.jpeg'
import SearchBar from '@/components/shared/SearchBar.vue'
import NotificationPanel from '@/components/announcements/NotificationPanel.vue'
import ProfileDrawer from './ProfileDrawer.vue'
import { useAuthStore } from '@/stores/useAuthStore'
import { useAnnouncementStore } from '@/stores/useAnnouncementStore'

const auth = useAuthStore()
const announcements = useAnnouncementStore()
const notifOpen = ref(false)
const drawerOpen = ref(false)

const activeCount = computed(() => announcements.active.length)
const initial = computed(() => auth.user?.displayName?.charAt(0).toUpperCase() ?? '?')

function onPointerDown(e) {
  if (notifOpen.value && !e.target.closest('[data-notif-root]')) notifOpen.value = false
}
function onKey(e) {
  if (e.key === 'Escape') notifOpen.value = false
}
onMounted(() => {
  document.addEventListener('pointerdown', onPointerDown)
  document.addEventListener('keydown', onKey)
})
onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', onPointerDown)
  document.removeEventListener('keydown', onKey)
})
</script>

<template>
  <header class="app-header" data-testid="app-header">
    <div class="app-header__inner">
      <RouterLink to="/" class="brand" data-testid="header-brand-link">
        <img :src="logo" alt="Logo Twogether Class" class="brand__logo" data-testid="header-logo" />
        <span class="brand__text">
          <span class="brand__title">Twogether Class</span>
          <span class="brand__class" data-testid="header-class-label">XI-B2</span>
        </span>
      </RouterLink>

      <div class="actions">
        <SearchBar />
        <button
          type="button"
          class="icon-btn"
          :class="{ 'is-open': notifOpen }"
          aria-label="Notifikasi"
          data-notif-root
          data-testid="notification-bell-button"
          @click="notifOpen = !notifOpen"
        >
          <Bell :size="20" :stroke-width="2" />
          <span v-if="activeCount" class="badge" data-testid="notification-badge">{{ activeCount > 9 ? '9+' : activeCount }}</span>
        </button>
        <button type="button" class="avatar" aria-label="Buka profil" data-testid="profile-avatar-button" @click="drawerOpen = true">
          {{ initial }}
        </button>
      </div>

      <Transition name="drop">
        <NotificationPanel v-if="notifOpen" @close="notifOpen = false" />
      </Transition>
    </div>
    <ProfileDrawer :open="drawerOpen" @close="drawerOpen = false" />
  </header>
</template>

<style scoped>
.app-header {
  position: sticky;
  top: 0;
  z-index: 40;
  background: rgba(246, 248, 252, 0.86);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
}

.app-header__inner {
  position: relative;
  max-width: var(--content-max);
  margin: 0 auto;
  height: var(--header-h);
  padding: 0 var(--space-4);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
}

.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.brand__logo {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  object-fit: cover;
  flex-shrink: 0;
  box-shadow: var(--shadow-sm);
}

.brand__text {
  display: flex;
  flex-direction: column;
  min-width: 0;
  line-height: 1.15;
}

.brand__title {
  font-size: 15px;
  font-weight: 800;
  letter-spacing: -0.01em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.brand__class {
  align-self: flex-start;
  margin-top: 3px;
  font-size: 11px;
  font-weight: 800;
  color: var(--c-primary);
  background: var(--c-blue-soft);
  padding: 1px 8px;
  border-radius: var(--radius-pill);
}

.actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.icon-btn {
  position: relative;
  width: 42px;
  height: 42px;
  display: grid;
  place-items: center;
  border-radius: var(--radius-pill);
  border: 1px solid var(--c-border);
  background: var(--c-white);
  transition: background-color 0.18s ease, border-color 0.18s ease;
}

.icon-btn:hover,
.icon-btn.is-open {
  background: var(--c-blue-soft);
  border-color: transparent;
  color: var(--c-primary);
}

.badge {
  position: absolute;
  top: -3px;
  right: -3px;
  min-width: 18px;
  height: 18px;
  padding: 0 5px;
  border-radius: var(--radius-pill);
  background: var(--c-danger);
  color: var(--c-white);
  font-size: 10px;
  font-weight: 800;
  display: grid;
  place-items: center;
  border: 2px solid var(--c-white);
}

.avatar {
  width: 42px;
  height: 42px;
  border-radius: 50%;
  border: 2px solid var(--c-white);
  background: var(--c-primary);
  color: var(--c-white);
  font-weight: 800;
  font-size: 16px;
  box-shadow: 0 4px 12px rgba(23, 105, 245, 0.25);
  transition: transform 0.18s var(--ease);
}

.avatar:hover {
  transform: scale(1.05);
}

@media (max-width: 359px) {
  .brand__title {
    font-size: 13px;
  }
  .actions {
    gap: 6px;
  }
  .icon-btn,
  .avatar,
  .actions :deep(.search-btn) {
    width: 38px;
    height: 38px;
  }
}

@media (min-width: 768px) {
  .app-header__inner {
    padding: 0 var(--space-6);
  }
  .brand__title {
    font-size: 17px;
  }
}

@media (min-width: 1024px) {
  .app-header__inner {
    padding: 0 var(--space-7);
    height: 80px;
  }
}

.drop-enter-active,
.drop-leave-active {
  transition: opacity 0.18s ease, transform 0.18s var(--ease);
}
.drop-enter-from,
.drop-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}
</style>
