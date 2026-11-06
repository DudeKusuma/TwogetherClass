<script setup>
import { reactive, ref } from 'vue'
import { Plus, Pencil, Trash2, Power, Megaphone } from 'lucide-vue-next'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import EmptyState from '@/components/shared/EmptyState.vue'
import AdminBackLink from '@/components/admin/AdminBackLink.vue'
import { useAnnouncementStore } from '@/stores/useAnnouncementStore'

const store = useAnnouncementStore()
const form = reactive({ title: '', body: '', active: true })
const editingId = ref(null)
const error = ref('')
const confirmId = ref(null)
const formEl = ref(null)

function reset() {
  Object.assign(form, { title: '', body: '', active: true })
  editingId.value = null
  error.value = ''
}

async function submit() {
  if (!form.title.trim() || !form.body.trim()) {
    error.value = 'Judul dan isi pengumuman wajib diisi.'
    return
  }
  if (editingId.value) {
    await store.update(editingId.value, { title: form.title.trim(), body: form.body.trim(), active: form.active })
  } else {
    await store.create({ ...form })
  }
  reset()
}

function startEdit(a) {
  Object.assign(form, { title: a.title, body: a.body, active: a.active })
  editingId.value = a.id
  confirmId.value = null
  error.value = ''
  formEl.value?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

async function confirmDelete(id) {
  await store.remove(id)
  confirmId.value = null
  if (editingId.value === id) reset()
}
</script>

<template>
  <div class="admin" data-testid="admin-announcements-page">
    <AdminBackLink />
    <header class="page-head">
      <span class="page-head__eyebrow">Admin Power</span>
      <h1 class="page-head__title">Kelola Pengumuman</h1>
      <p class="page-head__desc">
        Buat, ubah, aktifkan, atau hapus pengumuman kelas. Perubahan tersimpan di database kelas dan dapat dilihat anggota yang masuk.
      </p>
    </header>

    <div class="admin__grid">
      <div ref="formEl">
        <BaseCard tag="form" class="admin__form" novalidate data-testid="announcement-form" @submit.prevent="submit">
          <h2 class="admin__form-title">{{ editingId ? 'Ubah pengumuman' : 'Pengumuman baru' }}</h2>
          <label class="field">
            <span class="field__label">Judul</span>
            <input v-model="form.title" class="field__input" maxlength="120" placeholder="Judul pengumuman" data-testid="announcement-title-input" />
          </label>
          <label class="field">
            <span class="field__label">Isi pengumuman</span>
            <textarea v-model="form.body" class="field__input field__textarea" rows="5" placeholder="Tulis isi pengumuman" data-testid="announcement-body-input" />
          </label>
          <label class="toggle">
            <input v-model="form.active" type="checkbox" data-testid="announcement-active-checkbox" />
            <span class="toggle__track"><span class="toggle__thumb" /></span>
            <span class="toggle__label">{{ form.active ? 'Aktif — tampil ke siswa' : 'Nonaktif — disembunyikan' }}</span>
          </label>
          <p v-if="error" class="admin__error" role="alert" data-testid="announcement-form-error">{{ error }}</p>
          <div class="admin__form-actions">
            <BaseButton type="submit" data-testid="announcement-submit-button">
              <Plus v-if="!editingId" :size="18" /> {{ editingId ? 'Simpan perubahan' : 'Tambah pengumuman' }}
            </BaseButton>
            <BaseButton v-if="editingId" variant="ghost" data-testid="announcement-cancel-edit-button" @click="reset">Batal</BaseButton>
          </div>
        </BaseCard>
      </div>

      <section class="admin__list" data-testid="announcement-admin-list">
        <header class="section-head">
          <div>
            <h2 class="section-head__title">Semua pengumuman</h2>
            <p class="section-head__meta">{{ store.items.length }} total · {{ store.active.length }} aktif</p>
          </div>
        </header>

        <BaseCard v-if="!store.sorted.length" :padded="false">
          <EmptyState :icon="Megaphone" tone="yellow" title="Belum ada pengumuman" description="Pengumuman yang kamu buat akan muncul di sini." />
        </BaseCard>

        <BaseCard v-for="a in store.sorted" :key="a.id" class="ann" :class="{ 'is-editing': editingId === a.id }" data-testid="announcement-admin-item">
          <div class="ann__head">
            <h3 class="ann__title" data-testid="announcement-admin-item-title">{{ a.title }}</h3>
            <span class="chip" :class="a.active ? 'chip--mint' : 'chip--gray'" data-testid="announcement-admin-item-status">
              {{ a.active ? 'Aktif' : 'Nonaktif' }}
            </span>
          </div>
          <p class="ann__body">{{ a.body }}</p>
          <div v-if="confirmId === a.id" class="ann__confirm" data-testid="announcement-delete-confirm">
            <span>Hapus pengumuman ini?</span>
            <BaseButton size="sm" variant="ghost" data-testid="announcement-delete-cancel" @click="confirmId = null">Batal</BaseButton>
            <BaseButton size="sm" variant="danger-solid" data-testid="announcement-delete-confirm-button" @click="confirmDelete(a.id)">Hapus</BaseButton>
          </div>
          <div v-else class="ann__actions">
            <BaseButton size="sm" variant="secondary" data-testid="announcement-toggle-button" @click="store.toggleActive(a.id)">
              <Power :size="15" /> {{ a.active ? 'Nonaktifkan' : 'Aktifkan' }}
            </BaseButton>
            <BaseButton size="sm" variant="ghost" data-testid="announcement-edit-button" @click="startEdit(a)">
              <Pencil :size="15" /> Ubah
            </BaseButton>
            <BaseButton size="sm" variant="danger" data-testid="announcement-delete-button" @click="confirmId = a.id">
              <Trash2 :size="15" /> Hapus
            </BaseButton>
          </div>
        </BaseCard>
      </section>
    </div>
  </div>
</template>

<style scoped>
.admin__grid {
  display: grid;
  gap: var(--space-6);
}

@media (min-width: 1024px) {
  .admin__grid {
    grid-template-columns: minmax(0, 5fr) minmax(0, 7fr);
    align-items: start;
  }
}

.admin__form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.admin__form-title {
  font-size: 17px;
  font-weight: 800;
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
  height: 46px;
  padding: 0 14px;
  border-radius: var(--radius-md);
  border: 1px solid var(--c-border);
  background: var(--c-gray);
  font-size: 14px;
  transition: border-color 0.18s ease, background-color 0.18s ease;
}

.field__textarea {
  height: auto;
  padding: 12px 14px;
  resize: vertical;
  min-height: 110px;
}

.field__input:focus {
  outline: none;
  border-color: var(--c-primary);
  background: var(--c-white);
}

.toggle {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}

.toggle input {
  position: absolute;
  opacity: 0;
  width: 1px;
  height: 1px;
}

.toggle__track {
  width: 44px;
  height: 26px;
  border-radius: var(--radius-pill);
  background: #d7dce6;
  position: relative;
  transition: background-color 0.18s ease;
  flex-shrink: 0;
}

.toggle__thumb {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--c-white);
  box-shadow: var(--shadow-sm);
  transition: transform 0.18s var(--ease);
}

.toggle input:checked + .toggle__track {
  background: var(--c-primary);
}

.toggle input:checked + .toggle__track .toggle__thumb {
  transform: translateX(18px);
}

.toggle input:focus-visible + .toggle__track {
  outline: 2px solid var(--c-primary);
  outline-offset: 2px;
}

.toggle__label {
  font-size: 13px;
  font-weight: 600;
  color: var(--c-text-muted);
}

.admin__error {
  font-size: 13px;
  font-weight: 600;
  color: var(--c-danger);
}

.admin__form-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.admin__list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  min-width: 0;
}

.admin__list .section-head {
  margin-bottom: 0;
}

.ann {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.ann.is-editing {
  box-shadow: 0 0 0 2px var(--c-primary);
}

.ann__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-3);
}

.ann__title {
  font-size: 15px;
  font-weight: 800;
  overflow-wrap: anywhere;
}

.ann__body {
  font-size: 13px;
  color: var(--c-text-muted);
  white-space: pre-line;
  overflow-wrap: anywhere;
}

.ann__actions,
.ann__confirm {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
}

.ann__confirm span {
  font-size: 13px;
  font-weight: 700;
  margin-right: auto;
}
</style>
