<script setup>
import { computed, onMounted, ref } from 'vue'
import { UserRound, Save, Heart, Sparkles, LockKeyhole, CheckCircle2, Coins } from 'lucide-vue-next'
import BaseCard from '@/components/base/BaseCard.vue'
import PagePlaceholder from '@/components/shared/PagePlaceholder.vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/useAuthStore'

const auth = useAuthStore()
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const fullName = ref('')
const studentNumber = ref('')
const attendanceNumber = ref(null)
const adminOnly = ref(false)
const cosmetics = ref({})
const tMoney = ref(null)
const form = ref({
  short_name: '',
  birth_place: '',
  birth_date: '',
  gender: '',
  address: '',
  hobbies: [],
  about_me: [],
  show_student_number: false,
  discover_opt_in: false
})

const hobbyOptions = [
  '🎧 Music', '🎮 Gaming', '🏀 Basketball', '🎬 Movies', '📚 Comics',
  '📖 Reading', '📷 Photography', '🎨 Drawing', '⚽ Football',
  '🏸 Badminton', '🎤 Singing', '💃 Dancing', '💻 Coding',
  '🧑‍🍳 Cooking', '✈️ Traveling', '🐱 Pets'
]
const aboutOptions = [
  '😆 Funny', '💗 Romantic', '😎 Chill', '🎨 Creative', '🤫 Quiet',
  '⚡ Energetic', '🌻 Cheerful', '🧠 Curious', '🤝 Friendly',
  '🎯 Ambitious', '🥹 Sensitive', '🦉 Introvert', '🎉 Extrovert', '🤍 Caring'
]
const initial = computed(() => (form.value.short_name || auth.user?.displayName || 'S').trim().charAt(0).toUpperCase())

function toggleChoice(key, value, limit) {
  const values = form.value[key]
  if (values.includes(value)) form.value[key] = values.filter(item => item !== value)
  else if (values.length < limit) form.value[key] = [...values, value]
}

async function loadProfile() {
  loading.value = true
  error.value = ''
  adminOnly.value = false
  const [cosmeticResult, walletResult] = await Promise.all([
    supabase.from('student_cosmetics').select('profile_color,name_color,title_color').eq('profile_id', auth.user.id).maybeSingle(),
    supabase.rpc('get_my_t_money')
  ])
  cosmetics.value = cosmeticResult.data || {}
  tMoney.value = walletResult.error ? null : (walletResult.data?.balance ?? 0)
  const { data, error: requestError } = await supabase.rpc('get_student_profile', {
    target_profile_id: auth.user.id
  })
  if (requestError) {
    error.value = 'Profil belum dapat dimuat. Jalankan migration Student Profile di Supabase terlebih dahulu.'
  } else if (!data && auth.isAdmin) {
    adminOnly.value = true
  } else if (!data) {
    error.value = 'Akun ini belum terhubung ke data siswa di roster kelas. Minta admin menghubungkan akun terlebih dahulu.'
  } else {
    fullName.value = data.full_name || ''
    studentNumber.value = data.student_number || ''
    attendanceNumber.value = data.attendance_number ?? null
    if (data.short_name) auth.user.displayName = data.short_name
    form.value = {
      short_name: data.short_name === data.full_name ? '' : (data.short_name || ''),
      birth_place: data.birth_place || '',
      birth_date: data.birth_date || '',
      gender: data.gender || '',
      address: data.address || '',
      hobbies: Array.isArray(data.hobbies) ? data.hobbies : [],
      about_me: Array.isArray(data.about_me) ? data.about_me : [],
      show_student_number: data.show_student_number === true,
      discover_opt_in: data.discover_opt_in === true
    }
  }
  loading.value = false
}

async function saveProfile() {
  error.value = ''
  success.value = ''
  if (form.value.short_name.trim().length > 40) {
    error.value = 'Nama pendek maksimal 40 karakter.'
    return
  }
  if (form.value.hobbies.length > 8 || form.value.about_me.length > 6) {
    error.value = 'Pilihan hobi maksimal 8 dan About Me maksimal 6.'
    return
  }
  saving.value = true
  const payload = {
    profile_id: auth.user.id,
    short_name: form.value.short_name.trim(),
    birth_place: form.value.birth_place.trim(),
    birth_date: form.value.birth_date || null,
    gender: form.value.gender || null,
    address: form.value.address.trim(),
    hobbies: form.value.hobbies,
    about_me: form.value.about_me,
    show_student_number: form.value.show_student_number,
    discover_opt_in: form.value.discover_opt_in,
    updated_at: new Date().toISOString()
  }
  const { error: saveError } = await supabase
    .from('student_profile_details')
    .upsert(payload, { onConflict: 'profile_id' })
  if (saveError) {
    error.value = saveError.message
  } else {
    const { data } = await supabase.rpc('get_student_profile', {
      target_profile_id: auth.user.id
    })
    if (data?.short_name) auth.user.displayName = data.short_name
    success.value = 'Profil berhasil disimpan.'
  }
  saving.value = false
}

onMounted(loadProfile)
</script>

<template>
  <PagePlaceholder eyebrow="Profil Saya" title="Profil Saya" :icon="UserRound" tone="lavender" test-id="profile-page">
    <div class="profile-page-content">
      <BaseCard class="profile-identity" data-testid="profile-user-card">
        <span class="profile-avatar" :style="cosmetics.profile_color ? { background: cosmetics.profile_color, color: '#3b4658' } : {}">{{ initial }}</span>
        <div class="profile-identity__text">
          <h2 data-testid="profile-display-name" :style="cosmetics.name_color ? { color: cosmetics.name_color } : {}">{{ form.short_name || auth.user?.displayName || 'Profil Siswa' }}</h2>
          <p :style="cosmetics.title_color ? { color: cosmetics.title_color } : {}">{{ auth.roleLabel }} · XI-B2 · SMA Negeri 1 Gianyar</p>
          <small>Avatar menggunakan inisial nama. Foto profil belum digunakan.</small>
        </div>
        <div class="profile-wallet"><span><Coins :size="17" /> T-Money</span><strong>{{ tMoney === null ? 'Belum tersedia' : tMoney.toLocaleString('id-ID') }}</strong></div>
      </BaseCard>

      <p v-if="error" class="profile-message profile-message--error" role="alert">{{ error }}</p>
      <p v-if="success" class="profile-message profile-message--success"><CheckCircle2 :size="16"/> {{ success }}</p>
      <div v-if="loading" class="profile-loading">Memuat informasi profil...</div>
      <BaseCard v-else-if="adminOnly" class="profile-section">
        <h3>Profil Admin</h3>
        <p class="section-note">{{ auth.user?.displayName }} · Admin Kelas · XI-B2</p>
        <p class="section-note">Pengaturan profil siswa tersedia untuk akun yang terhubung ke roster kelas.</p>
      </BaseCard>

      <template v-else-if="!error">
        <BaseCard class="profile-section">
          <div class="profile-section__heading">
            <div><span class="section-kicker">01 · IDENTITAS</span><h3>Basic Information</h3></div>
            <LockKeyhole :size="18"/>
          </div>
          <p class="section-note">Data akademik diambil dari roster kelas dan hanya bisa diperbarui oleh admin.</p>
          <div class="readonly-grid">
            <label><span>Nama lengkap</span><input :value="fullName || 'Belum tersedia'" disabled /></label>
            <label><span>NISN</span><input :value="studentNumber || 'Belum tersedia'" disabled /></label>
            <label><span>Nomor absen</span><input :value="attendanceNumber ?? 'Belum tersedia'" disabled /></label>
          </div>
          <div class="profile-fields">
            <label>Nama pendek / panggilan<input v-model="form.short_name" maxlength="40" placeholder="Contoh: Alex"/></label>
            <label>Tempat lahir<input v-model="form.birth_place" maxlength="80" placeholder="Contoh: Denpasar"/></label>
            <label>Tanggal lahir<input v-model="form.birth_date" type="date"/></label>
            <label>Jenis kelamin
              <select v-model="form.gender">
                <option value="">Pilih (opsional)</option>
                <option value="L">Laki-laki</option>
                <option value="P">Perempuan</option>
                <option value="Prefer not to say">Tidak ingin menyebutkan</option>
              </select>
            </label>
            <label class="field-full">Alamat tempat tinggal<textarea v-model="form.address" maxlength="180" rows="2" placeholder="Contoh: Gianyar, Bali"/></label>
          </div>
        </BaseCard>

        <BaseCard class="profile-section">
          <div class="profile-section__heading">
            <div><span class="section-kicker">02 · INTERESTS</span><h3><Heart :size="17"/> My Hobbies</h3></div>
            <span class="selection-count">{{ form.hobbies.length }}/8</span>
          </div>
          <p class="section-note">Pilih hobi yang paling menggambarkan dirimu. Maksimal 8 pilihan.</p>
          <div class="choice-grid">
            <button v-for="item in hobbyOptions" :key="item" type="button" :class="{ selected: form.hobbies.includes(item) }" @click="toggleChoice('hobbies', item, 8)">{{ item }}</button>
          </div>
        </BaseCard>

        <BaseCard class="profile-section">
          <div class="profile-section__heading">
            <div><span class="section-kicker">03 · PERSONALITY</span><h3><Sparkles :size="17"/> About Me</h3></div>
            <span class="selection-count">{{ form.about_me.length }}/6</span>
          </div>
          <p class="section-note">Pilih kata yang menggambarkan kepribadianmu. Maksimal 6 pilihan.</p>
          <div class="choice-grid">
            <button v-for="item in aboutOptions" :key="item" type="button" :class="{ selected: form.about_me.includes(item) }" @click="toggleChoice('about_me', item, 6)">{{ item }}</button>
          </div>
        </BaseCard>

        <BaseCard class="profile-section privacy-section">
          <div class="profile-section__heading">
            <div><span class="section-kicker">04 · PRIVACY</span><h3>Privacy Settings</h3></div>
            <LockKeyhole :size="18"/>
          </div>
          <label class="privacy-toggle">
            <span><b>Tampilkan NISN ke siswa lain</b><small>Jika dinonaktifkan, hanya kamu dan admin yang dapat melihat NISN-mu.</small></span>
            <input v-model="form.show_student_number" type="checkbox"/>
          </label>
          <p class="section-note">Admin kelas tetap dapat melihat NISN meskipun pengaturan ini dimatikan.</p>
          <label class="privacy-toggle">
            <span><b>Izinkan profil tampil di Discover Students</b><small>Nama panggilan, hobi, dan pilihan About Me dapat dilihat teman sekelas. Isi Short name agar profilmu muncul. Data sensitif seperti alamat, tanggal lahir, dan NIS tidak ditampilkan.</small></span>
            <input v-model="form.discover_opt_in" type="checkbox"/>
          </label>
        </BaseCard>

        <button class="profile-save" type="button" :disabled="saving" @click="saveProfile">
          <Save :size="17"/> {{ saving ? 'Menyimpan...' : 'Simpan perubahan' }}
        </button>
      </template>
    </div>
  </PagePlaceholder>
</template>

<style scoped>
.profile-page-content{display:grid;gap:14px}
.profile-identity{display:flex;align-items:center;gap:14px}
.profile-avatar{width:62px;height:62px;border-radius:50%;display:grid;place-items:center;flex-shrink:0;background:var(--c-primary);color:white;font-size:25px;font-weight:850}
.profile-identity__text{min-width:0;flex:1}
.profile-wallet{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:10px 12px;border-radius:12px;background:#f6f2ff;color:#7655b5;min-width:145px}.profile-wallet span{display:flex;align-items:center;gap:6px;font-size:11px;font-weight:800}.profile-wallet strong{font-size:17px;font-weight:900}
.profile-identity__text h2{font-size:18px;font-weight:850}
.profile-identity__text p{font-size:12px;color:var(--c-text-muted);margin-top:4px}
.profile-identity__text small{font-size:10px;color:var(--c-text-soft);display:block;margin-top:5px}
.profile-section{display:grid;gap:14px}
.profile-section__heading{display:flex;align-items:center;justify-content:space-between;gap:10px}
.profile-section__heading>svg{color:var(--c-primary)}
.profile-section__heading h3{display:flex;align-items:center;gap:7px;font-size:16px;font-weight:850;margin-top:4px}
.section-kicker{font-size:9px;font-weight:850;letter-spacing:.1em;color:var(--c-text-muted)}
.section-note{font-size:11px;color:var(--c-text-muted);line-height:1.5}
.readonly-grid,.profile-fields{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}
.profile-fields label,.readonly-grid label{display:grid;gap:6px;font-size:11px;font-weight:750;color:var(--c-text)}
.profile-fields input,.profile-fields select,.profile-fields textarea,.readonly-grid input{width:100%;min-width:0;padding:11px 12px;border:1px solid var(--c-border);border-radius:11px;background:var(--c-gray);color:var(--c-text);font:inherit;font-size:12px}
.readonly-grid input{background:#f0f1f4;color:var(--c-text-muted);cursor:not-allowed}
.profile-fields input:focus,.profile-fields select:focus,.profile-fields textarea:focus{outline:2px solid var(--c-blue-soft);border-color:var(--c-primary);background:white}
.field-full{grid-column:1/-1}
.selection-count{font-size:10px;font-weight:800;color:var(--c-text-muted);background:var(--c-gray);padding:5px 9px;border-radius:20px}
.choice-grid{display:flex;flex-wrap:wrap;gap:8px}
.choice-grid button{border:1px solid var(--c-border);border-radius:999px;padding:8px 11px;background:var(--c-white);color:var(--c-text);font:inherit;font-size:11px;font-weight:700;transition:background .15s,border-color .15s}
.choice-grid button.selected{background:var(--c-lavender);border-color:var(--c-primary);color:var(--c-primary)}
.privacy-toggle{display:flex;align-items:center;justify-content:space-between;gap:14px;padding:13px;border:1px solid var(--c-border);border-radius:14px;background:var(--c-gray)}
.privacy-toggle span{display:grid;gap:5px}
.privacy-toggle b{font-size:12px}
.privacy-toggle small{font-size:10px;color:var(--c-text-muted);line-height:1.45}
.privacy-toggle input{width:19px;height:19px;accent-color:var(--c-primary);flex-shrink:0}
.profile-save{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:14px;border:0;border-radius:13px;background:var(--c-primary);color:white;font-weight:800;font-size:13px;box-shadow:var(--shadow-primary)}
.profile-save:disabled{opacity:.6;cursor:wait}
.profile-message{display:flex;align-items:center;gap:7px;padding:11px 13px;border-radius:12px;font-size:12px}
.profile-message--error{background:#fff0f0;color:#b42b36}
.profile-message--success{background:#e9f9ef;color:#167b48}
.profile-loading{padding:30px;text-align:center;color:var(--c-text-muted);font-size:12px}
@media(max-width:520px){.readonly-grid,.profile-fields{grid-template-columns:1fr}.field-full{grid-column:auto}.profile-identity{flex-wrap:wrap}.profile-wallet{width:100%}}
</style>
