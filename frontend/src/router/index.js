import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Attendance from '../views/Attendance.vue'
import Salary from '../views/Salary.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/attendance' },
    { path: '/login', component: Login },
    { path: '/attendance', component: Attendance, meta: { requiresAuth: true } },
    { path: '/salary', component: Salary, meta: { requiresAuth: true, requiresFinance: true } }
  ]
})

router.beforeEach((to) => {
  const token = localStorage.getItem('pt_token')
  if (to.meta.requiresAuth && !token) return '/login'
  if (to.path === '/login' && token) return '/attendance'
  const user = JSON.parse(localStorage.getItem('pt_user') || 'null')
  if (to.meta.requiresFinance && user && user.departmentName !== '财务部') return '/attendance'
})

export default router
