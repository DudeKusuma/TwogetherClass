<script setup>
import { onMounted, ref } from 'vue'
import { ShieldCheck, Check, X } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import AdminBackLink from '@/components/admin/AdminBackLink.vue'
import BaseCard from '@/components/base/BaseCard.vue'
const rows = ref([])
const loading = ref(true)
const error = ref('')
const notice = ref('')
async function load() {
  loading.value = true
  const { data, error: e } = await supabase.from('daily_interactions').select('id,content_type,prompt,response,visibility,created_at,user_id,sender:profiles!daily_interactions_user_id_fkey(display_name)').eq('status','pending').order('created_at',{ascending:false})
  if (e) error.value = 'Belum dapat memuat jawaban. Pastikan migration komunitas sudah dijalankan.'
  else rows.value = data || []
  loading.value = false
}
async function moderate(row, status) {
  error.value = ''; notice.value = ''
  const { error: e } = await supabase.from('daily_interactions').update({ status }).eq('id',row.id)
  if (e) error.value = 'Status jawaban belum berhasil diperbarui.'
  else { notice.value = status === 'approved' ? 'Jawaban disetujui.' : 'Jawaban ditolak.'; await load() }
}
onMounted(load)
</script>
<template>
  <div class="moderation-page"><AdminBackLink /><header class="page-head"><span class="page-head__eyebrow">Admin Power</span><h1 class="page-head__title">Moderasi Daily Responses</h1><p class="page-head__desc">Tinjau jawaban yang diajukan untuk ditampilkan secara anonim atau dengan nickname. Jawaban pribadi tidak muncul di sini.</p></header>
    <p v-if="error" class="moderation-error">{{ error }}</p><p v-if="notice" class="moderation-notice">{{ notice }}</p><p v-if="loading" class="moderation-muted">Memuat jawaban...</p><p v-else-if="!rows.length" class="moderation-muted">Tidak ada jawaban yang menunggu moderasi.</p>
    <div v-else class="moderation-list"><BaseCard v-for="row in rows" :key="row.id" class="moderation-card"><div class="moderation-meta"><strong>{{ row.content_type.replaceAll('_',' ') }}</strong><span>{{ row.visibility === 'anonymous' ? 'Anonim' : 'Dengan nickname' }}</span></div><p class="moderation-prompt">{{ row.prompt }}</p><p class="moderation-response">{{ row.response }}</p><small>Pengirim: {{ row.sender?.display_name || 'Siswa' }} · {{ new Date(row.created_at).toLocaleString('id-ID') }}</small><div class="moderation-actions"><button class="approve" @click="moderate(row,'approved')"><Check :size="15"/> Setujui</button><button class="reject" @click="moderate(row,'rejected')"><X :size="15"/> Tolak</button></div></BaseCard></div>
  </div>
</template>
<style scoped>
.moderation-page{display:flex;flex-direction:column;gap:14px}.moderation-list{display:grid;gap:12px}.moderation-card{display:grid;gap:9px}.moderation-meta{display:flex;justify-content:space-between;gap:10px;font-size:11px;text-transform:capitalize}.moderation-meta span{color:var(--c-text-muted)}.moderation-prompt{font-size:12px;color:var(--c-text-muted)}.moderation-response{font-size:14px;line-height:1.5}.moderation-card small,.moderation-muted{font-size:11px;color:var(--c-text-muted)}.moderation-actions{display:flex;gap:8px}.moderation-actions button{display:flex;align-items:center;gap:5px;padding:8px 11px;border:0;border-radius:10px;font-size:12px;font-weight:800}.approve{background:var(--c-mint);color:#167b48}.reject{background:var(--c-pink);color:#b42b36}.moderation-error{font-size:12px;color:var(--c-danger)}.moderation-notice{font-size:12px;color:#167b48}
</style>
