<script setup>
import { ref } from 'vue'
import { AlertCircle, KeyRound, ShieldCheck } from 'lucide-vue-next'
import { useRouter } from 'vue-router'
import BaseButton from '@/components/base/BaseButton.vue'
import { useAuthStore } from '@/stores/useAuthStore'

const auth = useAuthStore()
const router = useRouter()
const password = ref('')
const confirmPassword = ref('')
const error = ref('')
const loading = ref(false)

async function submit() {
  error.value = ''
  if (password.value.length < 10) {
    error.value = 'Password baru minimal 10 karakter.'
    return
  }
  if (password.value !== confirmPassword.value) {
    error.value = 'Konfirmasi password belum sama.'
    return
  }
  loading.value = true
  const ok = await auth.changePassword(password.value)
  loading.value = false
  if (!ok) {
    error.value = auth.authError || 'Password belum berhasil diperbarui.'
    return
  }
  router.replace('/')
}
</script>

<template>
  <div class="change-page">
    <section class="change-card">
      <span class="change-icon"><ShieldCheck :size="26" /></span>
      <h1>Ganti Password</h1>
      <p class="intro">Ini pertama kalinya kamu masuk. Buat password pribadi sebelum melanjutkan ke Twogether Class.</p>
      <form class="form" @submit.prevent="submit">
        <label class="field"><span>Password baru</span><input v-model="password" type="password" autocomplete="new-password" minlength="10" required placeholder="Minimal 10 karakter" /></label>
        <label class="field"><span>Ulangi password baru</span><input v-model="confirmPassword" type="password" autocomplete="new-password" minlength="10" required placeholder="Ketik ulang password" /></label>
        <p v-if="error" class="error" role="alert"><AlertCircle :size="16" />{{ error }}</p>
        <BaseButton type="submit" block :disabled="loading"><KeyRound :size="16" />{{ loading ? 'Menyimpan…' : 'Simpan password baru' }}</BaseButton>
      </form>
    </section>
  </div>
</template>

<style scoped>
.change-page { min-height: 100vh; min-height: 100dvh; display: grid; place-items: center; padding: var(--space-5) var(--space-4); background: var(--c-gray); }
.change-card { width: 100%; max-width: 420px; padding: var(--space-6) var(--space-5); background: var(--c-white); border-radius: var(--radius-xl); box-shadow: var(--shadow-md); }
.change-icon { width: 52px; height: 52px; display: grid; place-items: center; border-radius: 16px; color: var(--c-primary); background: var(--c-blue-soft); margin-bottom: var(--space-4); }
h1 { font-size: 24px; font-weight: 800; }.intro { margin-top: 8px; color: var(--c-text-muted); font-size: 13px; line-height: 1.6; }
.form { display: flex; flex-direction: column; gap: var(--space-4); margin-top: var(--space-5); }.field { display: flex; flex-direction: column; gap: 7px; font-size: 13px; font-weight: 700; }
input { height: 48px; padding: 0 14px; border: 1px solid var(--c-border); border-radius: var(--radius-md); background: var(--c-gray); font-size: 14px; }
input:focus { outline: none; border-color: var(--c-primary); box-shadow: 0 0 0 4px var(--c-blue-soft); }
.error { display: flex; gap: 7px; align-items: center; color: var(--c-danger); font-size: 12px; }
</style>
