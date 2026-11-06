<script setup>
import { UserCheck } from 'lucide-vue-next'
import PagePlaceholder from '@/components/shared/PagePlaceholder.vue'

const planned = ['Denah tempat duduk 43 siswa', 'Status kehadiran', 'Kontrol admin', 'Pengelolaan presensi seluruh kelas']
</script>

<template>
  <PagePlaceholder
    eyebrow="Presensi"
    title="Presensi Kelas"
    description="Pantau kehadiran XI-B2 dari satu tempat."
    :icon="UserCheck"
    tone="mint"
    :planned="planned"
    test-id="attendance-page"
  />
</template>
