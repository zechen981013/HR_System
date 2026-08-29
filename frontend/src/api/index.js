import axios from 'axios'

const api = axios.create({ baseURL: '/api', timeout: 15000 })

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('pt_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => res.data,
  (err) => {
    if (err.response && err.response.status === 401) {
      localStorage.removeItem('pt_token')
      localStorage.removeItem('pt_user')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export const login = (username, password) => api.post('/auth/login', { username, password })
export const logout = () => api.post('/auth/logout')
export const getMonthAttendance = (year, month) => api.get('/attendance/month', { params: { year, month } })

// 工资管理（仅财务部）
export const calculateSalary = (year, month) => api.post('/salary/calculate', null, { params: { year, month } })
export const getSalaryList = (year, month) => api.get('/salary/list', { params: { year, month } })
export const getSalaryStatistics = (year, month) => api.get('/salary/statistics', { params: { year, month } })
export const paySalary = (ids) => api.post('/salary/pay', { ids })
export const simulatePay = (count) => api.post('/salary/pay/simulate', null, { params: { count } })
