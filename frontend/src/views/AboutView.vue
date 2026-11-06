<script setup>
import logo from '@/assets/icons/logo XI B2.jpeg'
import BaseCard from '@/components/base/BaseCard.vue'
</script>

<template>
  <div class="about" data-testid="about-page">
    <header class="page-head">
      <span class="page-head__eyebrow">Tentang</span>
      <h1 class="page-head__title">Tentang Twogether Class</h1>
    </header>

    <BaseCard class="about__card">
      <img :src="logo" alt="Logo Twogether Class" class="about__logo" data-testid="about-logo" />
      <div class="about__text">
        <p>
          <b>Twogether Class</b> adalah portal kelas digital untuk kelas <b>XI-B2, SMA Negeri 1 Gianyar</b>. Portal ini menjadi
          ruang bersama bagi siswa dan admin kelas untuk melihat jadwal pelajaran, membaca pengumuman, dan nantinya mengelola
          tugas, kalender, serta presensi.
        </p>
        <p class="about__note">
          Versi ini adalah prototipe. Data disimpan di browser perangkat yang digunakan dan tidak tersinkron antarperangkat.
        </p>
      </div>
    </BaseCard>

    <div class="about__tiles">
      <BaseCard tone="blue"><h2>Jadwal</h2><p>Mata pelajaran dan linimasa jadwal kelas setiap hari sekolah.</p></BaseCard>
      <BaseCard tone="yellow"><h2>Pengumuman</h2><p>Informasi kelas dari admin langsung di lonceng notifikasi.</p></BaseCard>
      <BaseCard tone="mint"><h2>Segera hadir</h2><p>Kalender bersama, tugas, dan presensi kelas.</p></BaseCard>
    </div>
  </div>
</template>

<style scoped>
.about__card {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

@media (min-width: 768px) {
  .about__card {
    flex-direction: row;
    align-items: center;
  }
}

.about__logo {
  width: 120px;
  height: 120px;
  border-radius: 28px;
  object-fit: cover;
  flex-shrink: 0;
}

.about__text {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  font-size: 15px;
}

.about__note {
  font-size: 13px;
  color: var(--c-text-muted);
}

.about__tiles {
  margin-top: var(--space-4);
  display: grid;
  gap: var(--space-3);
}

@media (min-width: 768px) {
  .about__tiles {
    grid-template-columns: repeat(3, 1fr);
  }
}

.about__tiles h2 {
  font-size: 15px;
  font-weight: 800;
  margin-bottom: 4px;
}

.about__tiles p {
  font-size: 13px;
  color: var(--c-text-muted);
}
</style>
