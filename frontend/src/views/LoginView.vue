<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { AlertCircle } from 'lucide-vue-next'
import logo from '@/assets/icons/logo XI B2.jpeg'
import BaseButton from '@/components/base/BaseButton.vue'
import { useAuthStore } from '@/stores/useAuthStore'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

const username = ref('')
const password = ref('')
const error = ref('')

function safeRedirect(r) {
  return typeof r === 'string' && r.startsWith('/') && !r.startsWith('//') && !r.startsWith('/login') ? r : '/'
}

async function submit() {
  error.value = ''
  if (!username.value.trim() || !password.value) {
    error.value = 'Isi username dan password terlebih dahulu.'
    return
  }
  const ok = await auth.login(username.value, password.value)
  if (!ok) {
    error.value = auth.authError || 'Email atau password salah.'
    return
  }
  router.replace(safeRedirect(route.query.redirect))
}
</script>

<template>
  <div class="login" data-testid="login-page">
    <div class="login__card">
      <img :src="logo" alt="Logo Twogether Class" class="login__logo" data-testid="login-logo" />
      <h1 class="login__title">Twogether Class</h1>
      <span class="login__class" data-testid="login-class-label">XI-B2</span>
      <p class="login__sub">Masuk untuk membuka portal kelas.</p>

      <form class="login__form" novalidate data-testid="login-form" @submit.prevent="submit">
        <label class="field">
          <span class="field__label">Username / email admin</span>
          <input
            v-model="username"
            class="field__input"
            type="text"
            autocomplete="username"
            autocapitalize="none"
            placeholder="Contoh: siswa01"
            data-testid="login-username-input"
          />
        </label>
        <label class="field">
          <span class="field__label">Password</span>
          
        <input
        v-model="password"
        class="field__input"
        type="password"
          autocomplete="current-password"
        placeholder="Masukkan password"
        data-testid="login-password-input"
       @paste="(event) => {
         event.stopPropagation()
        }"
        />

        </label>

        <p v-if="error" class="login__error" role="alert" data-testid="login-error">
          <AlertCircle :size="16" /> {{ error }}
        </p>

        <BaseButton type="submit" block data-testid="login-submit-button">Masuk</BaseButton>
      </form>

      <p class="login__demo" data-testid="login-demo-hint">
        Siswa masuk dengan username dari admin. Admin lama tetap dapat masuk memakai email akunnya.
      </p>
    </div>
  </div>
</template>

<style scoped>
.login {
  min-height: 100vh;
  min-height: 100dvh;
  display: grid;
  place-items: center;
  padding: var(--space-5) var(--space-4);
  background: var(--c-gray);
}

.login__card {
  width: 100%;
  max-width: 400px;
  background: var(--c-white);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-md);
  padding: var(--space-6) var(--space-5);
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.login__logo {
  width: 104px;
  height: 104px;
  border-radius: 28px;
  object-fit: cover;
  box-shadow: var(--shadow-md);
  margin-bottom: var(--space-4);
}

.login__title {
  font-size: 26px;
  font-weight: 800;
  letter-spacing: -0.02em;
}

.login__class {
  margin-top: 6px;
  font-size: 12px;
  font-weight: 800;
  color: var(--c-primary);
  background: var(--c-blue-soft);
  padding: 3px 12px;
  border-radius: var(--radius-pill);
}

.login__sub {
  margin-top: var(--space-3);
  font-size: 14px;
  color: var(--c-text-muted);
}

.login__form {
  width: 100%;
  margin-top: var(--space-5);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  text-align: left;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field__label {
  font-size: 13px;
  font-weight: 700;
}

.field__input {
  height: 48px;
  padding: 0 16px;
  border-radius: var(--radius-md);
  border: 1px solid var(--c-border);
  background: var(--c-gray);
  font-size: 15px;
  transition: border-color 0.18s ease, background-color 0.18s ease, box-shadow 0.18s ease;
}

.field__input:focus {
  outline: none;
  border-color: var(--c-primary);
  background: var(--c-white);
  box-shadow: 0 0 0 4px var(--c-blue-soft);
}

.login__error {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  color: var(--c-danger);
  background: var(--c-danger-soft);
  padding: 10px 12px;
  border-radius: var(--radius-sm);
}

.login__demo {
  margin-top: var(--space-5);
  font-size: 12px;
  color: var(--c-text-soft);
}

.login__demo b {
  color: var(--c-text-muted);
}

@media (min-width: 768px) {
  .login__card {
    padding: var(--space-7) var(--space-6);
  }
}
</style>
