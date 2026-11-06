<script setup>
import { storeToRefs } from 'pinia'
import { useAuthStore } from '@/stores/useAuthStore'
import { useScheduleStore } from '@/stores/useScheduleStore'
import { useGreeting } from '@/composables/useGreeting'

const auth = useAuthStore()
const { now } = storeToRefs(useScheduleStore())
const { greeting, todayLabel } = useGreeting(now)
</script>

<template>
  <section class="greeting" data-testid="home-greeting-section">
    <p class="greeting__date" data-testid="greeting-date">{{ todayLabel }}</p>
    <h1 class="greeting__title" data-testid="greeting-text">
      {{ greeting }}, <span class="greeting__name">{{ auth.user?.displayName }}</span>
    </h1>
    <p class="greeting__sub">Selamat datang di Twogether Class XI-B2.</p>
  </section>
</template>

<style scoped>
.greeting {
  padding: var(--space-2) 0 0;
}

.greeting__date {
  font-size: 13px;
  font-weight: 600;
  color: var(--c-text-muted);
  margin-bottom: 6px;
}

.greeting__title {
  font-size: 30px;
  line-height: 1.15;
  font-weight: 800;
  letter-spacing: -0.025em;
}

.greeting__name {
  color: var(--c-primary);
}

.greeting__sub {
  margin-top: 8px;
  font-size: 14px;
  color: var(--c-text-muted);
}

@media (min-width: 768px) {
  .greeting__title {
    font-size: 40px;
  }
  .greeting__sub {
    font-size: 15px;
  }
}

@media (min-width: 1024px) {
  .greeting__title {
    font-size: 46px;
  }
}
</style>
