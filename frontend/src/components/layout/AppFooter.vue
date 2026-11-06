<script setup>
import { RouterLink } from 'vue-router'
import { CalendarDays, ListTodo, House, UserCheck, User } from 'lucide-vue-next'

// Main navigation: bottom bar on mobile/tablet, side rail on desktop.
const items = [
  { to: '/schedule', label: 'Jadwal', icon: CalendarDays, id: 'schedule' },
  { to: '/tasks', label: 'Tugas', icon: ListTodo, id: 'tasks' },
  { to: '/', label: 'Home', icon: House, id: 'home', home: true },
  { to: '/attendance', label: 'Presensi', icon: UserCheck, id: 'attendance' },
  { to: '/profile', label: 'Profil Saya', icon: User, id: 'profile' }
]
</script>

<template>
  <nav class="nav" aria-label="Navigasi utama" data-testid="main-navigation">
    <RouterLink
      v-for="item in items"
      :key="item.id"
      :to="item.to"
      class="nav__item"
      :class="{ 'nav__item--home': item.home }"
      :data-testid="`nav-${item.id}`"
    >
      <span class="nav__icon"><component :is="item.icon" :size="item.home ? 24 : 21" :stroke-width="2" /></span>
      <span class="nav__label">{{ item.label }}</span>
    </RouterLink>
  </nav>
</template>

<style scoped>
.nav {
  position: fixed;
  left: 50%;
  bottom: calc(12px + env(safe-area-inset-bottom));
  transform: translateX(-50%);
  z-index: 50;
  width: calc(100% - 24px);
  max-width: 520px;
  height: var(--nav-h);
  padding: 0 6px;
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  align-items: center;
  background: var(--c-white);
  border-radius: var(--radius-xl);
  box-shadow: 0 10px 34px rgba(34, 43, 58, 0.12);
  border: 1px solid var(--c-border);
}

.nav__item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  min-width: 0;
  color: var(--c-text-soft);
  transition: color 0.18s ease;
}

.nav__icon {
  display: grid;
  place-items: center;
  width: 40px;
  height: 32px;
  border-radius: var(--radius-pill);
  transition: background-color 0.18s ease;
}

.nav__label {
  font-size: 10.5px;
  font-weight: 700;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
}

.nav__item.router-link-exact-active {
  color: var(--c-primary);
}

.nav__item.router-link-exact-active .nav__icon {
  background: var(--c-blue-soft);
}

/* Emphasised, raised Home */
.nav__item--home .nav__icon {
  width: 58px;
  height: 58px;
  margin-top: -30px;
  border-radius: 50%;
  background: var(--c-primary);
  color: var(--c-white);
  border: 4px solid var(--c-gray);
  box-shadow: var(--shadow-primary);
  transition: transform 0.2s var(--ease);
}

.nav__item--home:hover .nav__icon {
  transform: translateY(-2px);
}

.nav__item--home.router-link-exact-active .nav__icon {
  background: var(--c-primary);
}

.nav__item--home .nav__label {
  color: var(--c-primary);
}

@media (min-width: 1024px) {
  .nav {
    left: 0;
    top: 0;
    bottom: 0;
    transform: none;
    width: var(--rail-w);
    max-width: none;
    height: auto;
    padding: var(--space-6) 0;
    grid-template-columns: 1fr;
    grid-auto-rows: min-content;
    align-content: center;
    gap: var(--space-4);
    border-radius: 0 var(--radius-xl) var(--radius-xl) 0;
    border-left: none;
    box-shadow: var(--shadow-sm);
  }

  .nav__icon {
    width: 48px;
    height: 40px;
  }

  .nav__label {
    font-size: 11.5px;
  }

  .nav__item--home .nav__icon {
    width: 62px;
    height: 62px;
    margin: var(--space-2) 0 0;
    border-color: var(--c-white);
  }
}
</style>
