# Twogether Class — Revisi Daily Spotlight & Main Menu

Tanggal revisi: 15 November 2026

## Perubahan yang diminta

### 1. Satu konten harian di homepage
- Homepage hanya menampilkan satu Daily Spotlight kecil di bagian atas.
- Setiap tanggal Bali (Asia/Makassar), sistem memilih tepat satu jenis konten dari kumpulan template.
- Semua siswa mendapatkan jenis dan prompt yang sama pada tanggal yang sama.
- Pemilihan dibuat stabil sepanjang hari, bukan berubah setiap kali halaman dibuka.
- Jenis konten: Random Question, Announcement, Fun Fact, Daily Event, Class Poll, atau This or That.
- Tidak ada dua jenis konten harian yang muncul bersamaan.
- Tidak ada halaman detail Daily Discovery/Events; `/daily` diarahkan kembali ke homepage.
- Daily Discovery dan Shared Interest tidak ditampilkan pada homepage.

### 2. Respons siswa
- Untuk pertanyaan/event, siswa dapat mengirim satu respons.
- Untuk polling/This or That, siswa memilih satu opsi.
- Respons pertanyaan/event dapat disimpan pribadi atau diajukan anonim/dengan nickname untuk moderasi.
- Migration tambahan membuat database menolak respons kedua dari siswa yang sama pada tanggal Bali yang sama, walaupun jenis kontennya berbeda.
- Announcement dan Fun Fact bersifat informatif dan tidak meminta respons.

### 3. Menu dan profil
- Games dan T-Money & Reward Shop berada di Main Menu (drawer), bukan homepage.
- Tombol/panduan instalasi aplikasi berada di Main Menu, bukan homepage.
- Saldo T-Money ditampilkan pada kartu identitas di halaman Profil Saya.
- Shop dan Games tetap dapat dibuka melalui menu.

### 4. Halaman utama
Homepage kini menampilkan:
- Greeting.
- Satu Daily Spotlight.
- Kartu mata pelajaran.
- Jadwal.

T-Money card, shortcut Games/Shop, Daily Discovery, dan Install App Card dihapus dari homepage.

## Kumpulan template
- Random Question: 20.
- Announcement: 30.
- Daily Event: 20.
- Class Poll: 15.
- This or That: 15.
- Fun Fact: 30.

## Migration database
Jalankan migration baru:
`supabase/migrations/20261115_one_daily_spotlight_response.sql`

Migration ini tidak menghapus riwayat respons. Trigger baru menolak respons kedua pada hari yang sama.

## Catatan pengujian
- JavaScript di script blocks komponen yang diubah diperiksa menggunakan `node --check` dan lolos.
- Production build belum dapat diverifikasi pada lingkungan ini karena `npm ci` tidak selesai dalam batas waktu dan executable Vite belum tersedia. Jalankan `npm install` lalu `npm run build` di komputer proyek sebelum deployment.
- Migration SQL belum dijalankan pada Supabase pengguna; harus diterapkan sebelum fitur one-response-per-day aktif di backend.
- Belum dilakukan pengujian end-to-end dengan akun siswa nyata.
