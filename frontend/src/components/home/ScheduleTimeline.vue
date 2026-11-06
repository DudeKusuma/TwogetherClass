<script setup>
import { defineProps } from 'vue'
import { computed, ref, onMounted, watch, nextTick } from 'vue'
import { formatTime, formatRange } from '@/utils/time'

const props = defineProps({
  entries: { type: Array, required: true },
  nowMinutes: { type: Number, required: true },
  isToday: { type: Boolean, default: false },
  currentId: { type: String, default: null }
})

const PPM = 3.6 // pixels per minute
const PAD = 28
const CARD_H = 66
const LANE_GAP = 14
const LANE_TOP = 18
const LANE_PATTERN = [0, 1, 2, 1]
const TRACK_H = LANE_TOP * 2 + CARD_H * 3 + LANE_GAP * 2
const AXIS_H = 40

const scroller = ref(null)

const rangeStart = computed(() =>
  props.entries.length ? Math.floor(Math.min(...props.entries.map((e) => e.startMin)) / 60) * 60 : 420
)
const rangeEnd = computed(() =>
  props.entries.length ? Math.ceil(Math.max(...props.entries.map((e) => e.endMin)) / 60) * 60 : 900
)
const x = (m) => PAD + (m - rangeStart.value) * PPM
const canvasWidth = computed(() => x(rangeEnd.value) + PAD)

const ticks = computed(() => {
  const list = []
  for (let m = rangeStart.value; m <= rangeEnd.value; m += 30) list.push({ m, major: m % 60 === 0, left: x(m) })
  return list
})

const lessons = computed(() =>
  props.entries
    .filter((e) => e.type === 'lesson')
    .map((e, i) => ({
      ...e,
      left: x(e.startMin) + 2,
      width: e.duration * PPM - 4,
      top: LANE_TOP + LANE_PATTERN[i % LANE_PATTERN.length] * (CARD_H + LANE_GAP),
      compact: e.duration * PPM < 220
    }))
)

const breaks = computed(() =>
  props.entries.filter((e) => e.type === 'break').map((e) => ({ ...e, left: x(e.startMin), width: e.duration * PPM }))
)

const showNow = computed(
  () => props.isToday && props.nowMinutes >= rangeStart.value && props.nowMinutes <= rangeEnd.value
)
const nowLeft = computed(() => x(props.nowMinutes))

function scrollToNow() {
  const el = scroller.value
  if (!el) return
  let target = 0
  if (showNow.value) target = nowLeft.value - el.clientWidth * 0.35
  else if (props.isToday && props.nowMinutes > rangeEnd.value) target = el.scrollWidth
  el.scrollTo({ left: Math.max(0, target), behavior: 'smooth' })
}

onMounted(() => nextTick(scrollToNow))
watch([() => props.entries.map((e) => e.id).join(), () => props.currentId], () => nextTick(scrollToNow))
</script>

<template>
  <div class="timeline" data-testid="schedule-timeline">
    <div ref="scroller" class="timeline__scroller" data-testid="timeline-scroller">
      <div class="timeline__canvas" :style="{ width: `${canvasWidth}px`, height: `${TRACK_H + AXIS_H}px` }">
        <span
          v-for="t in ticks"
          :key="`g${t.m}`"
          class="timeline__grid"
          :class="{ 'is-major': t.major }"
          :style="{ left: `${t.left}px`, height: `${TRACK_H}px` }"
        />

        <div
          v-for="b in breaks"
          :key="b.id"
          class="timeline__break"
          :style="{ left: `${b.left}px`, width: `${b.width}px`, height: `${TRACK_H}px` }"
          :title="`${b.label} ${formatRange(b.startMin, b.endMin)}`"
          data-testid="timeline-break"
        >
          <span class="timeline__break-label">{{ b.label }}</span>
        </div>

        <article
          v-for="l in lessons"
          :key="l.id"
          class="tl-card"
          :class="{ 'is-current': l.id === currentId, 'is-past': isToday && nowMinutes >= l.endMin, 'is-compact': l.compact }"
          :title="`${l.subject.name} · ${formatRange(l.startMin, l.endMin)} · ${l.duration} mnt`"
          :style="{ left: `${l.left}px`, width: `${l.width}px`, top: `${l.top}px`, height: `${CARD_H}px` }"
          :data-start="l.start"
          :data-end="l.end"
          data-testid="timeline-card"
        >
          <span class="tl-card__icon"><img :src="l.subject.icon" :alt="`Ikon ${l.subject.name}`" /></span>
          <span class="tl-card__text">
            <strong class="tl-card__title">{{ l.subject.name }}</strong>
            <small class="tl-card__meta">
              <template v-if="!l.compact">{{ formatRange(l.startMin, l.endMin) }} · </template>{{ l.duration }} mnt
            </small>
          </span>
        </article>

        <div
          v-if="showNow"
          class="timeline__now"
          :style="{ left: `${nowLeft}px`, height: `${TRACK_H}px` }"
          data-testid="timeline-now-indicator"
        >
          <span class="timeline__now-label">{{ formatTime(nowMinutes) }}</span>
        </div>

        <div class="timeline__axis" :style="{ top: `${TRACK_H}px` }">
          <span
            v-for="t in ticks"
            :key="`t${t.m}`"
            class="timeline__tick"
            :class="{ 'is-major': t.major }"
            :style="{ left: `${t.left}px` }"
          >
            <i />
            <em>{{ formatTime(t.m) }}</em>
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.timeline {
  background: var(--c-white);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  border: 1px solid rgba(231, 235, 243, 0.7);
  overflow: hidden;
}

.timeline__scroller {
  overflow-x: auto;
  overflow-y: hidden;
  overscroll-behavior-x: contain;
  scrollbar-width: thin;
  -webkit-overflow-scrolling: touch;
}

.timeline__canvas {
  position: relative;
}

.timeline__grid {
  position: absolute;
  top: 0;
  width: 0;
  border-left: 1px dashed #eef1f6;
}

.timeline__grid.is-major {
  border-left: 1px solid #edf0f5;
}

.timeline__break {
  position: absolute;
  top: 0;
  background: repeating-linear-gradient(135deg, #f6f8fc 0 6px, #eef2f8 6px 12px);
  border-radius: 10px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  padding-bottom: 8px;
}

.timeline__break-label {
  writing-mode: vertical-rl;
  transform: rotate(180deg);
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--c-text-soft);
}

.tl-card {
  position: absolute;
  z-index: 2;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 12px 0 8px;
  border-radius: 20px;
  background: var(--c-white);
  border: 1px solid var(--c-border);
  box-shadow: 0 6px 16px rgba(34, 43, 58, 0.07);
  overflow: hidden;
  transition: box-shadow 0.2s ease, transform 0.2s var(--ease);
}

.tl-card:hover {
  transform: translateY(-2px);
}

.tl-card.is-compact {
  gap: 8px;
  padding: 0 10px 0 7px;
}

.tl-card.is-compact .tl-card__icon {
  width: 38px;
  height: 38px;
}

.tl-card.is-compact .tl-card__title {
  font-size: 12px;
  white-space: normal;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.tl-card.is-past {
  opacity: 0.6;
}

.tl-card.is-current {
  z-index: 3;
  background: var(--c-primary);
  border-color: var(--c-primary);
  color: var(--c-white);
  box-shadow: var(--shadow-primary);
  opacity: 1;
}

.tl-card__icon {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: var(--c-gray);
  overflow: hidden;
  flex-shrink: 0;
}

.tl-card.is-current .tl-card__icon {
  background: var(--c-white);
}

.tl-card__icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.tl-card__text {
  display: flex;
  flex-direction: column;
  min-width: 0;
  line-height: 1.25;
}

.tl-card__title {
  font-size: 13px;
  font-weight: 800;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.tl-card__meta {
  font-size: 11px;
  font-weight: 600;
  color: var(--c-text-muted);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.tl-card.is-current .tl-card__meta {
  color: rgba(255, 255, 255, 0.85);
}

.timeline__now {
  position: absolute;
  top: 0;
  z-index: 4;
  width: 0;
  border-left: 2px solid var(--c-danger);
  pointer-events: none;
}

.timeline__now::after {
  content: '';
  position: absolute;
  bottom: -5px;
  left: -6px;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--c-danger);
  border: 2px solid var(--c-white);
}

.timeline__now-label {
  position: absolute;
  top: 2px;
  left: 4px;
  font-size: 10px;
  font-weight: 800;
  color: var(--c-white);
  background: var(--c-danger);
  padding: 1px 6px;
  border-radius: var(--radius-pill);
  white-space: nowrap;
}

.timeline__axis {
  position: absolute;
  left: 0;
  right: 0;
  height: 40px;
  border-top: 1px solid var(--c-border);
}

.timeline__tick {
  position: absolute;
  top: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  transform: translateX(-50%);
}

.timeline__tick i {
  display: block;
  width: 1px;
  height: 5px;
  background: #cfd5e0;
}

.timeline__tick.is-major i {
  height: 8px;
  background: #9aa3b3;
}

.timeline__tick em {
  font-style: normal;
  font-size: 10px;
  font-weight: 600;
  color: var(--c-text-soft);
  margin-top: 3px;
}

.timeline__tick.is-major em {
  font-size: 11px;
  font-weight: 800;
  color: var(--c-text-muted);
}
</style>
