<script setup>
import { computed, onMounted, ref } from 'vue'
import { CalendarDays, MessageCircle, Vote, Sparkles, Heart, Send, CheckCircle2, RefreshCw } from 'lucide-vue-next'
import PagePlaceholder from '@/components/shared/PagePlaceholder.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/useAuthStore'
import { useAnnouncementStore } from '@/stores/useAnnouncementStore'
import { useSubjectStore } from '@/stores/useSubjectStore'
import { toISODate } from '@/utils/time'
import { dailyQuestions, pollTemplates, thisOrThatTemplates, announcementTemplates, eventTemplates, dailyIndex } from '@/data/dailyContent'

const auth = useAuthStore()
const announcements = useAnnouncementStore()
const subjects = useSubjectStore()
const question = computed(() => dailyQuestions[dailyIndex(dailyQuestions.length)])
const poll = computed(() => pollTemplates[dailyIndex(pollTemplates.length, 5)])
const thisOrThat = computed(() => thisOrThatTemplates[dailyIndex(thisOrThatTemplates.length, 2)])
const fallbackAnnouncement = computed(() => announcementTemplates[dailyIndex(announcementTemplates.length, 11)])
const latestAnnouncement = computed(() => announcements.active[0] || null)
const announcement = computed(() => latestAnnouncement.value ? `${latestAnnouncement.value.title}: ${latestAnnouncement.value.body}` : fallbackAnnouncement.value)
const todayISO = toISODate(new Date())
const upcomingActivity = computed(() => subjects.activities.filter(a => a.date && a.date >= todayISO).sort((a,b) => a.date.localeCompare(b.date))[0] || null)
const event = computed(() => upcomingActivity.value ? `Agenda Kelas: ${upcomingActivity.value.title} — ${upcomingActivity.value.subject} (${upcomingActivity.value.date})` : eventTemplates[dailyIndex(eventTemplates.length, 7)])
const answer = ref('')
const visibility = ref('private')
const pollChoice = ref('')
const thisOrThatChoice = ref('')
const saving = ref(false)
const feedback = ref('')
const error = ref('')
const discovery = ref([])
const approvedAnswers = ref([])
const pollResults = ref([])
const choiceResults = ref([])
const sharedInterest = computed(() => { const counts = new Map(); for (const student of discovery.value) for (const hobby of student.hobbies || []) counts.set(hobby, (counts.get(hobby) || 0) + 1); return [...counts.entries()].filter(([,count]) => count >= 2).sort((a,b) => b[1]-a[1]).slice(0,4) })
const discoveryError = ref('')
const submitted = ref({ question: false, poll: false, choice: false })
const today = new Date().toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long' })

async function loadSubmissions() {
  const baliDate = new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Makassar' })
  const { data } = await supabase.from('daily_interactions').select('content_type').eq('activity_date', baliDate)
  for (const row of data || []) {
    if (row.content_type === 'random_question') submitted.value.question = true
    if (row.content_type === 'class_poll') submitted.value.poll = true
    if (row.content_type === 'this_or_that') submitted.value.choice = true
  }
}
async function loadPollResults() {
  const [pollRes, choiceRes] = await Promise.all([
    supabase.rpc('get_daily_poll_results', { p_content_type: 'class_poll', p_prompt: poll.value.q }),
    supabase.rpc('get_daily_poll_results', { p_content_type: 'this_or_that', p_prompt: thisOrThat.value.join(' / ') })
  ])
  pollResults.value = pollRes.data || []
  choiceResults.value = choiceRes.data || []
}
function resultWidth(rows, item) { const total = rows.reduce((sum, row) => sum + Number(row.votes || 0), 0); return total ? `${Math.round(Number(item.votes) / total * 100)}%` : '0%' }
async function loadApprovedAnswers() {
  const { data } = await supabase.rpc('get_approved_daily_answers', { p_prompt: question.value })
  approvedAnswers.value = data || []
}
async function loadDiscovery() {
  const { data, error: e } = await supabase.rpc('get_discover_students')
  if (e) discoveryError.value = 'Daily Discovery belum tersedia. Admin perlu menjalankan migration fitur komunitas.'
  else discovery.value = data || []
}
async function submit(kind) {
  feedback.value = ''; error.value = ''
  if (kind === 'question' && !answer.value.trim()) { error.value = 'Tulis jawaban singkat terlebih dahulu.'; return }
  if (kind === 'poll' && !pollChoice.value) { error.value = 'Pilih salah satu jawaban polling.'; return }
  if (kind === 'choice' && !thisOrThatChoice.value) { error.value = 'Pilih salah satu opsi.'; return }
  saving.value = true
  let payload
  if (kind === 'question') payload = { user_id: auth.user.id, content_type: 'random_question', prompt: question.value, response: answer.value.trim(), visibility: visibility.value, status: visibility.value === 'private' ? 'private' : 'pending' }
  if (kind === 'poll') payload = { user_id: auth.user.id, content_type: 'class_poll', prompt: poll.value.q, response: pollChoice.value, visibility: 'private', status: 'private' }
  if (kind === 'choice') payload = { user_id: auth.user.id, content_type: 'this_or_that', prompt: thisOrThat.value.join(' / '), response: thisOrThatChoice.value, visibility: 'private', status: 'private' }
  const { error: e } = await supabase.from('daily_interactions').insert(payload)
  if (e) error.value = 'Belum berhasil disimpan. Pastikan migration fitur komunitas sudah dijalankan.'
  else {
    submitted.value[kind] = true
    feedback.value = kind === 'question' ? 'Jawabanmu sudah tersimpan. Jawaban publik akan ditinjau admin terlebih dahulu.' : 'Pilihanmu berhasil dicatat. Terima kasih sudah berpartisipasi!'
    if (kind === 'question') { answer.value = ''; await loadApprovedAnswers() }
    if (kind === 'poll' || kind === 'choice') await loadPollResults()
  }
  saving.value = false
}
onMounted(async () => { await Promise.all([loadDiscovery(), loadApprovedAnswers(), loadPollResults(), loadSubmissions(), announcements.load(), subjects.load()]) })
</script>

<template>
  <PagePlaceholder eyebrow="Community" title="Daily Discovery & Events" :icon="CalendarDays" tone="mint" test-id="daily-page">
    <div class="daily-wrap">
      <p class="daily-date">{{ today }} · Konten harian berganti otomatis</p>
      <BaseCard class="daily-feature">
        <div class="daily-feature__icon"><Sparkles :size="20" /></div>
        <div><span class="daily-kicker">CLASS ANNOUNCEMENT</span><h2>Info Hari Ini</h2><p>{{ announcement }}</p></div>
      </BaseCard>
      <div class="daily-grid">
        <BaseCard class="daily-card">
          <span class="daily-kicker">DAILY EVENT</span><h2>{{ event }}</h2>
          <p class="daily-muted">Prompt kegiatan ringan untuk membangun interaksi kelas.</p>
        </BaseCard>
        <BaseCard class="daily-card">
          <span class="daily-kicker">RANDOM QUESTION</span><h2>{{ question }}</h2>
          <p class="daily-muted">Jawaban bersifat sukarela. Pilih apakah jawabanmu tetap pribadi atau ingin diajukan untuk ditampilkan.</p>
          <textarea v-model="answer" class="daily-input" maxlength="500" rows="3" placeholder="Tulis jawabanmu (maks. 500 karakter)" :disabled="submitted.question" />
          <div class="visibility-options">
            <label><input v-model="visibility" type="radio" value="private" :disabled="submitted.question" /> Pribadi</label>
            <label><input v-model="visibility" type="radio" value="anonymous" :disabled="submitted.question" /> Ajukan anonim</label>
            <label><input v-model="visibility" type="radio" value="nickname" :disabled="submitted.question" /> Ajukan dengan nickname</label>
          </div>
          <button class="daily-button" :disabled="saving || submitted.question" @click="submit('question')"><Send :size="16" /> {{ submitted.question ? 'Terkirim' : 'Kirim Jawaban' }}</button>
        </BaseCard>
        <BaseCard class="daily-card">
          <span class="daily-kicker">CLASS POLLING</span><h2>{{ poll.q }}</h2>
          <div class="option-list"><label v-for="option in poll.options" :key="option" class="option-row"><input v-model="pollChoice" type="radio" :value="option" :disabled="submitted.poll" />{{ option }}</label></div>
          <button class="daily-button" :disabled="saving || submitted.poll" @click="submit('poll')"><Vote :size="16" /> {{ submitted.poll ? 'Pilihan Tercatat' : 'Ikut Polling' }}</button>
          <div v-if="pollResults.length" class="result-list"><div v-for="item in pollResults" :key="item.response" class="result-item"><div><span>{{ item.response }}</span><b>{{ item.votes }}</b></div><i><span :style="{ width: resultWidth(pollResults,item) }"></span></i></div></div>
        </BaseCard>
        <BaseCard class="daily-card">
          <span class="daily-kicker">THIS OR THAT</span><h2>Pilih salah satu!</h2>
          <div class="choice-grid"><button v-for="option in thisOrThat" :key="option" :class="{ selected: thisOrThatChoice === option }" :disabled="submitted.choice" @click="thisOrThatChoice = option">{{ option }}</button></div>
          <button class="daily-button" :disabled="saving || submitted.choice" @click="submit('choice')"><CheckCircle2 :size="16" /> {{ submitted.choice ? 'Pilihan Tercatat' : 'Kirim Pilihan' }}</button>
          <div v-if="choiceResults.length" class="result-list"><div v-for="item in choiceResults" :key="item.response" class="result-item"><div><span>{{ item.response }}</span><b>{{ item.votes }}</b></div><i><span :style="{ width: resultWidth(choiceResults,item) }"></span></i></div></div>
        </BaseCard>
      </div>
      <p v-if="error" class="daily-error" role="alert">{{ error }}</p><p v-if="feedback" class="daily-success"><CheckCircle2 :size="16" /> {{ feedback }}</p>
      <BaseCard class="daily-card">
        <div class="daily-section-head"><div><span class="daily-kicker">DAILY DISCOVERY</span><h2>Kenali teman sekelas</h2></div><button class="refresh-button" @click="loadDiscovery"><RefreshCw :size="16" /> Muat ulang</button></div>
        <p v-if="discoveryError" class="daily-muted">{{ discoveryError }}</p>
        <div v-else-if="discovery.length" class="discovery-list">
          <div v-for="student in discovery.slice(0, 8)" :key="student.profile_id" class="discovery-person"><span class="discovery-avatar">{{ (student.display_name || '?').charAt(0) }}</span><div><strong>{{ student.display_name }}</strong><p>{{ (student.hobbies || []).slice(0, 3).join(' · ') || 'Sedang mengenal diri' }}</p></div><span v-if="student.about_me?.length" class="discovery-tag">{{ student.about_me[0] }}</span></div>
        </div>
        <p v-else class="daily-muted">Daily Discovery akan muncul jika ada siswa yang mengisi nama panggilan, melengkapi minat, dan mengaktifkan izin tampil di Discover Students.</p>
      </BaseCard>
      <BaseCard v-if="approvedAnswers.length" class="daily-card"><span class="daily-kicker">SHARED RESPONSES</span><h2>Jawaban pilihan kelas</h2><div v-for="(item, i) in approvedAnswers" :key="i" class="approved-answer"><strong>{{ item.display_name }}</strong><p>{{ item.response }}</p></div></BaseCard>
      <BaseCard v-if="sharedInterest.length" class="daily-card"><span class="daily-kicker">SHARED INTEREST</span><h2>Minat yang sama di kelas</h2><div class="shared-tags"><span v-for="interest in sharedInterest" :key="interest[0]">{{ interest[0] }} <b>{{ interest[1] }} siswa</b></span></div></BaseCard>
      <p class="daily-footnote"><Heart :size="14" /> Jawaban publik tidak langsung ditampilkan. Admin perlu meninjau jawaban terlebih dahulu.</p>
    </div>
  </PagePlaceholder>
</template>

<style scoped>
.daily-wrap{display:flex;flex-direction:column;gap:16px}.daily-date,.daily-muted,.daily-footnote{font-size:13px;color:var(--c-text-muted)}.daily-feature{display:flex;gap:16px;align-items:flex-start;background:linear-gradient(120deg,#eef7ff,#f3f0ff)}.daily-feature__icon{width:44px;height:44px;display:grid;place-items:center;border-radius:15px;background:#fff;color:var(--c-primary);flex-shrink:0}.daily-kicker{font-size:10px;font-weight:800;letter-spacing:.1em;color:var(--c-primary)}.daily-feature h2,.daily-card h2{font-size:17px;margin:5px 0 8px}.daily-feature p{font-size:14px;color:var(--c-text-muted);line-height:1.55}.daily-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}.daily-card{display:flex;flex-direction:column;gap:10px;min-width:0}.daily-card:first-child{grid-column:span 2}.daily-input{width:100%;border:1px solid var(--c-border);border-radius:12px;padding:12px;background:var(--c-gray);resize:vertical}.visibility-options{display:flex;flex-wrap:wrap;gap:8px 14px}.visibility-options label,.option-row{font-size:12px;color:var(--c-text-muted);display:flex;align-items:center;gap:6px}.option-list{display:grid;gap:9px}.option-row{padding:10px;border:1px solid var(--c-border);border-radius:12px;color:var(--c-text)}.daily-button{display:inline-flex;align-items:center;justify-content:center;gap:8px;border:0;border-radius:12px;padding:11px 14px;background:var(--c-primary);color:white;font-weight:700;font-size:13px;margin-top:auto}.daily-button:disabled{opacity:.55}.choice-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}.choice-grid button{border:1px solid var(--c-border);background:var(--c-gray);border-radius:12px;padding:14px 8px;font-weight:700;font-size:13px}.choice-grid button.selected{border-color:var(--c-primary);background:var(--c-blue-soft);color:var(--c-primary)}.daily-section-head{display:flex;justify-content:space-between;align-items:center;gap:12px}.refresh-button{display:flex;align-items:center;gap:6px;border:1px solid var(--c-border);background:white;border-radius:10px;padding:8px 10px;font-size:12px}.discovery-list{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.discovery-person{display:flex;align-items:center;gap:10px;padding:10px;border:1px solid var(--c-border);border-radius:13px;min-width:0}.discovery-avatar{width:36px;height:36px;display:grid;place-items:center;border-radius:50%;background:var(--c-blue-soft);color:var(--c-primary);font-weight:800;flex-shrink:0}.discovery-person strong{font-size:13px}.discovery-person p{font-size:11px;color:var(--c-text-muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;max-width:160px}.discovery-tag{font-size:10px;background:var(--c-mint);color:#24734c;padding:4px 7px;border-radius:20px;margin-left:auto}.daily-error{color:var(--c-danger);font-size:13px}.daily-success{display:flex;gap:7px;align-items:center;color:#218653;font-size:13px}.daily-footnote{display:flex;align-items:center;gap:6px}.result-list{display:grid;gap:8px;margin-top:4px}.result-item>div{display:flex;justify-content:space-between;font-size:11px;color:var(--c-text-muted)}.result-item i{display:block;height:6px;background:var(--c-gray);border-radius:10px;overflow:hidden;margin-top:4px}.result-item i span{display:block;height:100%;background:var(--c-primary);border-radius:10px}.approved-answer{padding:10px 0;border-top:1px solid var(--c-border)}.approved-answer strong{font-size:12px}.approved-answer p{font-size:13px;color:var(--c-text-muted);margin-top:4px}.shared-tags{display:flex;gap:8px;flex-wrap:wrap}.shared-tags span{display:flex;gap:6px;align-items:center;background:var(--c-mint);color:#226b47;border-radius:20px;padding:7px 10px;font-size:12px}.shared-tags b{font-size:10px}@media(max-width:700px){.daily-grid{grid-template-columns:1fr}.daily-card:first-child{grid-column:auto}.discovery-list{grid-template-columns:1fr}}
</style>
