<script setup>
import { computed, ref } from 'vue'
import { Gamepad2, Trophy, CheckCircle2, RotateCcw, Sparkles } from 'lucide-vue-next'
import PagePlaceholder from '@/components/shared/PagePlaceholder.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/useAuthStore'
import { gameQuestions, dailyIndex } from '@/data/dailyContent'

const auth = useAuthStore()
const games = [
  { id: 'trivia', name: 'Class Trivia', desc: 'Uji pengetahuan umum dan pelajaran.' },
  { id: 'fact', name: 'Fact or Myth', desc: 'Tentukan apakah pernyataan ini fakta atau mitos.' },
  { id: 'words', name: 'Word Scramble', desc: 'Susun kembali huruf yang diacak.' },
  { id: 'wordle', name: 'Daily Word', desc: 'Tebak kata berdasarkan petunjuk.' }
]
const active = ref('trivia')
const answers = ref({})
const completed = ref({})
const feedback = ref('')
const error = ref('')
const busy = ref(false)
const indexFor = (id, length) => dailyIndex(length, id.length * 3)
const current = computed(() => {
  const id = active.value
  if (id === 'trivia') return gameQuestions.trivia[indexFor(id, gameQuestions.trivia.length)]
  if (id === 'fact') return gameQuestions.fact[indexFor(id, gameQuestions.fact.length)]
  if (id === 'words') return gameQuestions.words[indexFor(id, gameQuestions.words.length)]
  return gameQuestions.wordle[indexFor(id, gameQuestions.wordle.length)]
})
const answerValue = computed(() => answers.value[active.value] ?? '')
const correctAnswer = computed(() => {
  if (active.value === 'trivia') return Number(answerValue.value) === current.value.correct
  if (active.value === 'fact') return answerValue.value === String(current.value.answer)
  return String(answerValue.value).trim().toUpperCase().replace(/\s/g, '') === (current.value.answer || current.value.word)
})
async function finishGame() {
  feedback.value = ''; error.value = ''
  if (!answerValue.value) { error.value = 'Pilih atau masukkan jawaban terlebih dahulu.'; return }
  if (!correctAnswer.value) { feedback.value = 'Belum tepat. Coba lagi, kamu pasti bisa!'; return }
  busy.value = true
  const { data, error: rpcError } = await supabase.rpc('submit_daily_game_answer', { p_game_key: active.value, p_challenge_index: indexFor(active.value, active.value === 'trivia' ? gameQuestions.trivia.length : active.value === 'fact' ? gameQuestions.fact.length : active.value === 'words' ? gameQuestions.words.length : gameQuestions.wordle.length), p_answer: String(answerValue.value).trim().toUpperCase() })
  if (rpcError) {
    error.value = rpcError.message?.includes('Jawaban belum benar') ? 'Jawaban belum tepat. Coba lagi.' : 'Jawaban benar, tetapi hadiah T-Money belum dapat dicatat. Admin perlu menjalankan migration Reward & Shop.'
  } else if (data?.already_claimed) {
    feedback.value = 'Jawaban benar! Hadiah untuk game ini hari ini sudah pernah kamu klaim.'
    completed.value[active.value] = true
  } else {
    feedback.value = `Benar! Kamu mendapatkan ${data?.amount ?? 1} T-Money.`
    completed.value[active.value] = true
  }
  busy.value = false
}
function resetGame() { answers.value[active.value] = ''; feedback.value = ''; error.value = '' }
</script>

<template>
  <PagePlaceholder eyebrow="Class Activities" title="Games" :icon="Gamepad2" tone="peach" test-id="games-page">
    <div class="games-layout">
      <BaseCard class="games-intro"><div class="games-intro__icon"><Trophy :size="22" /></div><div><h2>Play, learn, and earn</h2><p>Mainkan mini games harian. Setiap jenis game dapat memberikan maksimal satu reward T-Money per hari.</p></div></BaseCard>
      <div class="game-tabs"><button v-for="game in games" :key="game.id" :class="{ active: active === game.id }" @click="active = game.id; feedback = ''; error = ''"><strong>{{ game.name }}</strong><small>{{ game.desc }}</small><CheckCircle2 v-if="completed[game.id]" :size="16" /></button></div>
      <BaseCard class="game-stage">
        <div class="game-stage__top"><span class="game-kicker">DAILY CHALLENGE</span><span class="game-reward"><Sparkles :size="14" /> +1 T-Money</span></div>
        <template v-if="active === 'trivia'">
          <h2>{{ current.q }}</h2><div class="game-options"><button v-for="(option, i) in current.a" :key="option" :class="{ chosen: answerValue === String(i) }" @click="answers[active] = String(i)">{{ option }}</button></div>
        </template>
        <template v-else-if="active === 'fact'">
          <h2>{{ current.q }}</h2><div class="game-options game-options--two"><button :class="{ chosen: answerValue === 'true' }" @click="answers[active] = 'true'">Fakta</button><button :class="{ chosen: answerValue === 'false' }" @click="answers[active] = 'false'">Mitos</button></div>
        </template>
        <template v-else-if="active === 'words'">
          <h2>Susun huruf berikut</h2><div class="scrambled-word">{{ current.scrambled }}</div><p class="game-hint">Petunjuk: {{ current.hint }}</p><input v-model="answers[active]" class="game-answer" placeholder="Ketik jawabanmu" maxlength="20" @keyup.enter="finishGame" />
        </template>
        <template v-else>
          <h2>Tebak kata dari petunjuk</h2><div class="wordle-slots"><span v-for="(letter, i) in current.word" :key="i">{{ (answerValue.toUpperCase()[i] || '') }}</span></div><p class="game-hint">{{ current.hint }}</p><input v-model="answers[active]" class="game-answer" placeholder="Masukkan kata" maxlength="8" @keyup.enter="finishGame" />
        </template>
        <p v-if="feedback" class="game-feedback"><CheckCircle2 :size="17" /> {{ feedback }} <span v-if="active === 'trivia'">{{ current.explanation }}</span><span v-else-if="active === 'fact'">{{ current.explanation }}</span></p>
        <p v-if="error" class="game-error">{{ error }}</p>
        <div class="game-actions"><button class="game-submit" :disabled="busy || completed[active]" @click="finishGame">{{ completed[active] ? 'Selesai Hari Ini' : 'Periksa Jawaban' }}</button><button class="game-reset" @click="resetGame"><RotateCcw :size="15" /> Ulangi</button></div>
      </BaseCard>
      <p class="games-note">Game harian berganti otomatis. Tidak ada penalti jika kamu melewatkan permainan. Hadiah dibatasi agar saldo T-Money tetap seimbang.</p>
    </div>
  </PagePlaceholder>
</template>

<style scoped>
.games-layout{display:flex;flex-direction:column;gap:16px}.games-intro{display:flex;gap:14px;align-items:center;background:linear-gradient(120deg,#fff5e8,#fff0f3)}.games-intro__icon{width:46px;height:46px;display:grid;place-items:center;border-radius:15px;background:white;color:#bf7730;flex-shrink:0}.games-intro h2{font-size:17px;margin-bottom:4px}.games-intro p,.games-note{font-size:13px;color:var(--c-text-muted);line-height:1.5}.game-tabs{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:9px}.game-tabs button{position:relative;text-align:left;display:flex;flex-direction:column;gap:5px;min-height:88px;padding:12px;border:1px solid var(--c-border);border-radius:15px;background:white}.game-tabs button.active{border-color:var(--c-primary);background:var(--c-blue-soft)}.game-tabs strong{font-size:13px}.game-tabs small{font-size:11px;color:var(--c-text-muted);line-height:1.35}.game-tabs svg{position:absolute;right:9px;top:9px;color:#24935c}.game-stage{display:flex;flex-direction:column;gap:16px;min-height:280px}.game-stage__top{display:flex;justify-content:space-between;align-items:center}.game-kicker{font-size:10px;font-weight:800;letter-spacing:.1em;color:var(--c-primary)}.game-reward{display:flex;align-items:center;gap:5px;color:#a76b1f;background:#fff6e6;border-radius:20px;padding:6px 9px;font-size:11px;font-weight:800}.game-stage h2{font-size:20px;line-height:1.35}.game-options{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.game-options button{padding:14px;border:1px solid var(--c-border);border-radius:13px;background:var(--c-gray);font-weight:700;text-align:left}.game-options button.chosen{border-color:var(--c-primary);background:var(--c-blue-soft);color:var(--c-primary)}.game-options--two button{text-align:center}.scrambled-word{font-size:25px;letter-spacing:.22em;font-weight:900;text-align:center;padding:20px;background:var(--c-gray);border-radius:15px}.game-hint{font-size:13px;color:var(--c-text-muted)}.game-answer{height:46px;border:1px solid var(--c-border);border-radius:12px;padding:0 13px;background:var(--c-gray);max-width:360px}.wordle-slots{display:flex;gap:8px}.wordle-slots span{width:42px;height:46px;border:1px solid var(--c-border);border-radius:10px;display:grid;place-items:center;font-size:20px;font-weight:800;background:var(--c-gray)}.game-actions{display:flex;gap:10px;align-items:center}.game-submit{border:0;background:var(--c-primary);color:white;border-radius:12px;padding:12px 18px;font-weight:800}.game-submit:disabled{opacity:.55}.game-reset{display:flex;gap:6px;align-items:center;border:1px solid var(--c-border);background:white;border-radius:12px;padding:11px 13px;font-weight:700}.game-feedback{display:flex;gap:7px;flex-wrap:wrap;align-items:center;color:#218653;font-size:13px}.game-feedback span{width:100%;color:var(--c-text-muted)}.game-error{color:var(--c-danger);font-size:13px}@media(max-width:680px){.game-tabs{grid-template-columns:repeat(2,minmax(0,1fr))}.game-options{grid-template-columns:1fr}}
</style>
