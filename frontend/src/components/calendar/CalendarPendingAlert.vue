<script setup>
import { onMounted, onUnmounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { AlertCircle } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/useAuthStore'

const auth = useAuthStore()
const router = useRouter()
const pendingCount = ref(0)
let channel

async function refreshCount() {
  if (!auth.isAdmin || !supabase) { pendingCount.value = 0; return }
  const { count, error } = await supabase.from('calendar_requests').select('id', { count: 'exact', head: true }).eq('status', 'pending')
  if (!error) pendingCount.value = count || 0
}
function openRequests() {
  router.push({ name: 'schedule', query: { requests: '1' } })
}
watch(() => auth.isAdmin, async (isAdmin) => {
  if (isAdmin) await refreshCount()
  else pendingCount.value = 0
}, { immediate: true })
onMounted(() => {
  if (!supabase) return
  channel = supabase.channel('calendar-pending-alert')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'calendar_requests' }, refreshCount)
    .subscribe()
})
onUnmounted(() => { if (channel && supabase) supabase.removeChannel(channel) })
</script>

<template>
  <button v-if="auth.isAdmin" class="pending-alert" type="button" aria-label="Buka pengajuan kalender" @click="openRequests">
    <AlertCircle :size="21" />
    <span v-if="pendingCount" class="pending-alert__dot">{{ pendingCount > 9 ? '9+' : pendingCount }}</span>
  </button>
</template>

<style scoped>
.pending-alert { position:fixed; z-index:70; left:18px; bottom:calc(var(--nav-h) + 28px + env(safe-area-inset-bottom)); width:44px; height:44px; display:grid; place-items:center; border:1px solid var(--c-border); border-radius:50%; background:#fff; color:var(--c-text); box-shadow:var(--shadow-md); }
.pending-alert__dot { position:absolute; top:-5px; right:-5px; min-width:19px; height:19px; padding:0 4px; display:grid; place-items:center; border-radius:99px; color:#fff; background:#e5484d; font-size:10px; font-weight:800; border:2px solid white; }
@media (min-width:1024px) { .pending-alert { left:calc(var(--rail-w) + 18px); bottom:24px; } }
</style>
