<script setup>
import { computed, ref, watch } from 'vue'
import { Check, Save } from 'lucide-vue-next'
import BaseButton from '@/components/base/BaseButton.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import AdminBackLink from '@/components/admin/AdminBackLink.vue'
import { subjects } from '@/data/subjects'
import { useSubjectStore } from '@/stores/useSubjectStore'

const store = useSubjectStore()
const subjectList = Object.values(subjects)
const selectedKey = ref(subjectList[0].key)
const draft = ref('')
const saved = ref(false)

const selected = computed(() => subjects[selectedKey.value])

watch(
  selectedKey,
  (key) => {
    draft.value = store.descriptions[key] ?? ''
    saved.value = false
  },
  { immediate: true }
)

async function save() {
  const result = await store.setDescription(selectedKey.value, draft.value)
  if (result) return
  draft.value = store.descriptions[selectedKey.value] ?? ''
  saved.value = true
}
</script>

<template>
  <div class="desc" data-testid="admin-descriptions-page">
    <AdminBackLink />
    <header class="page-head">
      <span class="page-head__eyebrow">Admin Power</span>
      <h1 class="page-head__title">Deskripsi Mata Pelajaran</h1>
      <p class="page-head__desc">Pilih mata pelajaran, lalu tulis deskripsinya. Siswa melihat deskripsi ini saat membuka kartu mata pelajaran.</p>
    </header>

    <div class="desc__grid">
      <div class="desc__subjects" role="listbox" aria-label="Pilih mata pelajaran" data-testid="description-subject-list">
        <button
          v-for="s in subjectList"
          :key="s.key"
          type="button"
          class="subj"
          :class="{ 'is-on': s.key === selectedKey }"
          :aria-selected="s.key === selectedKey"
          :data-testid="`description-subject-${s.key}`"
          @click="selectedKey = s.key"
        >
          <span class="subj__icon"><img :src="s.icon" :alt="''" /></span>
          <span class="subj__name">{{ s.name }}</span>
          <Check v-if="store.descriptions[s.key]" :size="16" class="subj__check" />
        </button>
      </div>

      <BaseCard tag="form" class="desc__editor" novalidate data-testid="description-form" @submit.prevent="save">
        <div class="desc__head" :style="{ background: selected.accent }">
          <span class="desc__icon"><img :src="selected.icon" :alt="`Ikon ${selected.name}`" /></span>
          <h2 class="desc__name" data-testid="description-selected-name">{{ selected.name }}</h2>
        </div>
        <label class="form-field">
          <span class="form-label">Deskripsi</span>
          <textarea
            v-model="draft"
            class="form-input form-textarea"
            rows="7"
            placeholder="Tulis deskripsi mata pelajaran"
            data-testid="description-textarea"
            @input="saved = false"
          />
        </label>
        <p v-if="saved" class="form-success" role="status" data-testid="description-saved-message">Deskripsi tersimpan.</p>
        <div>
          <BaseButton type="submit" data-testid="description-save-button"><Save :size="17" /> Simpan deskripsi</BaseButton>
        </div>
      </BaseCard>
    </div>
  </div>
</template>

<style scoped>
.desc__grid {
  display: grid;
  gap: var(--space-5);
}

@media (min-width: 1024px) {
  .desc__grid {
    grid-template-columns: minmax(0, 5fr) minmax(0, 7fr);
    align-items: start;
  }
}

.desc__subjects {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
}

@media (min-width: 640px) {
  .desc__subjects {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (min-width: 1024px) {
  .desc__subjects {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

.subj {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px 8px 8px;
  border-radius: var(--radius-md);
  border: 1px solid var(--c-border);
  background: var(--c-white);
  text-align: left;
  min-width: 0;
  transition: border-color 0.18s ease, background-color 0.18s ease;
}

.subj.is-on {
  border-color: var(--c-primary);
  background: var(--c-blue-soft);
}

.subj__icon {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  background: var(--c-white);
  overflow: hidden;
  flex-shrink: 0;
}

.subj__icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.subj__name {
  flex: 1;
  min-width: 0;
  font-size: 13px;
  font-weight: 700;
  overflow-wrap: anywhere;
}

.subj__check {
  color: #1f8a56;
  flex-shrink: 0;
}

.desc__editor {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  overflow: hidden;
}

.desc__head {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin: calc(var(--space-5) * -1) calc(var(--space-5) * -1) 0;
  padding: var(--space-4) var(--space-5);
}

.desc__icon {
  width: 52px;
  height: 52px;
  border-radius: 16px;
  background: var(--c-white);
  overflow: hidden;
  flex-shrink: 0;
}

.desc__icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.desc__name {
  font-size: 18px;
  font-weight: 800;
}
</style>
