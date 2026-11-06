import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { subjects } from '@/data/subjects'
import { toISODate } from '@/utils/time'

export const ACTIVITY_TYPES = [
  { value: 'tugas', label: 'Tugas' }, { value: 'kuis', label: 'Kuis' },
  { value: 'ulangan', label: 'Ulangan' }, { value: 'lainnya', label: 'Lainnya' }
]
export const activityLabel = (value) => ACTIVITY_TYPES.find((t) => t.value === value)?.label ?? value
const norm = (s) => s.trim().toLowerCase().replace(/\s+/g, ' ')

export const useSubjectStore = defineStore('subjects', () => {
  const descriptions = ref({})
  const activities = ref([])
  const loading = ref(false)
  const error = ref('')
  async function load() {
    if (!supabase) return
    loading.value = true; error.value = ''
    const [descResult, activityResult] = await Promise.all([
      supabase.from('subject_descriptions').select('*'),
      supabase.from('subject_activities').select('*').order('date', { ascending: true, nullsFirst: false })
    ])
    if (descResult.error) error.value = descResult.error.message
    else descriptions.value = Object.fromEntries((descResult.data || []).map((r) => [r.subject_key, r.description]))
    if (activityResult.error) error.value = activityResult.error.message
    else activities.value = (activityResult.data || []).map((r) => ({ id: r.id, subject: r.subject, type: r.type, title: r.title, notes: r.notes, date: r.date || '', createdAt: r.created_at, updatedAt: r.updated_at }))
    loading.value = false
  }
  async function setDescription(key, text) {
    const value = text.trim()
    const result = value
      ? await supabase.from('subject_descriptions').upsert({ subject_key: key, description: value, updated_at: new Date().toISOString() }, { onConflict: 'subject_key' })
      : await supabase.from('subject_descriptions').delete().eq('subject_key', key)
    if (result.error) { error.value = result.error.message; return result.error.message }
    const next = { ...descriptions.value }
    if (value) next[key] = value; else delete next[key]
    descriptions.value = next
    return null
  }
  const sortedActivities = () => [...activities.value].sort((a, b) => (a.date || '9999').localeCompare(b.date || '9999') || a.createdAt.localeCompare(b.createdAt))
  function upcomingFor(key) { const today = toISODate(new Date()); return sortedActivities().filter((a) => a.subject === key && (!a.date || a.date >= today)) }
  function validate(entry, ignoreId = null) {
    if (!subjects[entry.subject] || !ACTIVITY_TYPES.some((t) => t.value === entry.type) || !entry.title.trim()) return 'Mata pelajaran, jenis aktivitas, dan judul wajib diisi.'
    const dup = activities.value.some((a) => a.id !== ignoreId && a.subject === entry.subject && a.type === entry.type && norm(a.title) === norm(entry.title) && (a.date || '') === (entry.date || ''))
    return dup ? 'Aktivitas yang sama sudah ada untuk mata pelajaran dan tanggal ini.' : null
  }
  const clean = (e) => ({ subject: e.subject, type: e.type, title: e.title.trim(), notes: e.notes.trim(), date: e.date || null })
  async function addActivity(entry) {
    const invalid = validate(entry); if (invalid) return invalid
    const { data, error: insertError } = await supabase.from('subject_activities').insert(clean(entry)).select().single()
    if (insertError) return (error.value = insertError.message)
    activities.value.push({ ...clean(entry), date: data.date || '', id: data.id, createdAt: data.created_at, updatedAt: data.updated_at }); return null
  }
  async function updateActivity(id, entry) {
    const invalid = validate(entry, id); if (invalid) return invalid
    const { data, error: updateError } = await supabase.from('subject_activities').update({ ...clean(entry), updated_at: new Date().toISOString() }).eq('id', id).select().single()
    if (updateError) return (error.value = updateError.message)
    const i = activities.value.findIndex((a) => a.id === id)
    if (i >= 0) activities.value[i] = { ...clean(entry), date: data.date || '', id: data.id, createdAt: data.created_at, updatedAt: data.updated_at }
    return null
  }
  async function removeActivity(id) {
    const { error: deleteError } = await supabase.from('subject_activities').delete().eq('id', id)
    if (deleteError) { error.value = deleteError.message; return deleteError.message }
    activities.value = activities.value.filter((a) => a.id !== id); return null
  }
  return { descriptions, activities, loading, error, load, sortedActivities, setDescription, upcomingFor, addActivity, updateActivity, removeActivity }
})
