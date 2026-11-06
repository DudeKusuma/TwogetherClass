<script setup>
import { defineProps, defineEmits } from 'vue'
import { computed, watch, onBeforeUnmount } from 'vue'
import { X, Clock, CalendarDays } from 'lucide-vue-next'
import { formatRange } from '@/utils/time'
import { useSubjectStore, activityLabel } from '@/stores/useSubjectStore'

const props = defineProps({
  lesson: { type: Object, default: null },
  dayLabel: { type: String, default: '' },
  classTasks: { type: Array, default: () => [] }
})
const emit = defineEmits(['close'])
const store = useSubjectStore()

const subject = computed(() => props.lesson?.subject ?? null)
const description = computed(() => (subject.value ? store.descriptions[subject.value.key] ?? '' : ''))
const activities = computed(() => (subject.value ? store.upcomingFor(subject.value.key) : []))
const taskActivities = computed(() => activities.value.filter((a) => a.type === 'tugas'))
const otherActivities = computed(() => activities.value.filter((a) => a.type !== 'tugas'))
const dateFmt = new Intl.DateTimeFormat('id-ID', { weekday: 'long', day: 'numeric', month: 'long' })
const formatDate = (iso) => dateFmt.format(new Date(`${iso}T00:00:00`))

function onKey(e) {
  if (e.key === 'Escape') emit('close')
}
watch(
  () => Boolean(props.lesson),
  (open) => {
    document.body.style.overflow = open ? 'hidden' : ''
    if (open) document.addEventListener('keydown', onKey)
    else document.removeEventListener('keydown', onKey)
  }
)
onBeforeUnmount(() => {
  document.body.style.overflow = ''
  document.removeEventListener('keydown', onKey)
})
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="lesson" class="overlay" data-testid="subject-detail-overlay" @click.self="emit('close')">
        <div class="modal" role="dialog" aria-modal="true" :aria-label="`Detail ${subject.name}`" data-testid="subject-detail-modal">
          <div class="modal__header" :style="{ background: subject.accent }">
            <span class="modal__icon"><img :src="subject.icon" :alt="`Ikon ${subject.name}`" /></span>
            <button type="button" class="modal__close" aria-label="Tutup" data-testid="subject-detail-close" @click="emit('close')">
              <X :size="18" />
            </button>
          </div>

          <div class="modal__body">
            <h2 class="modal__title" data-testid="subject-detail-name">{{ subject.name }}</h2>
            <p class="modal__meta" data-testid="subject-detail-time">
              <Clock :size="14" /> {{ dayLabel }} · {{ formatRange(lesson.startMin, lesson.endMin) }} · {{ lesson.duration }} menit
            </p>
            <p v-if="lesson.teacher" class="modal__meta">{{ lesson.teacher }}</p>

            <section class="modal__section">
              <h3 class="modal__section-title">Deskripsi</h3>
              <p v-if="description" class="modal__desc" data-testid="subject-detail-description">{{ description }}</p>
              <p v-else class="modal__muted" data-testid="subject-detail-description-empty">Belum ada deskripsi dari admin kelas.</p>
            </section>

            <section class="modal__section">
              <h3 class="modal__section-title">Tugas kelas</h3>
              <ul v-if="classTasks.length || taskActivities.length" class="acts"><li v-for="task in classTasks" :key="task.id" class="act"><h4 class="act__title">{{task.title}}</h4><p v-if="task.description" class="act__notes">{{task.description}}</p><span class="act__date">{{task.deadline ? `Deadline · ${formatDate(task.deadline)}` : `Diberikan · ${formatDate(task.assigned_date)}`}}</span></li><li v-for="task in taskActivities" :key="`activity-${task.id}`" class="act"><h4 class="act__title">{{task.title}}</h4><p v-if="task.notes" class="act__notes">{{task.notes}}</p><span v-if="task.date" class="act__date">Deadline · {{formatDate(task.date)}}</span></li></ul><p v-else class="modal__muted">Tidak ada tugas kelas.</p>
            </section>

            <section class="modal__section">
              <h3 class="modal__section-title">Tugas, kuis & ulangan</h3>
              <ul v-if="otherActivities.length" class="acts">
                <li v-for="a in otherActivities" :key="a.id" class="act" data-testid="subject-detail-activity">
                  <div class="act__head">
                    <span class="act__type" :class="`act__type--${a.type}`" data-testid="subject-detail-activity-type">{{ activityLabel(a.type) }}</span>
                    <span v-if="a.date" class="act__date"><CalendarDays :size="13" /> {{ formatDate(a.date) }}</span>
                  </div>
                  <h4 class="act__title" data-testid="subject-detail-activity-title">{{ a.title }}</h4>
                  <p v-if="a.notes" class="act__notes">{{ a.notes }}</p>
                </li>
              </ul>
              <p v-else class="modal__muted" data-testid="subject-detail-no-activity">Tidak ada tugas</p>
            </section>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: rgba(34, 43, 58, 0.4);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  padding: var(--space-3);
}

@media (min-width: 640px) {
  .overlay {
    align-items: center;
  }
}

.modal {
  width: 100%;
  max-width: 480px;
  max-height: calc(100vh - 24px);
  max-height: calc(100dvh - 24px);
  overflow-y: auto;
  background: var(--c-white);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-lg);
}

.modal__header {
  position: relative;
  height: 96px;
  padding: var(--space-4) var(--space-5) 0;
}

.modal__icon {
  position: absolute;
  left: var(--space-5);
  bottom: -36px;
  width: 84px;
  height: 84px;
  border-radius: 24px;
  background: var(--c-white);
  box-shadow: var(--shadow-md);
  overflow: hidden;
}

.modal__icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.modal__close {
  position: absolute;
  top: var(--space-3);
  right: var(--space-3);
  width: 36px;
  height: 36px;
  display: grid;
  place-items: center;
  border: none;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.85);
}

.modal__body {
  padding: 52px var(--space-5) var(--space-5);
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.modal__title {
  font-size: 22px;
  font-weight: 800;
  letter-spacing: -0.01em;
}

.modal__meta {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  color: var(--c-text-muted);
}

.modal__section {
  margin-top: var(--space-4);
  padding-top: var(--space-4);
  border-top: 1px solid var(--c-gray);
}

.modal__section-title {
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--c-text-muted);
  margin-bottom: var(--space-2);
}

.modal__desc {
  font-size: 14px;
  white-space: pre-line;
  overflow-wrap: anywhere;
}

.modal__muted {
  font-size: 13px;
  color: var(--c-text-soft);
}

.acts {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.act {
  padding: var(--space-3);
  border-radius: var(--radius-md);
  border: 1px solid var(--c-border);
}

.act__head {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 6px;
  margin-bottom: 4px;
}

.act__type {
  font-size: 11px;
  font-weight: 800;
  padding: 3px 9px;
  border-radius: var(--radius-pill);
  background: var(--c-blue-soft);
  color: var(--c-primary);
}

.act__type--kuis { background: var(--c-yellow); color: #8a6a12; }
.act__type--ulangan { background: var(--c-pink); color: #c23d52; }
.act__type--lainnya { background: var(--c-lavender); color: #6a4fd6; }

.act__date {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 600;
  color: var(--c-text-muted);
}

.act__title {
  font-size: 14px;
  font-weight: 800;
  margin: 0;
  overflow-wrap: anywhere;
}

.act__notes {
  font-size: 13px;
  color: var(--c-text-muted);
  white-space: pre-line;
  overflow-wrap: anywhere;
}
</style>
