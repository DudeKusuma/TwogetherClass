<script setup>
import { defineProps, defineEmits } from 'vue'
import { computed } from 'vue'
import { Clock } from 'lucide-vue-next'
import { formatRange } from '@/utils/time'
import { activityLabel } from '@/stores/useSubjectStore'

// Subject card for the Home page (course "ItemCard" adapted to Twogether Class).
const props = defineProps({
  lesson: { type: Object, required: true },
  current: { type: Boolean, default: false },
  activities: { type: Array, default: () => [] },
  classTasks: { type: Array, default: () => [] }
})
const emit = defineEmits(['open'])

const status = computed(() => {
  const taskCount = props.classTasks.length + props.activities.filter((a) => a.type === 'tugas').length
  const otherCounts = {}
  props.activities.filter((a) => a.type !== 'tugas').forEach((a) => (otherCounts[a.type] = (otherCounts[a.type] ?? 0) + 1))
  const labels = []
  if (taskCount) labels.push(`${taskCount} tugas`)
  labels.push(...Object.entries(otherCounts).map(([type, n]) => `${n} ${activityLabel(type)}`))
  return labels.join(' · ') || props.lesson.assignment || 'Tidak ada tugas'
})
const hasTask = computed(() => props.activities.length > 0 || props.classTasks.length > 0 || Boolean(props.lesson.assignment))
</script>

<template>
  <button
    type="button"
    class="subject-card"
    :class="{ 'is-current': current }"
    :style="{ '--accent': lesson.subject.accent }"
    :aria-label="`Lihat detail ${lesson.subject.name}`"
    data-testid="subject-card"
    :data-subject="lesson.subject.key"
    @click="emit('open', lesson)"
  >
    <span class="subject-card__header">
      <span class="subject-card__icon">
        <img :src="lesson.subject.icon" :alt="`Ikon ${lesson.subject.name}`" loading="lazy" />
      </span>
      <span v-if="current" class="subject-card__now" data-testid="subject-card-current-badge">Sekarang</span>
    </span>
    <span class="subject-card__body">
      <span class="subject-card__name" data-testid="subject-card-name">{{ lesson.subject.name }}</span>
      <span class="subject-card__time">
        <Clock :size="13" :stroke-width="2.2" />
        <span data-testid="subject-card-time"><span class="nw">{{ formatRange(lesson.startMin, lesson.endMin) }}</span> <span class="nw">· {{ lesson.duration }} mnt</span></span>
      </span>
      <span v-if="lesson.teacher" class="subject-card__teacher" data-testid="subject-card-teacher">{{ lesson.teacher }}</span>
      <span class="subject-card__footer">
        <span class="subject-card__status" :class="{ 'has-task': hasTask }" data-testid="subject-card-status">{{ status }}</span>
      </span>
    </span>
  </button>
</template>

<style scoped>
.subject-card {
  display: flex;
  flex-direction: column;
  width: 100%;
  min-width: 0;
  padding: 0;
  text-align: left;
  border-radius: var(--radius-lg);
  background: var(--c-white);
  border: 1px solid var(--c-border);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
  transition: transform 0.2s var(--ease), box-shadow 0.2s ease;
}

.subject-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.subject-card.is-current {
  border-color: var(--c-primary);
  box-shadow: 0 0 0 1px var(--c-primary), var(--shadow-md);
}

.subject-card__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: var(--space-3) var(--space-3) 0 var(--space-4);
  height: 68px;
  background: var(--accent);
}

.subject-card__icon {
  width: 52px;
  height: 52px;
  margin-top: 4px;
  border-radius: 16px;
  background: var(--c-white);
  overflow: hidden;
  flex-shrink: 0;
  box-shadow: var(--shadow-sm);
}

.subject-card__body {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
  padding: var(--space-4) var(--space-4) var(--space-4);
}

.subject-card__footer {
  margin-top: auto;
  padding-top: var(--space-3);
  border-top: 1px solid var(--c-gray);
}

.subject-card__icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.subject-card__now {
  font-size: 11px;
  font-weight: 800;
  color: var(--c-white);
  background: var(--c-primary);
  padding: 3px 9px;
  border-radius: var(--radius-pill);
}

.subject-card__name {
  display: block;
  font-size: 15px;
  font-weight: 800;
  line-height: 1.25;
  overflow-wrap: anywhere;
}

.subject-card__time {
  display: flex;
  align-items: flex-start;
  gap: 5px;
  font-size: 12px;
  font-weight: 600;
  color: var(--c-text-muted);
}

.subject-card__time svg {
  margin-top: 2px;
  flex-shrink: 0;
}

.nw {
  white-space: nowrap;
}

.subject-card__teacher {
  font-size: 12px;
  color: var(--c-text-muted);
}

.subject-card__status {
  display: inline-block;
  font-size: 11px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: var(--radius-pill);
  background: var(--c-gray);
  color: var(--c-text-muted);
}

.subject-card__status.has-task {
  background: var(--c-blue-soft);
  color: var(--c-primary);
}
</style>
