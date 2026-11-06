<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  CalendarDays, ChevronLeft, ChevronRight, Plus, X, MapPin, Clock,
  ThumbsUp, ThumbsDown, TrendingUp, Check, Trash2, Pencil,
  ClipboardList, LoaderCircle, Smile
} from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/useAuthStore'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()
const today = new Date()
const monthCursor = ref(new Date(today.getFullYear(), today.getMonth(), 1))
const events = ref([])
const markers = ref([])
const reactions = ref([])
const myRequests = ref([])
const pendingRequests = ref([])
const adminHistory = ref([])
const loading = ref(true)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const selectedDate = ref(toDateKey(today))
const selectedEvent = ref(null)
const showForm = ref(false)
const showRequests = ref(false)
const editingEvent = ref(null)
const form = ref(emptyForm())
const rejectionReasons = ref({})
const emojiChoices = ['📚', '⭐', '❤️', '🎯', '🎉', '📝', '☕', '🌱', '🔥', '✨', '🏆', '🎨']

function toDateKey(date) {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}
function emptyForm() {
  return { title: '', event_date: selectedDate.value || toDateKey(today), start_time: '', end_time: '', location: '', description: '' }
}
function formatMonth(date) {
  return new Intl.DateTimeFormat('id-ID', { month: 'long', year: 'numeric' }).format(date)
}
function formatLongDate(key) {
  return new Intl.DateTimeFormat('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(`${key}T00:00:00`))
}
function formatTime(value) {
  return value ? value.slice(0, 5) : ''
}
function displayName(id) {
  const request = [...myRequests.value, ...pendingRequests.value].find(item => item.requester_id === id)
  return request?.requester?.display_name || (id === auth.user?.id ? auth.user?.displayName : 'Anggota kelas')
}

const monthDays = computed(() => {
  const first = new Date(monthCursor.value.getFullYear(), monthCursor.value.getMonth(), 1)
  const offset = first.getDay()
  const count = new Date(monthCursor.value.getFullYear(), monthCursor.value.getMonth() + 1, 0).getDate()
  const previousCount = new Date(monthCursor.value.getFullYear(), monthCursor.value.getMonth(), 0).getDate()
  const cells = []
  for (let i = 0; i < 42; i++) {
    let date, inMonth = true
    if (i < offset) { date = new Date(first.getFullYear(), first.getMonth() - 1, previousCount - offset + i + 1); inMonth = false }
    else if (i >= offset + count) { date = new Date(first.getFullYear(), first.getMonth() + 1, i - offset - count + 1); inMonth = false }
    else date = new Date(first.getFullYear(), first.getMonth(), i - offset + 1)
    const key = toDateKey(date)
    cells.push({ key, day: date.getDate(), inMonth, events: events.value.filter(event => event.event_date === key), marker: markers.value.find(marker => marker.marker_date === key)?.emoji })
  }
  return cells
})
const selectedEvents = computed(() => events.value.filter(event => event.event_date === selectedDate.value).sort((a, b) => (a.start_time || '').localeCompare(b.start_time || '')))
const selectedMarker = computed(() => markers.value.find(marker => marker.marker_date === selectedDate.value)?.emoji || '')
const selectedReaction = (eventId) => reactions.value.find(item => item.event_id === eventId && item.user_id === auth.user?.id)?.reaction
const countsFor = (eventId) => {
  const votes = reactions.value.filter(item => item.event_id === eventId)
  const likes = votes.filter(item => item.reaction === 'like').length
  const dislikes = votes.filter(item => item.reaction === 'dislike').length
  const total = likes + dislikes
  return { likes, dislikes, total, ratio: total ? likes / total * 100 : 0, popular: likes >= 6 && total > 0 && likes / total >= 0.6 }
}
const calendarTitle = computed(() => formatMonth(monthCursor.value))

async function loadCalendar() {
  if (!supabase) { errorMessage.value = 'Koneksi Supabase belum tersedia.'; loading.value = false; return }
  loading.value = true
  errorMessage.value = ''
  const start = toDateKey(new Date(monthCursor.value.getFullYear(), monthCursor.value.getMonth(), 1))
  const end = toDateKey(new Date(monthCursor.value.getFullYear(), monthCursor.value.getMonth() + 1, 0))
  const [eventResult, markerResult, requestResult] = await Promise.all([
    supabase.from('calendar_events').select('*, creator:profiles!calendar_events_created_by_fkey(display_name)').gte('event_date', start).lte('event_date', end).order('event_date').order('start_time'),
    supabase.from('personal_calendar_markers').select('*').gte('marker_date', start).lte('marker_date', end),
    supabase.from('calendar_requests').select('id, request_type, status, rejection_reason, created_at, event_id, payload').eq('requester_id', auth.user.id).order('created_at', { ascending: false }).limit(30)
  ])
  if (eventResult.error) errorMessage.value = eventResult.error.message
  events.value = eventResult.data || []
  markers.value = markerResult.data || []
  myRequests.value = requestResult.data || []
  if (events.value.length) {
    const { data, error } = await supabase.from('calendar_reactions').select('*').in('event_id', events.value.map(e => e.id))
    if (!error) reactions.value = data || []
  } else reactions.value = []
  if (auth.isAdmin) { await loadPendingRequests(); await loadAdminHistory() }
  loading.value = false
}

async function loadAdminHistory() {
  const { data, error } = await supabase.from('calendar_requests')
    .select('*, requester:profiles!calendar_requests_requester_id_fkey(display_name), reviewer:profiles!calendar_requests_reviewed_by_fkey(display_name)')
    .neq('status', 'pending').order('reviewed_at', { ascending: false }).limit(30)
  if (error) { errorMessage.value = error.message; return }
  adminHistory.value = data || []
}

async function loadPendingRequests() {
  const { data, error } = await supabase.from('calendar_requests')
    .select('*, requester:profiles!calendar_requests_requester_id_fkey(display_name)')
    .eq('status', 'pending').order('created_at', { ascending: true })
  if (error) { errorMessage.value = error.message; return }
  pendingRequests.value = data || []
}

function changeMonth(amount) {
  monthCursor.value = new Date(monthCursor.value.getFullYear(), monthCursor.value.getMonth() + amount, 1)
  loadCalendar()
}
function openNewForm() {
  editingEvent.value = null
  form.value = { ...emptyForm(), event_date: selectedDate.value }
  showForm.value = true
}
function openEditForm(event) {
  editingEvent.value = event
  form.value = { title: event.title, event_date: event.event_date, start_time: formatTime(event.start_time), end_time: formatTime(event.end_time), location: event.location || '', description: event.description || '' }
  selectedEvent.value = null
  showForm.value = true
}
async function submitEvent() {
  if (!form.value.title.trim() || !form.value.event_date || !form.value.start_time) return
  saving.value = true
  errorMessage.value = ''
  const payload = { ...form.value, title: form.value.title.trim(), description: form.value.description.trim(), location: form.value.location.trim() }
  const { error } = await supabase.from('calendar_requests').insert({
    requester_id: auth.user.id,
    event_id: editingEvent.value?.id || null,
    request_type: editingEvent.value ? 'edit' : 'add',
    payload,
    status: 'pending'
  })
  saving.value = false
  if (error) { errorMessage.value = error.message; return }
  showForm.value = false
  successMessage.value = editingEvent.value ? 'Pengajuan perubahan dikirim ke admin.' : 'Kegiatan dikirim untuk persetujuan admin.'
  await loadCalendar()
}
async function requestDelete(event) {
  if (!window.confirm(`Ajukan penghapusan kegiatan “${event.title}”?`)) return
  const { error } = await supabase.from('calendar_requests').insert({ requester_id: auth.user.id, event_id: event.id, request_type: 'delete', payload: { title: event.title }, status: 'pending' })
  if (error) errorMessage.value = error.message
  else { successMessage.value = 'Pengajuan penghapusan dikirim ke admin.'; selectedEvent.value = null; await loadCalendar() }
}
async function setReaction(event, reaction) {
  const current = selectedReaction(event.id)
  const result = current === reaction
    ? await supabase.from('calendar_reactions').delete().eq('event_id', event.id).eq('user_id', auth.user.id)
    : await supabase.from('calendar_reactions').upsert({ event_id: event.id, user_id: auth.user.id, reaction, updated_at: new Date().toISOString() }, { onConflict: 'event_id,user_id' })
  if (result.error) { errorMessage.value = result.error.message; return }
  const { data } = await supabase.from('calendar_reactions').select('*').in('event_id', events.value.map(e => e.id))
  reactions.value = data || []
}
async function setMarker(emoji) {
  const existing = markers.value.find(marker => marker.marker_date === selectedDate.value)
  const result = existing?.emoji === emoji
    ? await supabase.from('personal_calendar_markers').delete().eq('user_id', auth.user.id).eq('marker_date', selectedDate.value)
    : await supabase.from('personal_calendar_markers').upsert({ user_id: auth.user.id, marker_date: selectedDate.value, emoji }, { onConflict: 'user_id,marker_date' })
  if (result.error) errorMessage.value = result.error.message
  else {
    const { data } = await supabase.from('personal_calendar_markers').select('*').gte('marker_date', toDateKey(new Date(monthCursor.value.getFullYear(), monthCursor.value.getMonth(), 1))).lte('marker_date', toDateKey(new Date(monthCursor.value.getFullYear(), monthCursor.value.getMonth() + 1, 0)))
    markers.value = data || []
  }
}
async function reviewRequest(request, status) {
  const reason = (rejectionReasons.value[request.id] || '').trim()
  if (status === 'rejected' && !reason) { errorMessage.value = 'Alasan penolakan wajib diisi.'; return }
  const { error } = await supabase.from('calendar_requests').update({ status, rejection_reason: status === 'rejected' ? reason : null, reviewed_by: auth.user.id, reviewed_at: new Date().toISOString() }).eq('id', request.id)
  if (error) { errorMessage.value = error.message; return }
  successMessage.value = status === 'approved' ? 'Pengajuan disetujui.' : 'Pengajuan ditolak.'
  await loadCalendar()
  await loadPendingRequests()
}
function closeRequests() {
  showRequests.value = false
  if (route.query.requests === '1') { const query = { ...route.query }; delete query.requests; router.replace({ name: 'schedule', query }) }
}
function requestLabel(request) {
  return ({ add: 'Tambah kegiatan', edit: 'Edit kegiatan', delete: 'Hapus kegiatan' })[request.request_type] || request.request_type
}

watch(() => route.query.requests, async (value) => {
  if (value === '1' && auth.isAdmin) { showRequests.value = true; await loadPendingRequests(); await loadAdminHistory() }
}, { immediate: true })
onMounted(loadCalendar)
</script>

<template>
  <section class="calendar-page" data-testid="schedule-page">
    <header class="page-head">
      <span class="page-head__eyebrow">Twogether Class · XI B2</span>
      <div class="calendar-heading">
        <div>
          <h1 class="page-head__title">Kalender Kelas</h1>
          <p class="page-head__desc">Satu kalender untuk semua cerita dan kegiatan kelas.</p>
        </div>

      </div>
    </header>

    <p v-if="errorMessage" class="notice notice--error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="notice notice--success">{{ successMessage }} <button @click="successMessage = ''">Tutup</button></p>

    <section class="calendar-card" aria-label="Kalender bulanan">
      <div class="month-toolbar">
        <button class="month-nav" aria-label="Bulan sebelumnya" @click="changeMonth(-1)"><ChevronLeft :size="20" /></button>
        <h2>{{ calendarTitle }}</h2>
        <button class="month-nav" aria-label="Bulan berikutnya" @click="changeMonth(1)"><ChevronRight :size="20" /></button>
      </div>
      <div class="weekday-row"><span v-for="day in ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']" :key="day">{{ day }}</span></div>
      <div class="month-grid">
        <button v-for="day in monthDays" :key="day.key" class="day-cell" :class="{ 'day-cell--muted': !day.inMonth, 'day-cell--selected': selectedDate === day.key, 'day-cell--today': day.key === toDateKey(today) }" @click="selectedDate = day.key">
          <span class="day-number">{{ day.day }}</span>
          <span v-if="day.marker" class="day-marker">{{ day.marker }}</span>
          <span class="day-events">
            <span v-for="event in day.events.slice(0, 2)" :key="event.id" class="event-peek">{{ countsFor(event.id).popular ? '↑ ' : '' }}{{ event.title }}</span>
            <span v-if="day.events.length > 2" class="more-events">+{{ day.events.length - 2 }} lainnya</span>
          </span>
          <span v-if="day.events.length" class="event-dots"><i v-for="event in day.events.slice(0, 3)" :key="event.id"></i></span>
        </button>
      </div>
      <div class="calendar-legend"><span><i class="legend-dot"></i> Kegiatan kelas</span><span><Smile :size="13" /> Emoji pribadi</span></div>
    </section>

    <section class="day-agenda">
      <div class="agenda-heading">
        <div><span class="page-head__eyebrow">Agenda tanggal</span><h2>{{ formatLongDate(selectedDate) }}</h2></div>
        <button class="add-button" @click="openNewForm"><Plus :size="18" /> Tambah</button>
      </div>
      <div class="personal-marker">
        <div><Smile :size="17" /><span>Emoji pribadi</span><small>Hanya terlihat olehmu</small></div>
        <div class="emoji-options"><button v-for="emoji in emojiChoices" :key="emoji" :class="{ active: selectedMarker === emoji }" @click="setMarker(emoji)">{{ emoji }}</button></div>
      </div>
      <div v-if="loading" class="empty-state"><LoaderCircle class="spin" :size="22" /> Memuat kalender…</div>
      <div v-else-if="!selectedEvents.length" class="empty-state"><CalendarDays :size="28" /><strong>Belum ada kegiatan</strong><span>Kegiatan yang disetujui admin akan muncul di sini.</span></div>
      <button v-for="event in selectedEvents" :key="event.id" class="agenda-event" @click="selectedEvent = event">
        <span class="event-time">{{ formatTime(event.start_time) || 'Waktu belum diatur' }}<small v-if="event.end_time">s.d. {{ formatTime(event.end_time) }}</small></span>
        <span class="event-copy"><strong>{{ event.title }}</strong><small>{{ event.location || 'Lokasi belum ditentukan' }}</small><small>Dibuat oleh {{ event.creator?.display_name || (event.created_by === auth.user.id ? auth.user.displayName : 'Nama tidak tersedia') }}</small></span>
        <TrendingUp v-if="countsFor(event.id).popular" class="popular-icon" :size="20" aria-label="Populer" />
        <ChevronRight :size="18" class="muted-icon" />
      </button>
    </section>

    <section v-if="myRequests.length" class="my-requests">
      <h2><ClipboardList :size="18" /> Pengajuan saya</h2>
      <article v-for="request in myRequests.slice(0, 5)" :key="request.id" class="request-row">
        <div><strong>{{ request.payload?.title || requestLabel(request) }}</strong><small>{{ requestLabel(request) }}</small><small v-if="request.status === 'rejected'">Alasan: {{ request.rejection_reason }}</small></div>
        <span class="status-pill" :class="`status-pill--${request.status}`">{{ request.status === 'pending' ? 'Menunggu' : request.status === 'approved' ? 'Disetujui' : 'Ditolak' }}</span>
      </article>
    </section>

    <div v-if="showForm" class="modal-backdrop" @click.self="showForm = false">
      <form class="dialog" @submit.prevent="submitEvent">
        <div class="dialog-head"><div><span class="page-head__eyebrow">{{ editingEvent ? 'Pengajuan perubahan' : 'Kalender bersama' }}</span><h2>{{ editingEvent ? 'Edit kegiatan' : 'Tambah kegiatan' }}</h2></div><button type="button" class="icon-button" @click="showForm = false"><X /></button></div>
        <label class="form-field"><span class="form-label">Judul kegiatan *</span><input v-model="form.title" class="form-input" required maxlength="100" placeholder="Contoh: Rapat kelas" /></label>
        <label class="form-field"><span class="form-label">Tanggal kegiatan *</span><input v-model="form.event_date" class="form-input" type="date" required /></label>
        <div class="form-grid"><label class="form-field"><span class="form-label">Jam mulai *</span><input v-model="form.start_time" class="form-input" type="time" required /></label><label class="form-field"><span class="form-label">Jam selesai</span><input v-model="form.end_time" class="form-input" type="time" /></label></div>
        <label class="form-field"><span class="form-label">Lokasi</span><input v-model="form.location" class="form-input" maxlength="120" placeholder="Lokasi kegiatan" /></label>
        <label class="form-field"><span class="form-label">Deskripsi</span><textarea v-model="form.description" class="form-input form-textarea" maxlength="1000" placeholder="Ceritakan detail kegiatannya…"></textarea></label>
        <p class="form-hint">Pengajuan akan muncul di kalender setelah disetujui admin.</p>
        <button class="submit-button" type="submit" :disabled="saving">{{ saving ? 'Mengirim…' : 'Kirim pengajuan' }}</button>
      </form>
    </div>

    <div v-if="selectedEvent" class="modal-backdrop" @click.self="selectedEvent = null">
      <article class="dialog event-dialog">
        <div class="dialog-head"><span class="page-head__eyebrow">Detail kegiatan</span><button class="icon-button" @click="selectedEvent = null"><X /></button></div>
        <h2>{{ selectedEvent.title }}</h2>
        <p v-if="selectedEvent.description" class="event-description">{{ selectedEvent.description }}</p>
        <div class="detail-line"><CalendarDays :size="17" /> {{ formatLongDate(selectedEvent.event_date) }}</div>
        <div class="detail-line"><Clock :size="17" /> {{ formatTime(selectedEvent.start_time) }}<template v-if="selectedEvent.end_time"> – {{ formatTime(selectedEvent.end_time) }}</template></div>
        <div v-if="selectedEvent.location" class="detail-line"><MapPin :size="17" /> {{ selectedEvent.location }}</div>
        <div class="detail-line"><span class="creator-avatar">{{ (selectedEvent.created_by === auth.user.id ? auth.user.displayName : 'T')[0] }}</span> Dibuat oleh {{ selectedEvent.creator?.display_name || (selectedEvent.created_by === auth.user.id ? auth.user.displayName : 'Nama tidak tersedia') }}</div>
        <div class="vote-row"><button :class="{ chosen: selectedReaction(selectedEvent.id) === 'like' }" @click="setReaction(selectedEvent, 'like')"><ThumbsUp :size="18" /> {{ countsFor(selectedEvent.id).likes }}</button><button :class="{ chosen: selectedReaction(selectedEvent.id) === 'dislike' }" @click="setReaction(selectedEvent, 'dislike')"><ThumbsDown :size="18" /> {{ countsFor(selectedEvent.id).dislikes }}</button><span v-if="countsFor(selectedEvent.id).popular" class="popular-label"><TrendingUp :size="17" /> Populer</span></div>
        <p class="vote-hint">Panah populer muncul jika Like minimal 6 dan mencapai setidaknya 60% dari seluruh voting.</p>
        <div class="dialog-actions"><button v-if="selectedEvent.created_by === auth.user.id" class="secondary-button" @click="openEditForm(selectedEvent)"><Pencil :size="16" /> Ajukan edit</button><button class="danger-button" @click="requestDelete(selectedEvent)"><Trash2 :size="16" /> Ajukan hapus</button></div>
      </article>
    </div>

    <div v-if="showRequests && auth.isAdmin" class="modal-backdrop" @click.self="closeRequests">
      <section class="dialog requests-dialog"><div class="dialog-head"><div><span class="page-head__eyebrow">Admin Power</span><h2>Pengajuan kalender</h2></div><button class="icon-button" @click="closeRequests"><X /></button></div>
        <div v-if="!pendingRequests.length" class="empty-state">Tidak ada pengajuan yang menunggu.</div>
        <article v-for="request in pendingRequests" :key="request.id" class="moderation-card">
          <div class="moderation-top"><span class="status-pill status-pill--pending">{{ requestLabel(request) }}</span><small>{{ request.requester?.display_name || 'Nama tidak tersedia' }}</small></div>
          <h3>{{ request.payload?.title || 'Pengajuan hapus kegiatan' }}</h3>
          <p v-if="request.payload?.event_date">{{ request.payload.event_date }} · {{ request.payload.start_time || 'Waktu belum diatur' }}<template v-if="request.payload.end_time">–{{ request.payload.end_time }}</template></p>
          <p v-if="request.payload?.location">{{ request.payload.location }}</p>
          <p v-if="request.request_type === 'edit'">Perubahan akan diterapkan setelah disetujui.</p>
          <label v-if="request.request_type === 'delete'" class="form-field"><span class="form-label">Kegiatan yang akan dihapus</span><span>{{ request.payload?.title || 'Kegiatan terpilih' }}</span></label>
          <label class="form-field"><span class="form-label">Alasan penolakan (wajib jika menolak)</span><textarea v-model="rejectionReasons[request.id]" class="form-input form-textarea" rows="2" placeholder="Tuliskan alasan jika ditolak"></textarea></label>
          <div class="moderation-actions"><button class="approve-button" @click="reviewRequest(request, 'approved')"><Check :size="16" /> Setujui</button><button class="reject-button" @click="reviewRequest(request, 'rejected')"><X :size="16" /> Tolak</button></div>
        </article>
        <div class="history-heading"><h3>Riwayat keputusan</h3><small>30 keputusan terakhir</small></div>
        <article v-for="item in adminHistory" :key="`history-${item.id}`" class="history-row">
          <div><strong>{{ item.payload?.title || requestLabel(item) }}</strong><small>{{ item.requester?.display_name || 'Nama tidak tersedia' }} · {{ requestLabel(item) }}</small><small v-if="item.status === 'rejected'">Alasan: {{ item.rejection_reason }}</small><small>Diproses oleh {{ item.reviewer?.display_name || 'Admin' }}</small></div>
          <span class="status-pill" :class="`status-pill--${item.status}`">{{ item.status === 'approved' ? 'Disetujui' : 'Ditolak' }}</span>
        </article>
      </section>
    </div>
  </section>
</template>

<style scoped>
.calendar-page { max-width: 900px; margin: 0 auto; }
.calendar-heading { display:flex; align-items:center; justify-content:space-between; gap:12px; }
.icon-button,.month-nav { border:0; background:var(--c-gray); color:var(--c-text); display:grid; place-items:center; border-radius:14px; width:42px; height:42px; position:relative; }

.calendar-card,.day-agenda,.my-requests { background:#fff; border:1px solid var(--c-border); border-radius:24px; padding:16px; box-shadow:var(--shadow-sm); margin-bottom:16px; }
.month-toolbar { display:flex; align-items:center; justify-content:space-between; margin-bottom:14px; }
.month-toolbar h2 { font-size:18px; font-weight:800; text-transform:capitalize; }
.weekday-row,.month-grid { display:grid; grid-template-columns:repeat(7,minmax(0,1fr)); }
.weekday-row { margin-bottom:7px; }
.weekday-row span { text-align:center; color:var(--c-text-muted); font-size:11px; font-weight:700; padding:5px 0; }
.day-cell { min-width:0; min-height:76px; padding:6px 3px 5px; border:1px solid #f0f2f7; border-radius:9px; background:#fff; display:flex; flex-direction:column; align-items:center; gap:3px; color:var(--c-text); }
.day-cell--muted { opacity:.36; background:#fafbfc; }
.day-cell--selected { border:2px solid var(--c-primary); background:var(--c-blue-soft); }
.day-cell--today .day-number { color:var(--c-primary); font-weight:900; }
.day-number { font-size:12px; font-weight:700; line-height:16px; }
.day-marker { font-size:15px; line-height:16px; }
.day-events { width:100%; display:flex; flex-direction:column; gap:2px; overflow:hidden; }
.event-peek { width:100%; overflow:hidden; white-space:nowrap; text-overflow:ellipsis; padding:2px 3px; border-radius:4px; background:#eaf2ff; color:#245bb0; font-size:8px; line-height:12px; text-align:left; }
.more-events { color:var(--c-text-muted); font-size:8px; }
.event-dots { display:flex; gap:3px; margin-top:auto; }
.event-dots i,.legend-dot { display:block; width:4px; height:4px; border-radius:50%; background:var(--c-primary); }
.calendar-legend { display:flex; gap:15px; color:var(--c-text-muted); font-size:10px; margin-top:12px; }
.calendar-legend span { display:flex; align-items:center; gap:5px; }
.agenda-heading { display:flex; justify-content:space-between; align-items:center; gap:12px; margin-bottom:14px; }
.agenda-heading h2 { font-size:17px; font-weight:800; text-transform:capitalize; }
.add-button,.submit-button { display:inline-flex; align-items:center; justify-content:center; gap:7px; border:0; border-radius:14px; padding:11px 14px; background:var(--c-primary); color:white; font-weight:800; font-size:13px; }
.personal-marker { background:#fafbfe; border:1px solid var(--c-border); border-radius:15px; padding:11px; margin-bottom:12px; }
.personal-marker > div:first-child { display:flex; align-items:center; gap:7px; font-size:12px; font-weight:800; }
.personal-marker small { color:var(--c-text-muted); font-size:10px; font-weight:500; margin-left:auto; }
.emoji-options { display:flex; flex-wrap:wrap; gap:6px; margin-top:9px; }
.emoji-options button { width:32px; height:32px; border:1px solid transparent; border-radius:9px; background:#fff; font-size:17px; }
.emoji-options button.active { border-color:var(--c-primary); background:var(--c-blue-soft); }
.empty-state { min-height:110px; display:flex; flex-direction:column; justify-content:center; align-items:center; gap:7px; color:var(--c-text-muted); font-size:12px; text-align:center; }
.empty-state strong { color:var(--c-text); font-size:14px; }
.agenda-event { width:100%; display:flex; align-items:center; gap:11px; text-align:left; border:1px solid var(--c-border); border-radius:15px; background:#fff; padding:12px; margin-top:8px; }
.event-time { width:65px; flex-shrink:0; font-size:12px; font-weight:800; color:var(--c-primary); }
.event-time small,.event-copy small { display:block; font-size:10px; color:var(--c-text-muted); font-weight:500; }
.event-copy { min-width:0; flex:1; display:flex; flex-direction:column; gap:2px; }
.event-copy strong { font-size:13px; overflow-wrap:anywhere; }
.popular-icon,.popular-label { color:#16a34a; }
.muted-icon { color:var(--c-text-soft); }
.my-requests h2 { display:flex; align-items:center; gap:8px; font-size:16px; margin-bottom:10px; }
.request-row { display:flex; align-items:center; justify-content:space-between; gap:10px; padding:11px 0; border-top:1px solid var(--c-border); }
.request-row div { display:flex; flex-direction:column; gap:2px; min-width:0; }
.request-row strong { font-size:12px; }
.request-row small { color:var(--c-text-muted); font-size:10px; }
.status-pill { white-space:nowrap; border-radius:99px; padding:5px 9px; font-size:10px; font-weight:800; background:#f1f3f7; color:#687387; }
.status-pill--pending { background:#fff5d8; color:#946c09; }.status-pill--approved { background:#e5f8ed; color:#187647; }.status-pill--rejected { background:#ffecef; color:#bd343b; }
.modal-backdrop { position:fixed; inset:0; z-index:100; display:flex; align-items:flex-end; justify-content:center; padding:14px; background:rgba(25,32,45,.42); }
.dialog { width:100%; max-width:520px; max-height:90vh; overflow:auto; display:flex; flex-direction:column; gap:13px; background:#fff; border-radius:24px; padding:20px; box-shadow:var(--shadow-lg); }
.dialog-head { display:flex; justify-content:space-between; align-items:center; gap:10px; }
.dialog h2 { font-size:21px; font-weight:850; }
.form-field { display:flex; flex-direction:column; gap:6px; }
.form-label { font-size:12px; font-weight:800; }
.form-grid { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
.form-hint,.vote-hint { color:var(--c-text-muted); font-size:11px; }
.submit-button { width:100%; min-height:46px; }
.submit-button:disabled { opacity:.6; }
.event-description { color:var(--c-text-muted); font-size:13px; white-space:pre-wrap; }
.detail-line { display:flex; align-items:center; gap:9px; font-size:13px; color:var(--c-text-muted); }
.creator-avatar { width:23px; height:23px; display:grid; place-items:center; border-radius:50%; background:var(--c-blue-soft); color:var(--c-primary); font-weight:800; }
.vote-row { display:flex; gap:8px; align-items:center; }
.vote-row button { display:flex; align-items:center; gap:7px; border:1px solid var(--c-border); border-radius:12px; padding:9px 13px; background:#fff; font-weight:800; }
.vote-row button:first-child.chosen { color:#16834d; background:#e8f8ef; border-color:#a7e4bf; }.vote-row button:last-of-type.chosen { color:#c43e46; background:#fff0f0; border-color:#f1b5b8; }
.popular-label { display:flex; align-items:center; gap:4px; font-size:11px; font-weight:800; }
.dialog-actions,.moderation-actions { display:flex; gap:8px; flex-wrap:wrap; }
.secondary-button,.danger-button,.approve-button,.reject-button { display:flex; align-items:center; justify-content:center; gap:6px; flex:1; min-height:42px; border:0; border-radius:12px; padding:9px; font-size:12px; font-weight:800; }
.secondary-button { background:var(--c-blue-soft); color:var(--c-primary); }.danger-button,.reject-button { background:#fff0f0; color:#c43e46; }.approve-button { background:#e8f8ef; color:#16834d; }
.requests-dialog { max-width:600px; }
.moderation-card { border:1px solid var(--c-border); border-radius:16px; padding:13px; display:flex; flex-direction:column; gap:9px; }
.moderation-top { display:flex; justify-content:space-between; align-items:center; gap:8px; }.moderation-top small,.moderation-card p { color:var(--c-text-muted); font-size:11px; }.moderation-card h3 { font-size:15px; }.history-heading { display:flex; justify-content:space-between; align-items:center; margin-top:8px; }.history-heading h3 { font-size:15px; }.history-heading small,.history-row small { color:var(--c-text-muted); font-size:10px; }.history-row { display:flex; justify-content:space-between; gap:10px; padding:10px 0; border-top:1px solid var(--c-border); }.history-row div { display:flex; flex-direction:column; gap:3px; min-width:0; }.history-row strong { font-size:12px; }
.notice { border-radius:12px; padding:10px 12px; margin-bottom:12px; font-size:12px; }.notice--error { background:#fff0f0; color:#b8323a; }.notice--success { background:#e8f8ef; color:#176b43; }.notice button { margin-left:8px; border:0; background:transparent; text-decoration:underline; font-weight:800; }
.spin { animation:spin 1s linear infinite; } @keyframes spin { to { transform:rotate(360deg); } }
@media (min-width:600px) { .day-cell { min-height:90px; padding:8px 5px; }.day-number { font-size:13px; }.event-peek { font-size:9px; }.modal-backdrop { align-items:center; }.calendar-card,.day-agenda,.my-requests { padding:20px; } }
@media (max-width:380px) { .day-cell { min-height:65px; }.event-peek { font-size:7px; padding:1px 2px; }.calendar-card { padding:10px; }.weekday-row span { font-size:10px; } }
</style>
