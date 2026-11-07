<script setup>
import { onMounted, ref } from 'vue'
import { Coins, ArrowUpRight } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import { supabase } from '@/lib/supabase'
const balance = ref(0)
const loading = ref(true)
const available = ref(true)
onMounted(async () => {
  const { data, error } = await supabase.rpc('get_my_t_money')
  available.value = !error
  balance.value = data?.balance ?? 0
  loading.value = false
})
</script>
<template>
  <RouterLink to="/shop" class="tmoney-card"><span class="tmoney-icon"><Coins :size="19"/></span><span class="tmoney-text"><small>TOGETHER MONEY</small><strong>{{ loading || !available ? '—' : balance.toLocaleString('id-ID') }} T-Money</strong></span><span class="tmoney-link">Reward Shop <ArrowUpRight :size="15"/></span></RouterLink>
</template>
<style scoped>
.tmoney-card{display:flex;align-items:center;gap:11px;padding:13px 15px;border-radius:16px;background:linear-gradient(110deg,#fff8e7,#fff1d5);border:1px solid #f3e2b7}.tmoney-icon{width:38px;height:38px;border-radius:12px;background:white;color:#a87518;display:grid;place-items:center}.tmoney-text{display:flex;flex-direction:column;gap:2px;flex:1}.tmoney-text small{font-size:9px;letter-spacing:.1em;font-weight:900;color:#9a752b}.tmoney-text strong{font-size:14px;color:#614916}.tmoney-link{display:flex;align-items:center;gap:4px;font-size:11px;font-weight:800;color:#9a752b}
</style>
