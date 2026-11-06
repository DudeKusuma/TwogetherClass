import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { useAnnouncementStore } from './useAnnouncementStore'

// Demo-only accounts. This is NOT secure production authentication.
const AUTH_KEY = 'tc_auth'
const DEMO_ACCOUNTS = [
  { username: 'student', password: '123', role: 'student', displayName: 'Student' },
  { username: 'admin', password: '123', role: 'admin', displayName: 'Admin' }
]

function readSession() {
  try {
    const raw = sessionStorage.getItem(AUTH_KEY)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref(readSession())

  const isAuthenticated = computed(() => Boolean(user.value))
  const isAdmin = computed(() => user.value?.role === 'admin')
  const roleLabel = computed(() => (isAdmin.value ? 'Admin Kelas' : 'Siswa'))

  function login(username, password) {
    const account = DEMO_ACCOUNTS.find(
      (a) => a.username === username.trim().toLowerCase() && a.password === password
    )
    if (!account) return false
    user.value = { username: account.username, role: account.role, displayName: account.displayName }
    sessionStorage.setItem(AUTH_KEY, JSON.stringify(user.value))
    return true
  }

  function logout() {
    user.value = null
    sessionStorage.removeItem(AUTH_KEY)
    useAnnouncementStore().clearDismissed()
  }

  return { user, isAuthenticated, isAdmin, roleLabel, login, logout }
})
