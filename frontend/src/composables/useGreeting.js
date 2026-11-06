import { computed } from 'vue'

export function greetingFor(hour) {
  if (hour >= 4 && hour < 11) return 'Selamat pagi'
  if (hour >= 11 && hour < 15) return 'Selamat siang'
  if (hour >= 15 && hour < 18) return 'Selamat sore'
  return 'Selamat malam'
}

const dateFormatter = new Intl.DateTimeFormat('id-ID', {
  weekday: 'long',
  day: 'numeric',
  month: 'long',
  year: 'numeric'
})

export function useGreeting(nowRef) {
  const greeting = computed(() => greetingFor(nowRef.value.getHours()))
  const todayLabel = computed(() => dateFormatter.format(nowRef.value))
  return { greeting, todayLabel }
}
