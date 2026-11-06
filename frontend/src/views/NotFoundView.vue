<script setup>
import { RouterLink } from 'vue-router'
import logo from '@/assets/icons/logo XI B2.jpeg'
import { useAuthStore } from '@/stores/useAuthStore'

const auth = useAuthStore()
</script>

<template>
  <div class="nf" data-testid="not-found-page">
    <div class="nf__card">
      <img :src="logo" alt="Logo Twogether Class" class="nf__logo" />
      <span class="nf__code">404</span>
      <h1 class="nf__title">Halaman tidak ditemukan</h1>
      <p class="nf__desc">Halaman yang kamu cari tidak ada atau sudah dipindahkan.</p>
      <RouterLink :to="auth.isAuthenticated ? '/' : '/login'" class="nf__btn" data-testid="not-found-back-button">
        {{ auth.isAuthenticated ? 'Kembali ke Home' : 'Ke halaman masuk' }}
      </RouterLink>
    </div>
  </div>
</template>

<style scoped>
.nf {
  min-height: 100vh;
  min-height: 100dvh;
  display: grid;
  place-items: center;
  padding: var(--space-5) var(--space-4);
}

.nf__card {
  max-width: 420px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-2);
}

.nf__logo {
  width: 72px;
  height: 72px;
  border-radius: 22px;
  object-fit: cover;
  margin-bottom: var(--space-3);
}

.nf__code {
  font-size: 13px;
  font-weight: 800;
  color: var(--c-primary);
  background: var(--c-blue-soft);
  padding: 3px 12px;
  border-radius: var(--radius-pill);
}

.nf__title {
  font-size: 26px;
  font-weight: 800;
  letter-spacing: -0.02em;
}

.nf__desc {
  color: var(--c-text-muted);
  font-size: 14px;
}

.nf__btn {
  margin-top: var(--space-4);
  height: 46px;
  padding: 0 22px;
  display: inline-flex;
  align-items: center;
  border-radius: var(--radius-pill);
  background: var(--c-primary);
  color: var(--c-white);
  font-weight: 700;
  font-size: 14px;
}
</style>
