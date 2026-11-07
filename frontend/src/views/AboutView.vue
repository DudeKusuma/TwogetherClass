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
          <b>Twogether Class</b> merupakan website yang dibuat untuk keluarga besar kelas <b>B2 angkatan 62, SMA Negeri 1 Gianyar</b>.
          Website ini hadir sebagai ruang digital untuk membantu kegiatan kelas, berbagi informasi, serta membangun hubungan yang lebih dekat antarsiswa.
        </p>
      </div>
    </BaseCard>


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
