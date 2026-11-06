import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { dummyTimetable, TIMETABLE_IS_DUMMY } from '@/data/items'
import { subjects } from '@/data/subjects'
import { useSchoolDay } from '@/composables/useSchoolDay'
import { toMinutes } from '@/utils/time'

// Single source for Home subject cards and the class timeline.
export const useScheduleStore = defineStore('schedule', () => {
  const now = ref(new Date())
  let timer = null

  function startClock() {
    if (timer) return
    timer = setInterval(() => {
      now.value = new Date()
    }, 30000)
  }

  const { schoolDay, dayTitle, dayRelation } = useSchoolDay(now)

  const entries = computed(() => {
    const weekday = schoolDay.value.weekday
    return (dummyTimetable[weekday] ?? []).map((e, i) => {
      const startMin = toMinutes(e.start)
      const endMin = toMinutes(e.end)
      return {
        ...e,
        id: `${weekday}-${i}`,
        startMin,
        endMin,
        duration: endMin - startMin,
        subject: e.type === 'lesson' ? subjects[e.subject] : null
      }
    })
  })

  const lessons = computed(() => entries.value.filter((e) => e.type === 'lesson'))

  const nowMinutes = computed(
    () => now.value.getHours() * 60 + now.value.getMinutes() + now.value.getSeconds() / 60
  )

  const currentEntryId = computed(() => {
    if (!schoolDay.value.isToday) return null
    const m = nowMinutes.value
    return entries.value.find((e) => m >= e.startMin && m < e.endMin)?.id ?? null
  })

  return {
    now,
    startClock,
    schoolDay,
    dayTitle,
    dayRelation,
    entries,
    lessons,
    nowMinutes,
    currentEntryId,
    isDummy: TIMETABLE_IS_DUMMY
  }
})
