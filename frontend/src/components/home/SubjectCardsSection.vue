<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { CalendarX } from 'lucide-vue-next'
import ItemCard from '@/components/shared/ItemCard.vue'
import EmptyState from '@/components/shared/EmptyState.vue'
import SubjectDetailModal from './SubjectDetailModal.vue'
import { useScheduleStore } from '@/stores/useScheduleStore'
import { useSubjectStore } from '@/stores/useSubjectStore'

const schedule = useScheduleStore()
const subjectStore = useSubjectStore()
const selected = ref(null)
const classTasks = ref([])
onMounted(async () => { if (supabase) { const { data } = await supabase.from('class_tasks').select('id,subject_key,title,deadline'); classTasks.value = data || [] } })
</script>

<template>
  <section class="subjects" data-testid="home-subjects-section">
    <header class="section-head">
      <div>
        <h2 class="section-head__title">Mata Pelajaran</h2>
        <p class="section-head__meta" data-testid="subjects-day-label">{{ schedule.dayRelation }} · {{ schedule.dayTitle }}</p>
      </div>
      <span v-if="schedule.isDummy" class="chip chip--yellow" data-testid="subjects-dummy-label">Data contoh</span>
    </header>

    <div v-if="schedule.lessons.length" class="subjects__grid">
      <ItemCard
        v-for="lesson in schedule.lessons"
        :key="lesson.id"
        :lesson="lesson"
        :current="lesson.id === schedule.currentEntryId"
        :activities="subjectStore.upcomingFor(lesson.subject.key)"
        :class-tasks="classTasks.filter(t => t.subject_key === lesson.subject.key)"
        @open="selected = $event"
      />
    </div>
    <EmptyState v-else :icon="CalendarX" title="Tidak ada pelajaran" description="Belum ada data jadwal untuk hari ini." />
    <SubjectDetailModal :lesson="selected" :day-label="schedule.dayTitle" :class-tasks="classTasks.filter(t => t.subject_key === selected?.subject?.key)" @close="selected = null" />
  </section>
</template>

<style scoped>
.subjects__grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-3);
}

@media (min-width: 640px) {
  .subjects__grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: var(--space-4);
  }
}

@media (min-width: 1024px) {
  .subjects__grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}
</style>
