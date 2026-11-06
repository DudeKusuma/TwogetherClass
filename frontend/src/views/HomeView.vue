<script setup>
import { onMounted } from 'vue'
import GreetingSection from '@/components/home/GreetingSection.vue'
import SubjectCardsSection from '@/components/home/SubjectCardsSection.vue'
import ScheduleSection from '@/components/home/ScheduleSection.vue'
import { useScheduleStore } from '@/stores/useScheduleStore'

const schedule = useScheduleStore()
onMounted(() => schedule.startClock())
</script>

<template>
  <div class="home" data-testid="home-page">
    <GreetingSection />
    <SubjectCardsSection />
    <ScheduleSection />
  </div>
</template>

<style scoped>
.home {
  display: flex;
  flex-direction: column;
  gap: var(--space-7);
  min-width: 0;
}
</style>
