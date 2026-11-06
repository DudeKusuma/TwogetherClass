<script setup>
import { defineProps, defineEmits } from 'vue'
import { watch, onBeforeUnmount } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { X, User, Info, ShieldCheck, LogOut, ChevronRight, Wallet, HandCoins, Brush, Images, Award } from 'lucide-vue-next'
import BaseButton from '@/components/base/BaseButton.vue'
import { useAuthStore } from '@/stores/useAuthStore'

const props = defineProps({ open: { type: Boolean, default: false } })
const emit = defineEmits(['close'])
const auth = useAuthStore()
const router = useRouter()

function onKey(e) {
  if (e.key === 'Escape') emit('close')
}

watch(
  () => props.open,
  (open) => {
    document.body.style.overflow = open ? 'hidden' : ''
    if (open) document.addEventListener('keydown', onKey)
    else document.removeEventListener('keydown', onKey)
  }
)

onBeforeUnmount(() => {
  document.body.style.overflow = ''
  document.removeEventListener('keydown', onKey)
})

function logout() {
  emit('close')
  auth.logout()
  router.push({ name: 'login' })
}
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="open" class="overlay" data-testid="profile-drawer-overlay" @click="emit('close')" />
    </Transition>
    <Transition name="slide">
      <aside v-if="open" class="drawer" role="dialog" aria-modal="true" aria-label="Profil pengguna" data-testid="profile-drawer">
        <div class="drawer__head">
          <span class="drawer__label">Profil</span>
          <button type="button" class="drawer__close" aria-label="Tutup" data-testid="profile-drawer-close" @click="emit('close')">
            <X :size="20" />
          </button>
        </div>

        <div class="drawer__user">
          <span class="drawer__avatar">{{ auth.user?.displayName?.charAt(0) }}</span>
          <div class="drawer__info">
            <h2 class="drawer__name" data-testid="drawer-user-name">{{ auth.user?.displayName }}</h2>
            <span class="chip chip--blue" data-testid="drawer-user-role">{{ auth.roleLabel }}</span>
          </div>
        </div>

        <dl class="drawer__meta">
          <div><dt>Username</dt><dd data-testid="drawer-username">{{ auth.user?.username }}</dd></div>
          <div><dt>Kelas</dt><dd>XI-B2</dd></div>
          <div><dt>Sekolah</dt><dd>SMA Negeri 1 Gianyar</dd></div>
        </dl>

        <nav class="drawer__nav">
          <RouterLink to="/profile" class="drawer__link" data-testid="drawer-profile-link" @click="emit('close')">
            <span class="drawer__link-icon"><User :size="18" /></span> Profil Saya <ChevronRight :size="18" class="chev" />
          </RouterLink>
          <div class="drawer__section-label">Fitur kelas</div>
          <RouterLink to="/cash" class="drawer__link" data-testid="drawer-cash-link" @click="emit('close')">
            <span class="drawer__link-icon drawer__link-icon--mint"><Wallet :size="18" /></span> Uang Kas <ChevronRight :size="18" class="chev" />
          </RouterLink>
          <RouterLink to="/contributions" class="drawer__link" data-testid="drawer-contributions-link" @click="emit('close')">
            <span class="drawer__link-icon drawer__link-icon--mint"><HandCoins :size="18" /></span> Iuran Kelas <ChevronRight :size="18" class="chev" />
          </RouterLink>
          <div class="drawer__link drawer__link--disabled" aria-disabled="true">
            <span class="drawer__link-icon"><Brush :size="18" /></span> Piket Kelas <span class="drawer__coming">Segera hadir</span>
          </div>
          <div class="drawer__link drawer__link--disabled" aria-disabled="true">
            <span class="drawer__link-icon"><Images :size="18" /></span> Arsip Kelas <span class="drawer__coming">Segera hadir</span>
          </div>
          <div class="drawer__link drawer__link--disabled" aria-disabled="true">
            <span class="drawer__link-icon"><Award :size="18" /></span> Student Titles &amp; Badges <span class="drawer__coming">Segera hadir</span>
          </div>
          <RouterLink to="/about" class="drawer__link" data-testid="drawer-about-link" @click="emit('close')">
            <span class="drawer__link-icon drawer__link-icon--mint"><Info :size="18" /></span> Tentang Twogether Class <ChevronRight :size="18" class="chev" />
          </RouterLink>
          <RouterLink
            v-if="auth.isAdmin"
            to="/admin-power"
            class="drawer__link drawer__link--admin"
            data-testid="drawer-admin-power-link"
            @click="emit('close')"
          >
            <span class="drawer__link-icon drawer__link-icon--admin"><ShieldCheck :size="18" /></span> Admin Power <ChevronRight :size="18" class="chev" />
          </RouterLink>
        </nav>

        <div class="drawer__foot">
          <BaseButton variant="danger" block data-testid="drawer-logout-button" @click="logout">
            <LogOut :size="18" /> Keluar
          </BaseButton>
        </div>
      </aside>
    </Transition>
  </Teleport>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  z-index: 80;
  background: rgba(34, 43, 58, 0.32);
}

.drawer {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  z-index: 90;
  width: min(360px, 88vw);
  background: var(--c-white);
  box-shadow: var(--shadow-lg);
  border-radius: var(--radius-xl) 0 0 var(--radius-xl);
  padding: var(--space-5) var(--space-5) calc(var(--space-5) + env(safe-area-inset-bottom));
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
  overflow-y: auto;
}

.drawer__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.drawer__label {
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--c-text-muted);
}

.drawer__close {
  width: 38px;
  height: 38px;
  display: grid;
  place-items: center;
  border: none;
  border-radius: 50%;
  background: var(--c-gray);
}

.drawer__user {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.drawer__avatar {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background: var(--c-primary);
  color: var(--c-white);
  font-weight: 800;
  font-size: 24px;
  flex-shrink: 0;
}

.drawer__info {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 6px;
}

.drawer__name {
  font-size: 20px;
  font-weight: 800;
}

.drawer__meta {
  margin: 0;
  padding: var(--space-4);
  border-radius: var(--radius-md);
  background: var(--c-gray);
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.drawer__meta div {
  display: flex;
  justify-content: space-between;
  gap: var(--space-3);
  font-size: 13px;
}

.drawer__meta dt {
  color: var(--c-text-muted);
}

.drawer__meta dd {
  margin: 0;
  font-weight: 700;
  text-align: right;
}

.drawer__section-label { margin: 2px 0 -10px; padding: 0 4px; color: var(--c-text-muted); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: .07em; }
.drawer__link--disabled { opacity: .62; cursor: default; }
.drawer__coming { margin-left: auto; color: var(--c-text-muted); font-size: 9px; white-space: nowrap; }

.drawer__nav {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.drawer__link {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: 10px;
  border-radius: var(--radius-md);
  font-weight: 700;
  font-size: 14px;
  transition: background-color 0.18s ease;
}

.drawer__link:hover {
  background: var(--c-gray);
}

.drawer__link .chev {
  margin-left: auto;
  color: var(--c-text-soft);
}

.drawer__link-icon {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  background: var(--c-blue-soft);
  color: var(--c-primary);
}

.drawer__link-icon--mint {
  background: var(--c-mint);
  color: #1f8a56;
}

.drawer__link--admin {
  background: var(--c-lavender);
}

.drawer__link--admin:hover {
  background: #e6deff;
}

.drawer__link-icon--admin {
  background: var(--c-white);
  color: #6a4fd6;
}

.drawer__foot {
  margin-top: auto;
}

.slide-enter-active,
.slide-leave-active {
  transition: transform 0.3s var(--ease);
}
.slide-enter-from,
.slide-leave-to {
  transform: translateX(100%);
}
</style>
