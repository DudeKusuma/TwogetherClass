<script setup>
import { RouterLink } from 'vue-router'
import { Megaphone, CalendarClock, BookOpenText, ChevronRight, Wallet, HandCoins, ListTodo, Users, ShieldCheck } from 'lucide-vue-next'
import { useAnnouncementStore } from '@/stores/useAnnouncementStore'
import { useSubjectStore } from '@/stores/useSubjectStore'

const announcements = useAnnouncementStore()
const subjects = useSubjectStore()

const features = [
  { to: '/admin-power/daily-moderation', id: 'daily-moderation', title: 'Moderasi Daily Responses', desc: 'Tinjau jawaban Random Question sebelum ditampilkan ke kelas.', icon: ShieldCheck, tone: 'mint', stat: () => 'Privasi dan moderasi' },
  { to: '/admin-power/student-accounts', id: 'student-accounts', title: 'Akun Siswa', desc: 'Buat username dan password untuk seluruh siswa XI-B2.', icon: Users, tone: 'mint', stat: () => '43 akun siswa' },
  {
    to: '/admin-power/announcements',
    id: 'announcements',
    title: 'Pengumuman',
    desc: 'Buat, ubah, aktifkan, atau hapus pengumuman kelas.',
    icon: Megaphone,
    tone: 'yellow',
    stat: () => `${announcements.active.length} aktif · ${announcements.items.length} total`
  },
  {
    to: '/admin-power/tomorrow',
    id: 'tomorrow',
    title: 'Jadwal Besok',
    desc: 'Catat tugas, kuis, ulangan, dan info lain untuk hari sekolah berikutnya.',
    icon: CalendarClock,
    tone: 'blue',
    stat: () => `${subjects.activities.length} aktivitas tercatat`
  },
  { to: '/tasks', id: 'tasks', title: 'Daftar Tugas', desc: 'Tambah tugas kelas dan tinjau pengajuan siswa.', icon: ListTodo, tone: 'blue', stat: () => 'Tugas seluruh mapel' },
  { to: '/cash', id: 'cash', title: 'Uang Kas', desc: 'Verifikasi pembayaran, catat pengeluaran, dan pantau saldo kas.', icon: Wallet, tone: 'mint', stat: () => 'Keuangan kelas' },
  { to: '/contributions', id: 'contributions', title: 'Iuran Kelas', desc: 'Buat iuran khusus dan verifikasi pembayaran siswa.', icon: HandCoins, tone: 'yellow', stat: () => 'Iuran aktif dan riwayat' },
  {
    to: '/admin-power/descriptions',
    id: 'descriptions',
    title: 'Deskripsi Mapel',
    desc: 'Tulis deskripsi tiap mata pelajaran yang tampil di detail kartu.',
    icon: BookOpenText,
    tone: 'mint',
    stat: () => `${Object.keys(subjects.descriptions).length} dari 13 terisi`
  }
]
</script>

<template>
  <div class="admin-home" data-testid="admin-power-page">
    <header class="page-head">
      <span class="page-head__eyebrow">Admin Power</span>
      <h1 class="page-head__title">Panel Admin</h1>
      <p class="page-head__desc">Pilih fitur yang ingin dikelola. Kelola fitur kelas, persetujuan, dan informasi bersama.</p>
    </header>

    <div class="admin-home__grid">
      <RouterLink
        v-for="f in features"
        :key="f.id"
        :to="f.to"
        class="feature"
        :data-testid="`admin-feature-${f.id}`"
      >
        <span class="feature__icon" :class="`feature__icon--${f.tone}`"><component :is="f.icon" :size="24" /></span>
        <span class="feature__text">
          <span class="feature__title">{{ f.title }}</span>
          <span class="feature__desc">{{ f.desc }}</span>
          <span class="feature__stat">{{ f.stat() }}</span>
        </span>
        <ChevronRight :size="20" class="feature__chev" />
      </RouterLink>
    </div>
  </div>
</template>

<style scoped>
.admin-home__grid {
  display: grid;
  gap: var(--space-3);
}

@media (min-width: 768px) {
  .admin-home__grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--space-4);
  }
}

@media (min-width: 1024px) {
  .admin-home__grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

.feature {
  display: flex;
  align-items: flex-start;
  gap: var(--space-4);
  padding: var(--space-5);
  border-radius: var(--radius-lg);
  background: var(--c-white);
  border: 1px solid var(--c-border);
  box-shadow: var(--shadow-sm);
  transition: transform 0.2s var(--ease), box-shadow 0.2s ease;
}

.feature:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.feature__icon {
  width: 52px;
  height: 52px;
  border-radius: 16px;
  display: grid;
  place-items: center;
  flex-shrink: 0;
}

.feature__icon--yellow { background: var(--c-yellow); color: #a17a10; }
.feature__icon--blue { background: var(--c-blue-soft); color: var(--c-primary); }
.feature__icon--mint { background: var(--c-mint); color: #1f8a56; }

.feature__text {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
  flex: 1;
}

.feature__title {
  font-size: 16px;
  font-weight: 800;
}

.feature__desc {
  font-size: 13px;
  color: var(--c-text-muted);
}

.feature__stat {
  margin-top: 6px;
  font-size: 12px;
  font-weight: 700;
  color: var(--c-primary);
}

.feature__chev {
  color: var(--c-text-soft);
  flex-shrink: 0;
  align-self: center;
}
</style>
