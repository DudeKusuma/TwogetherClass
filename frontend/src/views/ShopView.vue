<script setup>
import { onMounted, ref } from 'vue'
import { ShoppingBag, Coins, CheckCircle2, Palette } from 'lucide-vue-next'
import PagePlaceholder from '@/components/shared/PagePlaceholder.vue'
import BaseCard from '@/components/base/BaseCard.vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/useAuthStore'

const auth = useAuthStore()
const wallet = ref(0)
const items = ref([])
const owned = ref([])
const equipped = ref({})
const loading = ref(true)
const busyId = ref('')
const message = ref('')
const error = ref('')
async function loadShop() {
  loading.value = true; error.value = ''
  const [w, catalog, inventory, cosmetics] = await Promise.all([
    supabase.rpc('get_my_t_money'),
    supabase.from('shop_catalog').select('*').eq('active', true).order('price'),
    supabase.from('shop_purchases').select('item_id').eq('user_id', auth.user.id),
    supabase.from('student_cosmetics').select('profile_color,name_color,title_color').eq('profile_id', auth.user.id).maybeSingle()
  ])
  if (w.error || catalog.error || inventory.error) error.value = 'Shop belum siap. Admin perlu menjalankan migration Reward & Shop di Supabase.'
  wallet.value = w.data?.balance ?? 0
  items.value = catalog.data || []
  owned.value = (inventory.data || []).map(x => x.item_id)
  equipped.value = cosmetics.data || {}
  loading.value = false
}
function isEquipped(item) { const key = item.category === 'profile_color' ? 'profile_color' : item.category === 'name_color' ? 'name_color' : 'title_color'; const value = item.category === 'profile_color' ? item.preview_color : item.text_color; return equipped.value[key] === value }
async function equip(item) {
  message.value = ''; error.value = ''; busyId.value = item.id
  const { data, error: e } = await supabase.rpc('equip_shop_item', { p_item_id: item.id })
  if (e) error.value = 'Kosmetik belum berhasil dipasang.'
  else { message.value = data?.message || 'Kosmetik berhasil dipasang.'; await loadShop() }
  busyId.value = ''
}
async function purchase(item) {
  message.value = ''; error.value = ''; busyId.value = item.id
  const { data, error: e } = await supabase.rpc('purchase_shop_item', { p_item_id: item.id })
  if (e) error.value = 'Pembelian belum berhasil. Periksa migration dan saldo T-Money.'
  else { message.value = data?.message || 'Item berhasil dibeli dan dipasang.'; await loadShop() }
  busyId.value = ''
}
onMounted(loadShop)
</script>

<template>
  <PagePlaceholder eyebrow="Together Rewards" title="Reward Shop" :icon="ShoppingBag" tone="lavender" test-id="shop-page">
    <div class="shop-layout">
      <BaseCard class="wallet-card"><div><span class="wallet-label">SALDO T-MONEY</span><strong>{{ wallet.toLocaleString('id-ID') }}</strong><small>T-Money digunakan untuk item kosmetik profil.</small></div><span class="wallet-icon"><Coins :size="24" /></span></BaseCard>
      <div class="shop-intro"><Palette :size="17" /><span>Mulai dari koleksi kecil. Item kosmetik tidak memberikan keuntungan akademik atau keunggulan permainan.</span></div>
      <p v-if="loading" class="shop-muted">Memuat Reward Shop...</p>
      <p v-else-if="error" class="shop-error">{{ error }}</p>
      <div v-else class="shop-grid">
        <BaseCard v-for="item in items" :key="item.id" class="shop-item">
          <div class="item-preview" :style="{ background: item.preview_color || '#eef2ff' }"><span :style="{ color: item.text_color || '#3154a4' }">{{ item.preview_label || 'Aa' }}</span></div>
          <div class="item-info"><span class="item-category">{{ item.category }}</span><h2>{{ item.name }}</h2><p>{{ item.description }}</p></div>
          <div class="item-footer"><strong><Coins :size="15" /> {{ item.price }} T-Money</strong><button v-if="owned.includes(item.id)" :disabled="busyId === item.id || isEquipped(item)" @click="equip(item)">{{ isEquipped(item) ? 'Dipakai' : 'Pakai' }}</button><button v-else :disabled="busyId === item.id" @click="purchase(item)">Beli</button></div>
        </BaseCard>
      </div>
      <p v-if="message" class="shop-success"><CheckCircle2 :size="16" /> {{ message }}</p>
      <BaseCard class="shop-note"><strong>Catatan T-Money</strong><p>T-Money diperoleh dari partisipasi dan game yang selesai. Hadiah dibatasi per aktivitas dan per hari agar saldo tetap seimbang. Pembelian kosmetik tidak dapat ditukar kembali menjadi T-Money.</p></BaseCard>
    </div>
  </PagePlaceholder>
</template>

<style scoped>
.shop-layout{display:flex;flex-direction:column;gap:16px}.wallet-card{display:flex;justify-content:space-between;align-items:center;background:linear-gradient(120deg,#f4efff,#fff6e8)}.wallet-label{display:block;font-size:10px;letter-spacing:.1em;font-weight:800;color:#7153b6}.wallet-card strong{display:block;font-size:30px;line-height:1.25;margin:3px 0}.wallet-card small{font-size:12px;color:var(--c-text-muted)}.wallet-icon{width:50px;height:50px;display:grid;place-items:center;background:white;border-radius:16px;color:#a27620}.shop-intro{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--c-text-muted)}.shop-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:13px}.shop-item{display:flex;flex-direction:column;gap:12px}.item-preview{height:112px;border-radius:14px;display:grid;place-items:center;overflow:hidden}.item-preview span{font-size:32px;font-weight:900;letter-spacing:-.05em}.item-category{font-size:10px;text-transform:uppercase;letter-spacing:.08em;color:var(--c-primary);font-weight:800}.item-info h2{font-size:16px;margin:4px 0}.item-info p{font-size:12px;color:var(--c-text-muted);line-height:1.45;min-height:36px}.item-footer{display:flex;justify-content:space-between;align-items:center;gap:8px;margin-top:auto}.item-footer strong{display:flex;align-items:center;gap:4px;font-size:12px;color:#a27620;white-space:nowrap}.item-footer button{border:0;border-radius:10px;padding:8px 13px;background:var(--c-primary);color:white;font-size:12px;font-weight:800}.item-footer button:disabled{background:#e9edf3;color:#758093}.shop-note p,.shop-muted{font-size:13px;color:var(--c-text-muted);line-height:1.5}.shop-note strong{font-size:14px}.shop-error{font-size:13px;color:var(--c-danger)}.shop-success{display:flex;align-items:center;gap:7px;color:#218653;font-size:13px}@media(max-width:760px){.shop-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:460px){.shop-grid{grid-template-columns:1fr}.item-preview{height:90px}}
</style>
