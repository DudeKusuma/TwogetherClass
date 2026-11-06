import { computed } from 'vue'

export const ROLLOVER_HOUR = 16

function startOfDay(date) {
  const d = new Date(date)
  d.setHours(0, 0, 0, 0)
  return d
}

function addDays(date, n) {
  const d = new Date(date)
  d.setDate(d.getDate() + n)
  return d
}

// Before 16:00 → today; at/after 16:00 → next day; Sunday is always skipped to Monday.
export function resolveSchoolDay(now) {
  let target = startOfDay(now)
  if (now.getHours() >= ROLLOVER_HOUR) target = addDays(target, 1)
  if (target.getDay() === 0) target = addDays(target, 1)
  const diffDays = Math.round((target - startOfDay(now)) / 86400000)
  return { date: target, weekday: target.getDay(), isToday: diffDays === 0, diffDays }
}

// The school day after today (Sunday skipped), used for Admin "Jadwal Besok" defaults.
export function nextSchoolDay(now) {
  let target = addDays(startOfDay(now), 1)
  if (target.getDay() === 0) target = addDays(target, 1)
  return target
}

const dayFormatter = new Intl.DateTimeFormat('id-ID', { weekday: 'long', day: 'numeric', month: 'long' })

export function useSchoolDay(nowRef) {
  const schoolDay = computed(() => resolveSchoolDay(nowRef.value))
  const dayTitle = computed(() => dayFormatter.format(schoolDay.value.date))
  const dayRelation = computed(() => {
    const d = schoolDay.value.diffDays
    if (d === 0) return 'Hari ini'
    if (d === 1) return 'Besok'
    return 'Hari sekolah berikutnya'
  })
  return { schoolDay, dayTitle, dayRelation }
}
