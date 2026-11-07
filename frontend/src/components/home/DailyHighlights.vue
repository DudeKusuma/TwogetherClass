<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { Sparkles, UsersRound, ArrowRight } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { dailyQuestions, dailyIndex } from '@/data/dailyContent'
const students = ref([])
const question = computed(() => dailyQuestions[dailyIndex(dailyQuestions.length)])
const featured = computed(() => students.value.find(s => s.hobbies?.length) || null)
const shared = computed(() => {
  const map = new Map()
  for (const student of students.value) for (const hobby of student.hobbies || []) {
    if (!map.has(hobby)) map.set(hobby, [])
    map.get(hobby).push(student.display_name)
  }
  return [...map.entries()].filter(([,names]) => names.length >= 2).sort((a,b) => b[1].length-a[1].length)[0] || null
})
onMounted(async () => { const { data, error } = await supabase.rpc('get_discover_students'); if (!error) students.value = data || [] })
</script>
<template>
  <section class="daily-highlights">
    <div class="highlight-head"><div><span class="highlight-kicker">TODAY IN OUR CLASS</span><h2>Daily Discovery</h2></div><RouterLink to="/daily">Lihat semua <ArrowRight :size="14"/></RouterLink></div>
    <div class="highlight-grid">
      <article v-if="featured" class="highlight-card"><span class="highlight-icon"><Sparkles :size="17"/></span><div><small>DID YOU KNOW?</small><p><b>{{ featured.display_name }}</b> suka {{ featured.hobbies[0] }}.</p></div></article>
      <article v-if="shared" class="highlight-card"><span class="highlight-icon highlight-icon--mint"><UsersRound :size="17"/></span><div><small>SHARED INTEREST</small><p><b>{{ shared[0] }}</b> disukai {{ shared[1].length }} siswa yang berbagi profil.</p></div></article>
      <article class="highlight-card highlight-card--question"><span class="highlight-icon"><Sparkles :size="17"/></span><div><small>RANDOM QUESTION</small><p>{{ question }}</p></div></article>
    </div>
  </section>
</template>
<style scoped>
.daily-highlights{display:flex;flex-direction:column;gap:11px}.highlight-head{display:flex;align-items:flex-end;justify-content:space-between;gap:12px}.highlight-kicker{font-size:9px;letter-spacing:.1em;font-weight:900;color:var(--c-primary)}.highlight-head h2{font-size:18px;margin-top:3px}.highlight-head>a{display:flex;align-items:center;gap:4px;font-size:11px;font-weight:800;color:var(--c-primary)}.highlight-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.highlight-card{display:flex;align-items:flex-start;gap:10px;padding:13px;border:1px solid var(--c-border);border-radius:15px;background:white;min-width:0}.highlight-icon{width:34px;height:34px;border-radius:11px;display:grid;place-items:center;background:var(--c-blue-soft);color:var(--c-primary);flex-shrink:0}.highlight-icon--mint{background:var(--c-mint);color:#248653}.highlight-card small{font-size:9px;font-weight:900;letter-spacing:.08em;color:var(--c-text-muted)}.highlight-card p{font-size:12px;line-height:1.45;margin-top:4px}.highlight-card--question{grid-column:span 2;background:#fbfaff}@media(max-width:560px){.highlight-grid{grid-template-columns:1fr}.highlight-card--question{grid-column:auto}}
</style>
