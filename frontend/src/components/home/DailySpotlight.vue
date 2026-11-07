<script setup>
import { computed, onMounted, ref } from 'vue'
import { CalendarDays, CheckCircle2, Megaphone, MessageCircle, Send, Sparkles, Vote } from 'lucide-vue-next'
import BaseCard from '@/components/base/BaseCard.vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/useAuthStore'
import { dailyQuestions, pollTemplates, thisOrThatTemplates, announcementTemplates, eventTemplates, funFactTemplates } from '@/data/dailyContent'

const auth = useAuthStore()
const answer = ref('')
const visibility = ref('private')
const selected = ref('')
const busy = ref(false)
const submitted = ref(false)
const feedback = ref('')
const error = ref('')

function baliDate() {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Makassar' }).format(new Date())
}
function daySeed(date) {
  // Stable pseudo-random seed: identical for every student on the same Bali date.
  let hash = 2166136261
  for (const char of date) hash = Math.imul(hash ^ char.charCodeAt(0), 16777619)
  return hash >>> 0
}
function pick(list, seed, offset = 0) {
  return list[(seed + offset) % list.length]
}
const today = baliDate()
const seed = daySeed(today)
const types = ['question', 'announcement', 'fun_fact', 'event', 'poll', 'this_or_that']
const kind = types[seed % types.length]
const dailyContent = computed(() => {
  if (kind === 'question') return { kind, label: 'PERTANYAAN HARI INI', title: 'Random Question', prompt: pick(dailyQuestions, seed, 3), icon: MessageCircle }
  if (kind === 'fun_fact') return { kind, label: 'FUN FACT HARI INI', title: 'Tahukah Kamu?', prompt: pick(funFactTemplates, seed, 17), icon: Sparkles }
  if (kind === 'announcement') return { kind, label: 'PENGUMUMAN HARI INI', title: 'Info untuk Kelas', prompt: pick(announcementTemplates, seed, 5), icon: Megaphone }
  if (kind === 'event') return { kind, label: 'DAILY EVENT', title: 'Prompt Hari Ini', prompt: pick(eventTemplates, seed, 7), icon: CalendarDays }
  if (kind === 'poll') {
    const item = pick(pollTemplates, seed, 11)
    return { kind, label: 'CLASS POLLING', title: item.q, options: item.options, icon: Vote }
  }
  const item = pick(thisOrThatTemplates, seed, 13)
  return { kind, label: 'THIS OR THAT', title: 'Pilih salah satu!', options: item, icon: Sparkles }
})
const promptText = computed(() => dailyContent.value.kind === 'this_or_that' ? dailyContent.value.options.join(' / ') : dailyContent.value.prompt || dailyContent.value.title)
const interactionType = computed(() => ({ question: 'random_question', event: 'random_question', poll: 'class_poll', this_or_that: 'this_or_that' })[kind])

async function loadState() {
  if (!interactionType.value || !auth.user?.id) return
  const { data, error: queryError } = await supabase.from('daily_interactions').select('id').eq('activity_date', today).eq('user_id', auth.user.id).limit(1)
  if (!queryError && data?.length) submitted.value = true
}
async function submit() {
  error.value = ''
  feedback.value = ''
  const response = ['question', 'event'].includes(kind) ? answer.value.trim() : selected.value
  if (!response) { error.value = kind === 'poll' || kind === 'this_or_that' ? 'Pilih salah satu jawaban terlebih dahulu.' : 'Tulis jawaban singkat terlebih dahulu.'; return }
  busy.value = true
  const payload = {
    user_id: auth.user.id,
    content_type: interactionType.value,
    prompt: promptText.value,
    response,
    visibility: kind === 'question' || kind === 'event' ? visibility.value : 'private',
    status: (kind === 'question' || kind === 'event') && visibility.value !== 'private' ? 'pending' : 'private'
  }
  const { error: insertError } = await supabase.from('daily_interactions').insert(payload)
  if (insertError) {
    error.value = insertError.code === '23505' || insertError.message?.includes('already')
      ? 'Kamu sudah berpartisipasi pada konten harian hari ini.'
      : insertError.message?.includes('one daily interaction')
        ? 'Kamu sudah mengirim satu respons hari ini.'
        : 'Respons belum berhasil disimpan. Pastikan migration komunitas sudah diterapkan.'
  } else {
    submitted.value = true
    feedback.value = 'Responsmu berhasil dicatat. Terima kasih sudah ikut berpartisipasi!'
    answer.value = ''
  }
  busy.value = false
}
onMounted(loadState)
</script>

<template>
  <BaseCard class="daily-spotlight" data-testid="daily-spotlight">
    <div class="spotlight-top">
      <span class="spotlight-icon"><component :is="dailyContent.icon" :size="18" /></span>
      <span class="spotlight-label">{{ dailyContent.label }}</span>
      <span class="spotlight-date">{{ new Date().toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }) }}</span>
    </div>
    <h2>{{ dailyContent.title }}</h2>
    <p v-if="dailyContent.prompt" class="spotlight-prompt">{{ dailyContent.prompt }}</p>
    <template v-if="['question', 'event'].includes(kind)">
      <textarea v-model="answer" rows="2" maxlength="500" placeholder="Tulis responsmu di sini..." :disabled="submitted" />
      <div class="spotlight-options">
        <label><input v-model="visibility" type="radio" value="private" :disabled="submitted" /> Pribadi</label>
        <label><input v-model="visibility" type="radio" value="anonymous" :disabled="submitted" /> Ajukan anonim</label>
        <label><input v-model="visibility" type="radio" value="nickname" :disabled="submitted" /> Dengan nickname</label>
      </div>
    </template>
    <div v-else-if="['poll', 'this_or_that'].includes(kind)" class="spotlight-choices">
      <button v-for="option in dailyContent.options" :key="option" type="button" :class="{ selected: selected === option }" :disabled="submitted" @click="selected = option">{{ option }}</button>
    </div>
    <p v-if="error" class="spotlight-error" role="alert">{{ error }}</p>
    <p v-if="feedback" class="spotlight-success"><CheckCircle2 :size="15" /> {{ feedback }}</p>
    <button v-if="['question', 'event', 'poll', 'this_or_that'].includes(kind)" class="spotlight-submit" :disabled="busy || submitted" @click="submit">
      <CheckCircle2 v-if="submitted" :size="15" /><Send v-else :size="15" />
      {{ submitted ? 'Sudah berpartisipasi' : busy ? 'Menyimpan...' : 'Kirim respons' }}
    </button>
  </BaseCard>
</template>

<style scoped>
.daily-spotlight{display:grid;gap:10px;padding:17px 19px;background:linear-gradient(115deg,#f2f7ff,#f8f4ff);border:1px solid #e3eaf8}.spotlight-top{display:flex;align-items:center;gap:8px}.spotlight-icon{width:32px;height:32px;border-radius:11px;display:grid;place-items:center;background:white;color:var(--c-primary)}.spotlight-label{font-size:10px;letter-spacing:.09em;font-weight:850;color:var(--c-primary)}.spotlight-date{margin-left:auto;font-size:10px;color:var(--c-text-muted)}h2{font-size:16px;line-height:1.35;font-weight:850}.spotlight-prompt{font-size:13px;line-height:1.5;color:var(--c-text-muted)}textarea{width:100%;resize:vertical;min-height:58px;padding:10px 11px;border:1px solid var(--c-border);border-radius:11px;background:white;font:inherit;font-size:12px}.spotlight-options{display:flex;flex-wrap:wrap;gap:7px 13px}.spotlight-options label{display:flex;align-items:center;gap:5px;font-size:10px;color:var(--c-text-muted)}.spotlight-choices{display:flex;flex-wrap:wrap;gap:8px}.spotlight-choices button{flex:1;min-width:120px;border:1px solid var(--c-border);border-radius:11px;background:white;padding:10px;font-size:12px;font-weight:750}.spotlight-choices button.selected{border-color:var(--c-primary);background:var(--c-blue-soft);color:var(--c-primary)}.spotlight-submit{justify-self:start;display:flex;align-items:center;gap:7px;border:0;border-radius:10px;background:var(--c-primary);color:white;padding:9px 13px;font-size:11px;font-weight:800}.spotlight-submit:disabled{opacity:.6}.spotlight-error{font-size:11px;color:var(--c-danger)}.spotlight-success{display:flex;align-items:center;gap:6px;font-size:11px;color:#218653}
</style>
