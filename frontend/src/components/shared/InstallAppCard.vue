<script setup>
import { computed, onMounted, ref } from 'vue'
import { Download, Smartphone, Monitor, Share2 } from 'lucide-vue-next'
const promptEvent = ref(null)
const installed = ref(false)
const ios = ref(false)
const instructionsOpen = ref(false)
const isStandalone = () => window.matchMedia?.('(display-mode: standalone)').matches || window.navigator.standalone === true
const platformLabel = computed(() => ios.value ? 'iPhone / iPad' : 'Android atau Desktop')
onMounted(() => {
  installed.value = isStandalone()
  ios.value = /iphone|ipad|ipod/i.test(navigator.userAgent)
  window.addEventListener('beforeinstallprompt', (event) => { event.preventDefault(); promptEvent.value = event })
  window.addEventListener('appinstalled', () => { installed.value = true; promptEvent.value = null })
})
async function install() {
  if (!promptEvent.value) { instructionsOpen.value = !instructionsOpen.value; return }
  await promptEvent.value.prompt()
  await promptEvent.value.userChoice
  promptEvent.value = null
}
</script>

<template>
  <section class="install-card">
    <div class="install-icon"><Download :size="21" /></div>
    <div class="install-copy"><strong>{{ installed ? 'Twogether Class sudah terpasang' : 'Pasang Twogether Class' }}</strong><p>{{ installed ? 'Buka website dari layar utama atau daftar aplikasi.' : 'Tambahkan ke layar utama agar lebih mudah dibuka seperti aplikasi.' }}</p></div>
    <button v-if="!installed" class="install-action" @click="install">{{ promptEvent ? 'Instal' : 'Cara instal' }}</button>
    <div v-if="instructionsOpen && !installed" class="install-instructions">
      <template v-if="ios"><b><Share2 :size="15" /> Untuk {{ platformLabel }}</b><p>1. Buka Twogether Class melalui Safari.<br/>2. Tekan tombol Share / Bagikan.<br/>3. Pilih “Add to Home Screen” / “Tambahkan ke Layar Utama”.<br/>4. Tekan Add / Tambahkan.</p></template>
      <template v-else><b><Smartphone :size="15" /> Android</b><p>Buka menu browser lalu pilih “Install app” atau “Add to Home screen”.</p><b><Monitor :size="15" /> Desktop Chrome / Edge</b><p>Gunakan ikon instalasi di address bar atau menu browser → Install Twogether Class.</p></template>
      <small>Nama menu dapat berbeda tergantung browser dan perangkat.</small>
    </div>
  </section>
</template>

<style scoped>
.install-card{display:flex;align-items:center;gap:12px;padding:15px;border:1px solid var(--c-border);border-radius:18px;background:white;flex-wrap:wrap}.install-icon{width:42px;height:42px;border-radius:14px;background:var(--c-blue-soft);color:var(--c-primary);display:grid;place-items:center;flex-shrink:0}.install-copy{flex:1;min-width:150px}.install-copy strong{font-size:13px}.install-copy p{font-size:11px;color:var(--c-text-muted);margin-top:3px;line-height:1.4}.install-action{border:0;border-radius:11px;padding:10px 13px;background:var(--c-primary);color:white;font-size:12px;font-weight:800}.install-instructions{width:100%;padding:12px;border-radius:12px;background:var(--c-gray);font-size:12px;color:var(--c-text-muted);line-height:1.6}.install-instructions b{display:flex;align-items:center;gap:6px;color:var(--c-text);margin:5px 0}.install-instructions p{margin:3px 0 10px}.install-instructions small{font-size:10px}
</style>
