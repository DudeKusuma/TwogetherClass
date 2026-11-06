import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { supabase, isSupabaseConfigured } from '@/lib/supabase'
import { useAnnouncementStore } from './useAnnouncementStore'
import { useSubjectStore } from './useSubjectStore'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const loading = ref(true)
  const authError = ref('')
  const isAuthenticated = computed(() => Boolean(user.value))
  const isAdmin = computed(() => user.value?.role === 'admin')
  const roleLabel = computed(() => (isAdmin.value ? 'Admin Kelas' : 'Siswa'))

  async function applySession(session) {
    if (!session?.user) {
      user.value = null
      return
    }
    const authUser = session.user
    let profile = null
    const { data, error } = await supabase
      .from('profiles')
      .select('display_name, role, username, attendance_number, must_change_password')
      .eq('id', authUser.id)
      .maybeSingle()
    if (error) console.error('Could not load profile:', error.message)
    profile = data
    let studentProfile = null
    if (profile?.role !== 'admin') {
      const { data: studentProfileData } = await supabase.rpc('get_student_profile', {
        target_profile_id: authUser.id
      })
      studentProfile = studentProfileData
    }
    user.value = {
      id: authUser.id,
      email: authUser.email,
      username: profile?.username || authUser.user_metadata?.username || (authUser.email || '').split('@')[0],
      attendanceNumber: profile?.attendance_number ?? studentProfile?.attendance_number ?? authUser.user_metadata?.attendance_number ?? null,
      fullName: studentProfile?.full_name || profile?.display_name || authUser.user_metadata?.display_name || authUser.email,
      displayName: studentProfile?.short_name || profile?.display_name || authUser.user_metadata?.display_name || authUser.email,
      role: profile?.role || 'student',
      mustChangePassword: profile ? profile.must_change_password === true : true
    }
  }

  async function initialize() {
    if (!isSupabaseConfigured) {
      loading.value = false
      authError.value = 'Supabase belum dikonfigurasi. Periksa file frontend/.env.local.'
      return
    }
    const { data, error } = await supabase.auth.getSession()
    if (error) authError.value = error.message
    await applySession(data?.session)
    if (user.value) { await Promise.all([useAnnouncementStore().load(), useSubjectStore().load()]) }
    supabase.auth.onAuthStateChange((_event, session) => {
      // Defer profile lookup out of the auth callback to avoid locking the auth client.
      Promise.resolve().then(() => applySession(session))
    })
    loading.value = false
  }

  async function login(usernameOrEmail, password) {
    authError.value = ''
    if (!isSupabaseConfigured) {
      authError.value = 'Koneksi Supabase belum dikonfigurasi.'
      return false
    }
    const loginValue = usernameOrEmail.trim().toLowerCase()
    const email = loginValue.includes('@') ? loginValue : `${loginValue}@twogetherclass.invalid`
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) {
      authError.value = error.message
      return false
    }
    await applySession(data.session)
    await Promise.all([useAnnouncementStore().load(), useSubjectStore().load()])
    return true
  }

  async function changePassword(newPassword) {
    authError.value = ''
    if (!isSupabaseConfigured || !user.value) {
      authError.value = 'Sesi login tidak ditemukan.'
      return false
    }
    const { data, error } = await supabase.functions.invoke('complete-student-password-change', {
      body: { newPassword }
    })
    if (error || data?.error || data?.success !== true) {
      authError.value = data?.error || error?.message || 'Password belum berhasil diperbarui.'
      return false
    }
    user.value.mustChangePassword = false
    return true
  }

  async function logout() {
    if (supabase) await supabase.auth.signOut()
    user.value = null
    useAnnouncementStore().clearDismissed()
  }

  return { user, loading, authError, isAuthenticated, isAdmin, roleLabel, initialize, login, changePassword, logout }
})
