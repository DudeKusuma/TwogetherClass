<script setup>
import { computed, ref, watch, onBeforeUnmount } from 'vue'
import { X, IdCard, Heart, Sparkles } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/useAuthStore'

const props = defineProps({
  profileId: { type: String, default: '' }
})
const emit = defineEmits(['close'])
const auth = useAuthStore()
const profile = ref(null)
const loading = ref(false)
const error = ref('')
const isAdmin = computed(() => auth.isAdmin)
const genderLabel = computed(() => ({
  L: 'Laki-laki',
  P: 'Perempuan',
  'Prefer not to say': 'Tidak ingin menyebutkan'
}[profile.value?.gender] || 'Belum diisi'))
const birthDateLabel = computed(() => {
  if (!profile.value?.birth_date) return 'Belum diisi'
  const [year, month, day] = profile.value.birth_date.split('-').map(Number)
  return new Date(year, month - 1, day).toLocaleDateString('id-ID', {
    day: 'numeric', month: 'long', year: 'numeric'
  })
})
const hobbies = computed(() => Array.isArray(profile.value?.hobbies) ? profile.value.hobbies : [])
const traits = computed(() => Array.isArray(profile.value?.about_me) ? profile.value.about_me : [])

async function loadProfile(id) {
  if (!id) return
  loading.value = true
  error.value = ''
  profile.value = null
  const { data, error: requestError } = await supabase.rpc('get_student_profile', {
    target_profile_id: id
  })
  if (requestError) {
    error.value = 'Profil belum dapat dimuat. Pastikan migration Student Profile sudah dijalankan.'
  } else if (!data) {
    error.value = 'Profil siswa belum tersedia atau akun belum terhubung ke roster.'
  } else {
    profile.value = data
  }
  loading.value = false
}

function onKey(event) {
  if (event.key === 'Escape') emit('close')
}

watch(() => props.profileId, (id) => {
  if (id) loadProfile(id)
}, { immediate: true })

watch(() => Boolean(props.profileId), (open) => {
  document.body.style.overflow = open ? 'hidden' : ''
  if (open) document.addEventListener('keydown', onKey)
  else document.removeEventListener('keydown', onKey)
}, { immediate: true })

onBeforeUnmount(() => {
  document.body.style.overflow = ''
  document.removeEventListener('keydown', onKey)
})
</script>

<template>
  <Teleport to="body">
    <Transition name="student-profile-fade">
      <div v-if="profileId" class="student-profile-overlay" @click.self="emit('close')">
        <section class="student-profile-modal" role="dialog" aria-modal="true" aria-label="Profil siswa">
          <header class="student-profile-header">
            <div>
              <span class="student-profile-eyebrow">TWogether class · XI-B2</span>
              <h2>Student Profile</h2>
            </div>
            <button class="student-profile-close" type="button" aria-label="Tutup profil" @click="emit('close')">
              <X :size="19"/>
            </button>
          </header>

          <div v-if="loading" class="student-profile-state">Memuat profil siswa...</div>
          <div v-else-if="error" class="student-profile-state student-profile-error">{{ error }}</div>
          <template v-else-if="profile">
            <div class="student-profile-hero">
              <div class="student-profile-avatar">{{ (profile.short_name || profile.full_name || '?').charAt(0).toUpperCase() }}</div>
              <h3>{{ profile.short_name || profile.full_name }}</h3>
              <p>XI-B2 · Siswa</p>
            </div>

            <section class="student-profile-section">
              <h4><IdCard :size="16"/> Basic Information</h4>
              <dl class="student-profile-grid">
                <div><dt>Nama lengkap</dt><dd>{{ profile.full_name || 'Belum tersedia' }}</dd></div>
                <div><dt>Nomor absen</dt><dd>{{ profile.attendance_number ?? '—' }}</dd></div>
                <div v-if="profile.student_number"><dt>NISN</dt><dd>{{ profile.student_number }}</dd></div>
                <div><dt>Tempat lahir</dt><dd>{{ profile.birth_place || 'Belum diisi' }}</dd></div>
                <div><dt>Tanggal lahir</dt><dd>{{ birthDateLabel }}</dd></div>
                <div><dt>Jenis kelamin</dt><dd>{{ genderLabel }}</dd></div>
                <div class="student-profile-wide"><dt>Alamat tempat tinggal</dt><dd>{{ profile.address || 'Belum diisi' }}</dd></div>
              </dl>
              <p v-if="!profile.student_number && (isAdmin || profile.profile_id === auth.user?.id)" class="student-profile-muted">
                NISN belum tersedia.
              </p>
            </section>

            <section class="student-profile-section">
              <h4><Heart :size="16"/> My Hobbies</h4>
              <div v-if="hobbies.length" class="student-profile-chips">
                <span v-for="item in hobbies" :key="item">{{ item }}</span>
              </div>
              <p v-else class="student-profile-muted">Belum menambahkan hobi.</p>
            </section>

            <section class="student-profile-section">
              <h4><Sparkles :size="16"/> About Me</h4>
              <div v-if="traits.length" class="student-profile-chips">
                <span v-for="item in traits" :key="item">{{ item }}</span>
              </div>
              <p v-else class="student-profile-muted">Belum mengisi About Me.</p>
            </section>
          </template>
        </section>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.student-profile-overlay{position:fixed;inset:0;z-index:160;background:rgba(24,32,48,.48);display:grid;place-items:center;padding:18px;backdrop-filter:blur(3px)}
.student-profile-modal{width:min(100%,520px);max-height:min(88dvh,780px);overflow:auto;background:var(--c-white);border:1px solid var(--c-border);border-radius:24px;padding:22px;box-shadow:var(--shadow-lg);color:var(--c-text)}
.student-profile-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:18px}
.student-profile-header h2{font-size:19px;font-weight:800}
.student-profile-eyebrow{font-size:10px;font-weight:800;letter-spacing:.09em;text-transform:uppercase;color:var(--c-text-muted)}
.student-profile-close{width:36px;height:36px;border:0;border-radius:50%;background:var(--c-gray);display:grid;place-items:center;color:var(--c-text)}
.student-profile-hero{display:flex;align-items:center;flex-direction:column;text-align:center;padding:8px 0 20px}
.student-profile-avatar{width:72px;height:72px;border-radius:50%;display:grid;place-items:center;background:var(--c-primary);color:white;font-size:29px;font-weight:800;box-shadow:var(--shadow-md);margin-bottom:10px}
.student-profile-hero h3{font-size:21px;font-weight:850}
.student-profile-hero p{font-size:12px;color:var(--c-text-muted);margin-top:4px}
.student-profile-section{border-top:1px solid var(--c-border);padding:16px 0 4px}
.student-profile-section h4{display:flex;align-items:center;gap:8px;font-size:13px;font-weight:800;margin-bottom:12px}
.student-profile-section h4 :deep(svg){color:var(--c-primary)}
.student-profile-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
.student-profile-grid>div{min-width:0;padding:10px 12px;background:var(--c-gray);border-radius:12px}
.student-profile-grid dt{font-size:10px;color:var(--c-text-muted);margin-bottom:4px}
.student-profile-grid dd{font-size:12px;font-weight:700;overflow-wrap:anywhere}
.student-profile-wide{grid-column:1/-1}
.student-profile-chips{display:flex;flex-wrap:wrap;gap:7px}
.student-profile-chips span{background:var(--c-lavender);color:var(--c-primary);padding:7px 10px;border-radius:999px;font-size:11px;font-weight:700}
.student-profile-muted{font-size:11px;color:var(--c-text-muted)}
.student-profile-state{padding:44px 12px;text-align:center;color:var(--c-text-muted);font-size:13px}
.student-profile-error{color:var(--c-danger)}
.student-profile-fade-enter-active,.student-profile-fade-leave-active{transition:opacity .18s ease}
.student-profile-fade-enter-from,.student-profile-fade-leave-to{opacity:0}
@media(max-width:420px){.student-profile-modal{padding:17px;border-radius:20px}.student-profile-grid{grid-template-columns:1fr}.student-profile-wide{grid-column:auto}}
</style>
