import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/useAuthStore'
import HomeView from '@/views/HomeView.vue'
import LoginView from '@/views/LoginView.vue'

const routes = [
  { path: '/login', name: 'login', component: LoginView, meta: { public: true, layout: 'blank', title: 'Masuk' } },
  { path: '/change-password', name: 'change-password', component: () => import('@/views/ChangePasswordView.vue'), meta: { public: true, layout: 'blank', title: 'Ganti Password' } },
  { path: '/', name: 'home', component: HomeView, meta: { title: 'Home' } },
  { path: '/about', name: 'about', component: () => import('@/views/AboutView.vue'), meta: { title: 'Tentang' } },
  { path: '/schedule', name: 'schedule', component: () => import('@/views/ScheduleView.vue'), meta: { title: 'Jadwal' } },
  { path: '/tasks', name: 'tasks', component: () => import('@/views/TaskView.vue'), meta: { title: 'Tugas' } },
  { path: '/cash', name: 'cash', component: () => import('@/views/CashView.vue'), meta: { title: 'Uang Kas' } },
  { path: '/contributions', name: 'contributions', component: () => import('@/views/ContributionsView.vue'), meta: { title: 'Iuran Kelas' } },
  { path: '/attendance', name: 'attendance', component: () => import('@/views/AttendanceView.vue'), meta: { title: 'Presensi' } },
  { path: '/profile', name: 'profile', component: () => import('@/views/ProfileView.vue'), meta: { title: 'Profil Saya' } },
  { path: '/admin-power', name: 'admin-power', component: () => import('@/views/AdminPowerView.vue'), meta: { requiresAdmin: true, title: 'Admin Power' } },
  { path: '/admin-power/student-accounts', name: 'admin-student-accounts', component: () => import('@/views/AdminStudentAccountsView.vue'), meta: { requiresAdmin: true, title: 'Akun Siswa · Admin Power' } },
  { path: '/admin-power/announcements', name: 'admin-announcements', component: () => import('@/views/AdminAnnouncementsView.vue'), meta: { requiresAdmin: true, title: 'Pengumuman · Admin Power' } },
  { path: '/admin-power/tomorrow', name: 'admin-tomorrow', component: () => import('@/views/AdminTomorrowView.vue'), meta: { requiresAdmin: true, title: 'Jadwal Besok · Admin Power' } },
  { path: '/admin-power/descriptions', name: 'admin-descriptions', component: () => import('@/views/AdminDescriptionsView.vue'), meta: { requiresAdmin: true, title: 'Deskripsi Mapel · Admin Power' } },
  { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/views/NotFoundView.vue'), meta: { public: true, layout: 'blank', title: 'Tidak ditemukan' } }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: (to, from) => {
    if (to.query.requests === '1' && to.name === 'schedule') return false
    return { top: 0 }
  }
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (to.name === 'login' && auth.isAuthenticated) return { name: auth.user?.mustChangePassword ? 'change-password' : 'home' }
  if (to.name === 'change-password' && !auth.isAuthenticated) return { name: 'login' }
  if (!to.meta.public && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (auth.isAuthenticated && auth.user?.mustChangePassword && to.name !== 'change-password') return { name: 'change-password' }
  if (to.meta.requiresAdmin && !auth.isAdmin) return { name: 'home' }
  return true
})

router.afterEach((to) => {
  document.title = `${to.meta.title ?? 'Twogether Class'} · Twogether Class XI-B2`
})

export default router
