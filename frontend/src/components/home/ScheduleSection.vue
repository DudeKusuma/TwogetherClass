<script setup>
import ScheduleTimeline from './ScheduleTimeline.vue'
import { useScheduleStore } from '@/stores/useScheduleStore'

const schedule = useScheduleStore()
</script>

<template>
  <section class="schedule" data-testid="home-schedule-section">
    <header class="section-head">
      <div>
        <h2 class="section-head__title">Jadwal Kelas</h2>
        <p class="section-head__meta" data-testid="schedule-day-label">{{ schedule.dayRelation }} · {{ schedule.dayTitle }}</p>
      </div>
      <span v-if="schedule.isDummy" class="chip chip--yellow" data-testid="schedule-dummy-label">Data contoh</span>
    </header>

    <ScheduleTimeline
      :entries="schedule.entries"
      :now-minutes="schedule.nowMinutes"
      :is-today="schedule.schoolDay.isToday"
      :current-id="schedule.currentEntryId"
    />

    <p v-if="schedule.isDummy" class="schedule__note" data-testid="schedule-dummy-note">
      Jadwal ini masih data contoh untuk uji tampilan, bukan jadwal resmi XI-B2.
    </p>
  </section>
</template>

<style scoped>
.schedule {
  min-width: 0;
}

.schedule__note {
  margin-top: var(--space-3);
  font-size: 12px;
  color: var(--c-text-soft);
}
</style>
