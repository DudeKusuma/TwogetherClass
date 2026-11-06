# Twogether Class — Backend Security Update

Patch ini memperkuat alur akun siswa tanpa mengubah fitur kelas lain.

## File yang diubah

- `supabase/functions/create-student-accounts/index.ts`
  - Memastikan roster tepat 43 baris dengan nomor absen 1–43, nama dan NIS valid serta NIS unik.
  - Memverifikasi metadata identitas Auth dan kecocokan profil sebelum memakai akun yang sudah ada.
  - Menolak konflik tautan, dan mencoba menghapus akun Auth baru jika penautan database gagal.
  - Tidak mereset password akun yang sudah ada dan tidak mengembalikan password lama.
- `supabase/functions/complete-student-password-change/index.ts` (baru)
  - Mengubah password melalui Admin API setelah memverifikasi sesi dan profil siswa.
  - Menghapus status wajib ganti password hanya dari server.
- `supabase/migrations/20261111_secure_student_password_change.sql` (baru)
  - Menambahkan `profiles.must_change_password`.
  - Memindahkan flag lama dari Auth metadata ke kolom database.
  - Menambahkan unique index nomor absen; migration berhenti jika menemukan duplikat.
- `frontend/src/stores/useAuthStore.js`
  - Membaca status wajib ganti password dari `profiles`.
  - Memanggil Edge Function khusus saat siswa mengganti password.
  - Gagal tertutup (diarahkan untuk ganti password) jika profil tidak dapat dibaca.
- `USERNAME_LOGIN_SETUP.md`
  - Memperbarui urutan penerapan.

## Urutan penerapan

1. Backup database terlebih dahulu.
2. Pastikan migration `20261110_username_accounts.sql` sudah diterapkan.
3. Jalankan pemeriksaan duplikasi `profiles.attendance_number` di SQL Editor sebelum migration baru.
4. Terapkan `20261111_secure_student_password_change.sql` hanya jika pemeriksaan bersih.
5. Deploy kedua Edge Function: `create-student-accounts` dan `complete-student-password-change`.
6. Build/deploy frontend.
7. Uji dengan akun admin dan satu akun siswa percobaan sebelum membuat semua akun.

Jangan deploy function lama `rapid-task` atau memasukkan Service Role Key ke frontend.

## Pemeriksaan yang dilakukan di lingkungan ini

- JavaScript `useAuthStore.js`: `node --check` lulus.
- Sintaks TypeScript kedua Edge Function: transpile/syntax check lulus.
- Build Vue belum dijalankan karena dependency tidak tersedia di cache offline; `npm install --offline` gagal menemukan paket `@supabase/supabase-js`.
- Belum ada koneksi ke project Supabase online, sehingga migration, Edge Function, Auth, RLS, dan deployment belum diuji terhadap database sebenarnya.
