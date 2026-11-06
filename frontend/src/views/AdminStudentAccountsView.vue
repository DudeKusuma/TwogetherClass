<script setup>
import { ref } from 'vue'
import { ArrowLeft, Copy, Download, KeyRound, ShieldCheck, Users } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import { supabase } from '@/lib/supabase'
import BaseButton from '@/components/base/BaseButton.vue'

const loading = ref(false)
const error = ref('')
const result = ref(null)
const copied = ref(false)

async function createAccounts() {
  if (loading.value) return
  const confirmed = window.confirm('Buat akun untuk seluruh siswa yang ada di roster XI-B2? Akun yang sudah ada tidak akan dibuat ulang atau di-reset password-nya.')
  if (!confirmed) return

  loading.value = true
  error.value = ''
  result.value = null
  copied.value = false
  const { data, error: invokeError } = await supabase.functions.invoke('create-student-accounts', { body: {} })
  loading.value = false
  if (invokeError) {
    error.value = invokeError.message || 'Tidak dapat menghubungi layanan pembuatan akun.'
    return
  }
  if (data?.error) {
    error.value = data.error
    return
  }
  result.value = data
}

function csvEscape(value) {
  return `"${String(value ?? '').replaceAll('"', '""')}"`
}

function downloadCredentials() {
  if (!result.value?.created?.length) return
  const rows = [['Nomor Absen', 'Nama', 'Username', 'Password Sementara'], ...result.value.created.map((item) => [item.attendance_number, item.full_name, item.username, item.password])]
  const csv = '\uFEFF' + rows.map((row) => row.map(csvEscape).join(',')).join('\r\n')
  const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
  const link = document.createElement('a')
  link.href = url
  link.download = 'akun-siswa-xi-b2.csv'
  link.click()
  URL.revokeObjectURL(url)
}

async function copyCredentials() {
  if (!result.value?.created?.length) return
  const lines = result.value.created.map((item) => `${item.attendance_number}. ${item.full_name}\nUsername: ${item.username}\nPassword sementara: ${item.password}`)
  await navigator.clipboard.writeText(lines.join('\n\n'))
  copied.value = true
}
</script>

<template>
  <div class="accounts-page">
    <RouterLink to="/admin-power" class="back-link"><ArrowLeft :size="16" /> Kembali ke Admin Power</RouterLink>
    <header class="page-head">
      <span class="page-head__eyebrow">Admin Power</span>
      <h1 class="page-head__title">Akun Siswa</h1>
      <p class="page-head__desc">Buat akun login username untuk siswa XI-B2 berdasarkan data roster kelas.</p>
    </header>

    <section class="info-card">
      <div class="info-icon"><Users :size="22" /></div>
      <div>
        <h2>Username otomatis</h2>
        <p>Nomor absen 1–43 akan mendapatkan username <strong>siswa01</strong> sampai <strong>siswa43</strong>. Setiap akun dibuat dengan password sementara acak dan langsung ditautkan ke nama serta NIS pada roster.</p>
      </div>
    </section>

    <section class="action-card">
      <div class="action-heading"><ShieldCheck :size="20" /><strong>Pembuatan akun aman</strong></div>
      <p>Proses ini hanya bisa dijalankan oleh admin. Password hanya ditampilkan satu kali untuk akun yang baru dibuat. Simpan file kredensial di tempat aman dan bagikan secara pribadi kepada siswa.</p>
      <BaseButton block :disabled="loading" @click="createAccounts">
        <KeyRound :size="17" /> {{ loading ? 'Sedang membuat akun…' : 'Buat akun 43 siswa' }}
      </BaseButton>
      <p v-if="error" class="error-message" role="alert">{{ error }}</p>
    </section>

    <section v-if="result" class="result-card" aria-live="polite">
      <h2>Hasil pembuatan akun</h2>
      <p class="result-note">{{ result.message }}</p>
      <div class="stats">
        <div><strong>{{ result.created?.length || 0 }}</strong><span>Akun baru</span></div>
        <div><strong>{{ result.alreadyCreated?.length || 0 }}</strong><span>Sudah ada</span></div>
        <div><strong>{{ result.failures?.length || 0 }}</strong><span>Gagal</span></div>
      </div>
      <div v-if="result.created?.length" class="credential-actions">
        <BaseButton size="sm" @click="downloadCredentials"><Download :size="16" /> Unduh CSV</BaseButton>
        <BaseButton size="sm" variant="secondary" @click="copyCredentials"><Copy :size="16" /> {{ copied ? 'Tersalin' : 'Salin kredensial' }}</BaseButton>
      </div>
      <div v-if="result.created?.length" class="table-wrap">
        <table>
          <thead><tr><th>Absen</th><th>Nama</th><th>Username</th><th>Password sementara</th></tr></thead>
          <tbody>
            <tr v-for="item in result.created" :key="item.username">
              <td>{{ item.attendance_number }}</td><td>{{ item.full_name }}</td><td><code>{{ item.username }}</code></td><td><code>{{ item.password }}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="result.alreadyCreated?.length" class="sub-result">
        <strong>Akun yang sudah ada (password tidak diubah)</strong>
        <p v-for="item in result.alreadyCreated" :key="item.username">{{ item.attendance_number }} · {{ item.full_name }} · {{ item.username }}</p>
      </div>
      <div v-if="result.failures?.length" class="sub-result failures">
        <strong>Akun yang perlu diperiksa</strong>
        <p v-for="item in result.failures" :key="item.username">{{ item.username }} · {{ item.full_name }}: {{ item.error }}</p>
      </div>
    </section>
  </div>
</template>

<style scoped>
.accounts-page { display: flex; flex-direction: column; gap: var(--space-4); }
.back-link { display: inline-flex; align-items: center; gap: 7px; width: fit-content; color: var(--c-primary); font-size: 13px; font-weight: 700; }
.info-card, .action-card, .result-card { padding: var(--space-5); border: 1px solid var(--c-border); border-radius: var(--radius-lg); background: var(--c-white); box-shadow: var(--shadow-sm); }
.info-card { display: flex; align-items: flex-start; gap: var(--space-3); }
.info-icon { width: 44px; height: 44px; flex: 0 0 44px; display: grid; place-items: center; border-radius: 14px; color: var(--c-primary); background: var(--c-blue-soft); }
h2 { font-size: 16px; font-weight: 800; margin-bottom: 7px; }
.info-card p, .action-card > p, .result-note { color: var(--c-text-muted); font-size: 13px; line-height: 1.65; }
.action-heading { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; color: var(--c-text); }
.action-card > p { margin-bottom: var(--space-4); }
.error-message { margin-top: 12px; color: var(--c-danger) !important; }
.stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin: var(--space-4) 0; }
.stats > div { padding: 12px; border-radius: var(--radius-md); background: var(--c-gray); display: flex; flex-direction: column; gap: 3px; }
.stats strong { font-size: 22px; }.stats span { color: var(--c-text-muted); font-size: 11px; }
.credential-actions { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: var(--space-3); }
.table-wrap { overflow-x: auto; border: 1px solid var(--c-border); border-radius: var(--radius-md); }
table { width: 100%; border-collapse: collapse; min-width: 620px; font-size: 12px; text-align: left; }
th, td { padding: 10px 12px; border-bottom: 1px solid var(--c-border); white-space: nowrap; }
th { background: var(--c-gray); font-weight: 800; } td code { font-size: 11px; }
.sub-result { margin-top: var(--space-4); font-size: 12px; line-height: 1.7; }.sub-result p { color: var(--c-text-muted); }.failures { color: var(--c-danger); }
@media (max-width: 480px) { .info-card, .action-card, .result-card { padding: var(--space-4); } }
</style>
