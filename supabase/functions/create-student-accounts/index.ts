import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type RosterStudent = {
  attendance_number: number
  student_number: string
  full_name: string
  profile_id: string | null
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function makeTemporaryPassword() {
  const bytes = crypto.getRandomValues(new Uint8Array(18))
  const value = Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('')
  return `Tc-${value}!`
}

function matchesRosterIdentity(user: any, student: RosterStudent, username: string) {
  const metadata = user.user_metadata || {}
  return metadata.username === username
    && Number(metadata.attendance_number) === Number(student.attendance_number)
    && String(metadata.student_number || '') === String(student.student_number)
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
  if (!authorization) return json({ error: 'Sesi admin tidak ditemukan.' }, 401)

  const caller = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  })
  const { data: authData, error: authError } = await caller.auth.getUser()
  if (authError || !authData.user) return json({ error: 'Sesi login tidak valid.' }, 401)

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
  const { data: callerProfile, error: callerProfileError } = await admin
    .from('profiles').select('role').eq('id', authData.user.id).maybeSingle()
  if (callerProfileError || callerProfile?.role !== 'admin') {
    return json({ error: 'Hanya admin kelas yang dapat membuat akun.' }, 403)
  }

  const { data: roster, error: rosterError } = await admin
    .from('class_roster')
    .select('attendance_number, student_number, full_name, profile_id')
    .order('attendance_number')
  if (rosterError) return json({ error: `Data roster belum siap: ${rosterError.message}` }, 400)

  const students = (roster || []) as RosterStudent[]
  if (students.length !== 43) {
    return json({ error: `Roster harus berisi tepat 43 siswa. Saat ini ditemukan ${students.length} baris. Tidak ada akun yang dibuat.` }, 400)
  }

  const studentNumbers = new Set<string>()
  for (let index = 0; index < 43; index += 1) {
    const student = students[index]
    if (Number(student.attendance_number) !== index + 1) {
      return json({ error: `Nomor absen ${index + 1} tidak ditemukan atau urutannya tidak valid. Tidak ada akun yang dibuat.` }, 400)
    }
    const studentNumber = String(student.student_number || '').trim()
    const fullName = String(student.full_name || '').trim()
    if (!studentNumber || !fullName || studentNumbers.has(studentNumber)) {
      return json({ error: `Data nama atau NIS pada nomor absen ${index + 1} kosong/duplikat. Tidak ada akun yang dibuat.` }, 400)
    }
    studentNumbers.add(studentNumber)
  }

  const usernames = students.map((student) => `siswa${String(student.attendance_number).padStart(2, '0')}`)
  const { data: profiles, error: profilesError } = await admin
    .from('profiles')
    .select('id, username, role, attendance_number, must_change_password')
    .or(`attendance_number.gte.1,username.in.(${usernames.join(',')})`)
  if (profilesError) return json({ error: `Tidak dapat memeriksa profil siswa: ${profilesError.message}` }, 500)

  const profileByAttendance = new Map<number, any>()
  const profileByUsername = new Map<string, any>()
  for (const profile of profiles || []) {
    if (profile.attendance_number != null) profileByAttendance.set(Number(profile.attendance_number), profile)
    if (profile.username) profileByUsername.set(String(profile.username).toLowerCase(), profile)
  }

  const existingUsers: any[] = []
  const perPage = 1000
  for (let page = 1; ; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage })
    if (error) return json({ error: `Tidak dapat memeriksa akun Auth: ${error.message}` }, 500)
    const batch = data.users || []
    existingUsers.push(...batch)
    if (batch.length < perPage) break
  }
  const existingByEmail = new Map(existingUsers.map((user) => [String(user.email || '').toLowerCase(), user]))

  const created: Array<{ username: string; password: string; full_name: string; attendance_number: number }> = []
  const alreadyCreated: Array<{ username: string; full_name: string; attendance_number: number }> = []
  const failures: Array<{ username: string; full_name: string; error: string }> = []

  for (const student of students) {
    const attendanceNumber = Number(student.attendance_number)
    const username = `siswa${String(attendanceNumber).padStart(2, '0')}`
    const syntheticEmail = `${username}@twogetherclass.invalid`
    const existingAuthUser = existingByEmail.get(syntheticEmail)
    const attendanceProfile = profileByAttendance.get(attendanceNumber)
    const usernameProfile = profileByUsername.get(username)

    if (attendanceProfile && usernameProfile && attendanceProfile.id !== usernameProfile.id) {
      failures.push({ username, full_name: student.full_name, error: 'Nomor absen dan username menunjuk ke dua profil berbeda. Perlu pemeriksaan admin.' })
      continue
    }

    if (existingAuthUser) {
      if (!matchesRosterIdentity(existingAuthUser, student, username)) {
        failures.push({ username, full_name: student.full_name, error: 'Alamat login internal sudah dipakai akun dengan metadata berbeda. Akun tidak disentuh.' })
        continue
      }
      if (student.profile_id && student.profile_id !== existingAuthUser.id) {
        failures.push({ username, full_name: student.full_name, error: 'Roster sudah terhubung ke profil lain. Akun tidak disentuh.' })
        continue
      }
      const linkedProfile = attendanceProfile || usernameProfile
      if (!linkedProfile || linkedProfile.id !== existingAuthUser.id || linkedProfile.role !== 'student') {
        failures.push({ username, full_name: student.full_name, error: 'Akun Auth ditemukan tetapi profilnya tidak cocok/tidak lengkap. Perlu pemeriksaan admin; tidak dilakukan penautan otomatis.' })
        continue
      }
      if (Number(linkedProfile.attendance_number) !== attendanceNumber || String(linkedProfile.username || '').toLowerCase() !== username) {
        failures.push({ username, full_name: student.full_name, error: 'Identitas profil tidak cocok dengan roster. Akun tidak disentuh.' })
        continue
      }
      if (!student.profile_id) {
        const { error: linkError } = await admin.from('class_roster')
          .update({ profile_id: existingAuthUser.id })
          .eq('attendance_number', attendanceNumber)
          .is('profile_id', null)
        if (linkError) {
          failures.push({ username, full_name: student.full_name, error: `Gagal memperbaiki tautan roster: ${linkError.message}` })
          continue
        }
      }
      alreadyCreated.push({ username, full_name: student.full_name, attendance_number: attendanceNumber })
      continue
    }

    if (attendanceProfile || usernameProfile || student.profile_id) {
      failures.push({ username, full_name: student.full_name, error: 'Sudah ada tautan profil tanpa akun Auth yang cocok. Perlu pemeriksaan admin; tidak dibuat akun baru.' })
      continue
    }

    const password = makeTemporaryPassword()
    const { data: createdAuth, error: createError } = await admin.auth.admin.createUser({
      email: syntheticEmail,
      password,
      email_confirm: true,
      user_metadata: {
        username,
        display_name: student.full_name,
        attendance_number: attendanceNumber,
        student_number: student.student_number,
        must_change_password: true,
      },
    })

    if (createError || !createdAuth.user) {
      failures.push({ username, full_name: student.full_name, error: createError?.message || 'Gagal membuat akun Auth.' })
      continue
    }

    const newUserId = createdAuth.user.id
    const { error: profileWriteError } = await admin.from('profiles').upsert({
      id: newUserId,
      username,
      display_name: student.full_name,
      role: 'student',
      attendance_number: attendanceNumber,
      must_change_password: true,
    }, { onConflict: 'id' })

    let linkError: { message: string } | null = profileWriteError
    if (!linkError) {
      const { data: linkedRows, error } = await admin.from('class_roster')
        .update({ profile_id: newUserId })
        .eq('attendance_number', attendanceNumber)
        .is('profile_id', null)
        .select('attendance_number')
      linkError = error || (!linkedRows?.length ? { message: 'Roster berubah atau sudah ditautkan oleh proses lain.' } : null)
    }

    if (linkError) {
      const { error: rollbackError } = await admin.auth.admin.deleteUser(newUserId)
      const rollbackMessage = rollbackError
        ? ` Penghapusan ulang akun Auth juga gagal (${rollbackError.message}); perlu pemeriksaan manual.`
        : ' Akun Auth yang baru dibuat sudah dibatalkan.'
      failures.push({ username, full_name: student.full_name, error: `Gagal menautkan profil/roster: ${linkError.message}.${rollbackMessage}` })
      continue
    }

    created.push({ username, password, full_name: student.full_name, attendance_number: attendanceNumber })
  }

  return json({
    message: 'Proses selesai. Password sementara hanya tersedia pada respons pembuatan akun baru ini; unduh CSV dan simpan dengan aman.',
    created,
    alreadyCreated,
    failures,
  })
})
