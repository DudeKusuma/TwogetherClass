<script setup>
import { computed, reactive, ref } from 'vue'
import { Plus, Pencil, Trash2, CalendarClock } from 'lucide-vue-next'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import EmptyState from '@/components/shared/EmptyState.vue'
import AdminBackLink from '@/components/admin/AdminBackLink.vue'
import { subjects } from '@/data/subjects'
import { useSubjectStore, ACTIVITY_TYPES, activityLabel } from '@/stores/useSubjectStore'
import { nextSchoolDay } from '@/composables/useSchoolDay'
import { toISODate } from '@/utils/time'

const store = useSubjectStore()
const subjectList = Object.values(subjects)
const defaultDate = () => toISODate(nextSchoolDay(new Date()))
const nextDayTitle = new Intl.DateTimeFormat('id-ID', { weekday: 'long', day: 'numeric', month: 'long' }).format(nextSchoolDay(new Date()))
const dateFmt = new Intl.DateTimeFormat('id-ID', { weekday: 'short', day: 'numeric', month: 'short' })
const formatDate = (iso) => dateFmt.format(new Date(`${iso}T00:00:00`))

const blank = () => ({ subject: '', type: 'tugas', title: '', notes: '', date: defaultDate() })
const form = reactive(blank())
const editingId = ref(null)
const error = ref('')
const confirmId = ref(null)
const formEl = ref(null)

const list = computed(() => store.sortedActivities())

function reset() {
  Object.assign(form, blank())
  editingId.value = null
  error.value = ''
}

async function submit() {
  const result = editingId.value ? await store.updateActivity(editingId.value, { ...form }) : await store.addActivity({ ...form })
  if (result) {
    error.value = result
    return
  }
  reset()
}

function startEdit(a) {
  Object.assign(form, { subject: a.subject, type: a.type, title: a.title, notes: a.notes, date: a.date })
  editingId.value = a.id
  confirmId.value = null
  error.value = ''
  formEl.value?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

async function confirmDelete(id) {
  await store.removeActivity(id)
  confirmId.value = null
  if (editingId.value === id) reset()
}
</script>

<template>
  <div class="tomorrow" data-testid="admin-tomorrow-page">
    <AdminBackLink />
    <header class="page-head">
      <span class="page-head__eyebrow">Admin Power</span>
      <h1 class="page-head__title">Jadwal Besok</h1>
      <p class="page-head__desc">
        Catat tugas, kuis, ulangan, atau info lain per mata pelajaran. Siswa melihatnya saat membuka kartu mata pelajaran.
        Hari sekolah berikutnya: <b>{{ nextDayTitle }}</b>.
      </p>
    </header>

    <div class="tomorrow__grid">
      <div ref="formEl">
        <BaseCard tag="form" class="tomorrow__form" novalidate data-testid="activity-form" @submit.prevent="submit">
          <h2 class="tomorrow__form-title">{{ editingId ? 'Ubah aktivitas' : 'Aktivitas baru' }}</h2>

          <label class="form-field">
            <span class="form-label">Mata pelajaran</span>
            <select v-model="form.subject" class="form-input" data-testid="activity-subject-select">
              <option value="" disabled>Pilih mata pelajaran</option>
              <option v-for="s in subjectList" :key="s.key" :value="s.key">{{ s.name }}</option>
            </select>
          </label>

          <fieldset class="types">
            <legend class="form-label">Jenis aktivitas</legend>
            <div class="types__row">
              <label v-for="t in ACTIVITY_TYPES" :key="t.value" class="types__opt" :class="{ 'is-on': form.type === t.value }">
                <input v-model="form.type" type="radio" name="activity-type" :value="t.value" :data-testid="`activity-type-${t.value}`" />
                {{ t.label }}
              </label>
            </div>
          </fieldset>

          <label class="form-field">
            <span class="form-label">Judul</span>
            <input v-model="form.title" class="form-input" maxlength="120" placeholder="Contoh: Kuis Bab 3" data-testid="activity-title-input" />
          </label>

          <label class="form-field">
            <span class="form-label">Catatan (opsional)</span>
            <textarea v-model="form.notes" class="form-input form-textarea" rows="4" placeholder="Materi, halaman, atau barang yang perlu dibawa" data-testid="activity-notes-input" />
          </label>

          <label class="form-field">
            <span class="form-label">Tanggal (tenggat / pelaksanaan)</span>
            <input v-model="form.date" type="date" class="form-input" data-testid="activity-date-input" />
          </label>

          <p v-if="error" class="form-error" role="alert" data-testid="activity-form-error">{{ error }}</p>

          <div class="tomorrow__actions">
            <BaseButton type="submit" data-testid="activity-submit-button">
              <Plus v-if="!editingId" :size="18" /> {{ editingId ? 'Simpan perubahan' : 'Tambah aktivitas' }}
            </BaseButton>
            <BaseButton v-if="editingId" variant="ghost" data-testid="activity-cancel-edit-button" @click="reset">Batal</BaseButton>
          </div>
        </BaseCard>
      </div>

      <section class="tomorrow__list" data-testid="activity-admin-list">
        <header class="section-head">
          <div>
            <h2 class="section-head__title">Aktivitas tercatat</h2>
            <p class="section-head__meta">{{ list.length }} aktivitas</p>
          </div>
        </header>

        <BaseCard v-if="!list.length" :padded="false">
          <EmptyState :icon="CalendarClock" title="Belum ada aktivitas" description="Aktivitas yang kamu tambahkan akan muncul di sini." />
        </BaseCard>

        <BaseCard v-for="a in list" :key="a.id" class="act" :class="{ 'is-editing': editingId === a.id }" data-testid="activity-admin-item">
          <div class="act__head">
            <span class="act__icon"><img :src="subjects[a.subject]?.icon" :alt="''" /></span>
            <div class="act__info">
              <span class="act__subject" data-testid="activity-admin-item-subject">{{ subjects[a.subject]?.name }}</span>
              <h3 class="act__title" data-testid="activity-admin-item-title">{{ a.title }}</h3>
            </div>
            <span class="chip chip--blue" data-testid="activity-admin-item-type">{{ activityLabel(a.type) }}</span>
          </div>
          <p v-if="a.notes" class="act__notes">{{ a.notes }}</p>
          <p v-if="a.date" class="act__date">{{ formatDate(a.date) }}</p>
          <div v-if="confirmId === a.id" class="act__row" data-testid="activity-delete-confirm">
            <span class="act__confirm-text">Hapus aktivitas ini?</span>
            <BaseButton size="sm" variant="ghost" data-testid="activity-delete-cancel" @click="confirmId = null">Batal</BaseButton>
            <BaseButton size="sm" variant="danger-solid" data-testid="activity-delete-confirm-button" @click="confirmDelete(a.id)">Hapus</BaseButton>
          </div>
          <div v-else class="act__row">
            <BaseButton size="sm" variant="ghost" data-testid="activity-edit-button" @click="startEdit(a)"><Pencil :size="15" /> Ubah</BaseButton>
            <BaseButton size="sm" variant="danger" data-testid="activity-delete-button" @click="confirmId = a.id"><Trash2 :size="15" /> Hapus</BaseButton>
          </div>
        </BaseCard>
      </section>
    </div>
  </div>
</template>

<style scoped>
.tomorrow__grid {
  display: grid;
  gap: var(--space-6);
}

@media (min-width: 1024px) {
  .tomorrow__grid {
    grid-template-columns: minmax(0, 5fr) minmax(0, 7fr);
    align-items: start;
  }
}

.tomorrow__form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.tomorrow__form-title {
  font-size: 17px;
  font-weight: 800;
}

.types {
  border: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.types__row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.types__opt {
  position: relative;
  padding: 8px 16px;
  border-radius: var(--radius-pill);
  border: 1px solid var(--c-border);
  background: var(--c-white);
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 0.18s ease, color 0.18s ease, border-color 0.18s ease;
}

.types__opt input {
  position: absolute;
  opacity: 0;
  inset: 0;
  cursor: pointer;
}

.types__opt.is-on {
  background: var(--c-primary);
  border-color: var(--c-primary);
  color: var(--c-white);
}

.types__opt:has(input:focus-visible) {
  outline: 2px solid var(--c-primary);
  outline-offset: 2px;
}

.tomorrow__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tomorrow__list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  min-width: 0;
}

.tomorrow__list .section-head {
  margin-bottom: 0;
}

.act {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.act.is-editing {
  box-shadow: 0 0 0 2px var(--c-primary);
}

.act__head {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.act__icon {
  width: 44px;
  height: 44px;
  border-radius: 14px;
  background: var(--c-gray);
  overflow: hidden;
  flex-shrink: 0;
}

.act__icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.act__info {
  flex: 1;
  min-width: 0;
}

.act__subject {
  font-size: 12px;
  font-weight: 700;
  color: var(--c-text-muted);
}

.act__title {
  font-size: 15px;
  font-weight: 800;
  overflow-wrap: anywhere;
}

.act__notes {
  font-size: 13px;
  color: var(--c-text-muted);
  white-space: pre-line;
  overflow-wrap: anywhere;
}

.act__date {
  font-size: 12px;
  font-weight: 700;
  color: var(--c-text-soft);
}

.act__row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
}

.act__confirm-text {
  font-size: 13px;
  font-weight: 700;
  margin-right: auto;
}
</style>
