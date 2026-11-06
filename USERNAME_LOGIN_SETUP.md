# Username login XI-B2

Perubahan ini menambahkan login siswa memakai `siswa01` sampai `siswa43` tanpa meminta siswa mempunyai Gmail. Supabase Auth tetap dipakai; di belakang layar setiap username dipetakan ke alamat internal `@twogetherclass.invalid`. Alamat ini bukan kotak email dan tidak dipakai untuk mengirim email.

## File yang berubah

- Login menerima username siswa atau email admin lama.
- Profil menyimpan `username` dan `attendance_number`.
- Halaman Admin Power memiliki menu **Akun Siswa**.
- Edge Function membuat akun dari `class_roster`, membuat password sementara acak, lalu menautkan Auth user, `profiles`, dan `class_roster`.
- Siswa baru wajib mengganti password pada login pertama; statusnya disimpan di database.

## Langkah penerapan Supabase

1. Pastikan tabel `class_roster` sudah tersedia dan berisi 43 siswa. Jika belum, periksa status migrasi `20261109_finance_roster.sql` dan jalankan migrasi tersebut satu kali melalui Supabase SQL Editor. Jangan jalankan semua migration sekaligus.
2. Buka Supabase Dashboard → SQL Editor, lalu jalankan isi `supabase/migrations/20261110_username_accounts.sql`.
3. Jalankan migration `supabase/migrations/20261111_secure_student_password_change.sql`. Migration ini menambahkan status wajib ganti password yang hanya dapat diubah oleh proses server. Jika ada nomor absen duplikat pada `profiles`, migration akan berhenti dengan pesan pemeriksaan dan tidak memilih data secara otomatis.
4. Deploy kedua Edge Function berikut dari folder project menggunakan Supabase CLI:

   ```bash
   supabase login
   supabase link --project-ref lrvipfabmkyfrtusmhfh
   supabase functions deploy create-student-accounts
   supabase functions deploy complete-student-password-change
   ```

   Edge Function memakai environment secrets bawaan Supabase (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`). Jangan masukkan service-role key ke frontend atau file `.env` frontend.
5. Build dan deploy frontend seperti biasa.
6. Login memakai akun admin yang sudah ada. Buka **Admin Power → Akun Siswa → Buat akun 43 siswa**.
7. Unduh CSV kredensial yang baru dibuat dan simpan dengan aman. Bagikan username/password masing-masing secara pribadi. Password hanya dikembalikan pada proses pembuatan pertama; menekan tombol lagi tidak mereset password akun yang sudah ada.

## Catatan keamanan

- Endpoint hanya mengizinkan pengguna dengan `profiles.role = 'admin'`.
- Password sementara dibuat acak dan tidak disimpan sebagai teks di tabel aplikasi.
- CSV berisi password sementara. Jangan unggah ke grup kelas atau repositori publik.
- Siswa diminta mengganti password saat pertama kali login.
- Akun admin lama tetap dapat login memakai email dan password yang sudah dimiliki.

## Verifikasi

Setelah kedua migration dan kedua Edge Function terpasang, uji dengan satu akun admin terlebih dahulu. Periksa jumlah akun baru, akun yang sudah ada, dan kegagalan yang dilaporkan UI sebelum membagikan kredensial. Build frontend perlu dijalankan di lingkungan yang sudah memasang dependency project.
