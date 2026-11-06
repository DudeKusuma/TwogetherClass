import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method tidak diizinkan.' }, 405)

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ error: 'Konfigurasi server Supabase belum lengkap.' }, 500)
  }

  const authorization = request.headers.get('Authorization')
  if (!authorization) return json({ error: 'Sesi login tidak ditemukan.' }, 401)

  let body: { newPassword?: unknown }
  try {
    body = await request.json()
  } catch {
    return json({ error: 'Format permintaan tidak valid.' }, 400)
  }

  if (typeof body.newPassword !== 'string' || body.newPassword.length < 10 || body.newPassword.length > 128) {
    return json({ error: 'Password baru harus terdiri dari 10 sampai 128 karakter.' }, 400)
  }

  const caller = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  })
  const { data: authData, error: authError } = await caller.auth.getUser()
  if (authError || !authData.user) return json({ error: 'Sesi login tidak valid.' }, 401)

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  const { data: profile, error: profileError } = await admin
    .from('profiles')
    .select('id, role, must_change_password')
    .eq('id', authData.user.id)
    .maybeSingle()

  if (profileError) return json({ error: 'Tidak dapat memeriksa status akun.' }, 500)
  if (!profile || profile.role !== 'student') return json({ error: 'Profil siswa tidak ditemukan.' }, 403)
  if (profile.must_change_password !== true) {
    return json({ error: 'Akun ini tidak sedang diwajibkan mengganti password.' }, 409)
  }

  const { error: passwordError } = await admin.auth.admin.updateUserById(authData.user.id, {
    password: body.newPassword,
  })
  if (passwordError) return json({ error: `Password gagal diperbarui: ${passwordError.message}` }, 400)

  // Only this trusted server-side function can clear the database flag.
  const { data: updatedProfile, error: updateError } = await admin
    .from('profiles')
    .update({ must_change_password: false })
    .eq('id', authData.user.id)
    .eq('must_change_password', true)
    .select('id')
    .maybeSingle()

  if (updateError || !updatedProfile) {
    // The password has changed, but the flag remains set. The student can retry this
    // endpoint; it will safely set the password again and attempt to clear the flag.
    return json({
      error: 'Password sudah diperbarui, tetapi status wajib ganti password belum tersimpan. Silakan kirim ulang password baru yang sama.',
    }, 500)
  }

  return json({ success: true, message: 'Password berhasil diperbarui.' })
})
