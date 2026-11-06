import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import { supabase } from '@/lib/supabase'

const DISMISSED_KEY = 'tc_dismissed_announcements'
function readDismissed() {
  try { return JSON.parse(sessionStorage.getItem(DISMISSED_KEY) || '[]') } catch { return [] }
}

export const useAnnouncementStore = defineStore('announcements', () => {
  const items = ref([])
  const dismissedIds = ref(readDismissed())
  const loading = ref(false)
  const error = ref('')
  watch(dismissedIds, (v) => sessionStorage.setItem(DISMISSED_KEY, JSON.stringify(v)), { deep: true })
  const sorted = computed(() => [...items.value].sort((a, b) => b.createdAt.localeCompare(a.createdAt)))
  const active = computed(() => sorted.value.filter((a) => a.active))
  const undismissed = computed(() => active.value.filter((a) => !dismissedIds.value.includes(a.id)))
  const mapRow = (row) => ({ id: row.id, title: row.title, body: row.body, active: row.active, createdAt: row.created_at, updatedAt: row.updated_at })

  async function load() {
    if (!supabase) return
    loading.value = true; error.value = ''
    const { data, error: queryError } = await supabase.from('announcements').select('*').order('created_at', { ascending: false })
    if (queryError) error.value = queryError.message
    else items.value = (data || []).map(mapRow)
    loading.value = false
  }
  async function create({ title, body, active: isActive }) {
    const { data, error: insertError } = await supabase.from('announcements').insert({ title: title.trim(), body: body.trim(), active: isActive }).select().single()
    if (insertError) { error.value = insertError.message; return insertError.message }
    items.value.unshift(mapRow(data)); return null
  }
  async function update(id, patch) {
    const { data, error: updateError } = await supabase.from('announcements').update({ title: patch.title, body: patch.body, active: patch.active, updated_at: new Date().toISOString() }).eq('id', id).select().single()
    if (updateError) { error.value = updateError.message; return updateError.message }
    const index = items.value.findIndex((a) => a.id === id)
    if (index >= 0) items.value[index] = mapRow(data)
    return null
  }
  async function toggleActive(id) {
    const item = items.value.find((a) => a.id === id)
    if (item) return update(id, { ...item, active: !item.active })
  }
  async function remove(id) {
    const { error: deleteError } = await supabase.from('announcements').delete().eq('id', id)
    if (deleteError) { error.value = deleteError.message; return deleteError.message }
    items.value = items.value.filter((a) => a.id !== id)
    dismissedIds.value = dismissedIds.value.filter((d) => d !== id)
    return null
  }
  function dismiss(id) { if (!dismissedIds.value.includes(id)) dismissedIds.value.push(id) }
  function clearDismissed() { dismissedIds.value = []; sessionStorage.removeItem(DISMISSED_KEY) }
  return { items, sorted, active, undismissed, dismissedIds, loading, error, load, create, update, toggleActive, remove, dismiss, clearDismissed }
})
