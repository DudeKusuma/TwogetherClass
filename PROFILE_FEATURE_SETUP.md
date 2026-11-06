# Twogether Class — Student Profile

Patch ini menambahkan halaman profil siswa dan modal profil yang bisa dibuka dari nama siswa di halaman Uang Kas dan Iuran Kelas.

## Isi patch

- `frontend/src/views/ProfileView.vue` — halaman edit profil siswa.
- `frontend/src/components/shared/StudentProfileModal.vue` — modal profil siswa di tengah layar.
- `frontend/src/views/CashView.vue` — nama siswa yang terhubung ke akun dapat diklik untuk membuka profil.
- `frontend/src/views/ContributionsView.vue` — nama siswa yang terhubung ke akun dapat diklik untuk membuka profil.
- `frontend/src/stores/useAuthStore.js` — memakai nama pendek profil sebagai nama tampilan setelah login.
- `supabase/migrations/20261112_student_profiles.sql` — tabel profil, kebijakan akses, dan RPC aman untuk data profil.

## Cara memasang

1. Buat salinan/backup folder project terlebih dahulu.
2. Ekstrak ZIP patch ini.
3. Salin folder `frontend` dan `supabase` dari patch ke folder project Twogether Class, lalu izinkan file yang sama diganti.
4. Buka Supabase Dashboard → SQL Editor.
5. Pastikan project Supabase yang dipilih benar, lalu jalankan seluruh isi file:
   `supabase/migrations/20261112_student_profiles.sql`
6. Di folder `frontend`, jalankan:
   `npm run build`
7. Jika build berhasil, jalankan `npm run dev` dan uji dengan akun siswa serta admin.

## Cara kerja dan privasi

- Nama lengkap, NISN, dan nomor absen bersumber dari `class_roster`, bukan dari input edit siswa.
- Nama pendek, tempat/tanggal lahir, jenis kelamin, alamat, hobi, dan pilihan About Me disimpan di `student_profile_details`.
- NISN tidak dikirim oleh RPC profil ke siswa lain kecuali pemilik profil mengaktifkan “Tampilkan NISN ke siswa lain”. Pemilik dan admin tetap dapat melihat NISN.
- Akses langsung ke `class_roster` juga dibatasi: siswa hanya dapat membaca baris roster miliknya sendiri. Daftar nama teman sekelas di UI memakai RPC `get_class_roster_public()` yang tidak mengirim NISN teman yang belum mengaktifkannya.
- Kebijakan RLS membatasi akses langsung ke tabel detail profil. Siswa hanya dapat mengubah baris profilnya sendiri; admin dapat mengelola semua.
- Nama siswa yang belum terhubung ke `class_roster.profile_id` tidak bisa membuka modal profil sampai admin menghubungkan akunnya.
- Tidak ada upload foto/avatar pada patch ini; avatar memakai inisial nama.
- Hobi dan About Me menggunakan pilihan template emoji, bukan input bebas.

## Pengujian yang disarankan

1. Login sebagai siswa A, isi profil, simpan, refresh, dan pastikan data tetap ada.
2. Login sebagai siswa B, buka Uang Kas atau Iuran Kelas, klik nama siswa A.
3. Pastikan NISN siswa A tidak terlihat jika pengaturan NISN dimatikan.
4. Login sebagai siswa A, aktifkan pengaturan NISN, simpan. Login kembali sebagai siswa B dan pastikan NISN A terlihat.
5. Login sebagai admin dan pastikan admin tetap dapat melihat NISN meskipun pengaturan siswa dimatikan.
6. Uji nama siswa yang belum terhubung ke akun: tombol profil seharusnya nonaktif.
