<template>
  <div class="page">
    <header class="header">
      <div class="header-left">
        <h2>员工考勤管理</h2>
        <span class="sub" v-if="meta.workStart">
          班次 {{ meta.workStart }} - {{ meta.workEnd }} · 2026 年 7 月
        </span>
      </div>
      <div class="header-right">
        <span class="user">{{ user?.name }}（{{ user?.departmentName }} · {{ user?.position }}）</span>
        <el-button v-if="user?.departmentName === '财务部'" size="small" type="primary" @click="router.push('/salary')">
          工资管理
        </el-button>
        <el-button size="small" @click="handleLogout">退出登录</el-button>
      </div>
    </header>

    <main class="main">
      <div class="toolbar">
        <el-date-picker v-model="month" type="month" value-format="YYYY-MM" @change="load" />
        <div class="legend">
          <span class="lg"><i class="dot s-normal"></i>正常</span>
          <span class="lg"><i class="dot s-late"></i>迟到</span>
          <span class="lg"><i class="dot s-early"></i>早退</span>
          <span class="lg"><i class="dot s-leave"></i>请假</span>
          <span class="lg"><i class="dot s-absent"></i>缺勤</span>
          <span class="lg"><i class="dot s-rest"></i>休息</span>
        </div>
        <span class="stats">{{ employees.length }} 名员工 · {{ recordsTotal }} 条记录</span>
      </div>

      <div class="table-wrap" v-loading="loading">
        <table class="matrix">
          <thead>
            <tr>
              <th class="sticky col-emp">员工</th>
              <th v-for="d in dayList" :key="d.day" class="col-day" :class="{ weekend: d.weekend }">
                <div class="d">{{ d.day }}</div>
                <div class="w">{{ d.week }}</div>
              </th>
              <th class="col-sum">出勤</th>
              <th class="col-sum">迟到</th>
              <th class="col-sum">早退</th>
              <th class="col-sum">请假</th>
              <th class="col-sum">缺勤</th>
              <th class="col-sum">加班</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="emp in employees" :key="emp.employeeId">
              <td class="sticky col-emp">
                <div class="name">{{ emp.name }}</div>
                <div class="meta">{{ emp.departmentName }} · {{ emp.position }}</div>
              </td>
              <td
                v-for="r in emp.records"
                :key="r.date"
                class="col-day cell"
                :class="[statusClass(r.status), isWeekendDate(r.date) ? 'weekend' : '']"
                :title="tooltip(r)"
              >
                {{ cellText(r) }}
              </td>
              <td class="col-sum sum">{{ count(emp, '正常') }}</td>
              <td class="col-sum sum">{{ count(emp, '迟到') }}</td>
              <td class="col-sum sum">{{ count(emp, '早退') }}</td>
              <td class="col-sum sum">{{ count(emp, '请假') }}</td>
              <td class="col-sum sum">{{ count(emp, '缺勤') }}</td>
              <td class="col-sum sum">{{ otCount(emp) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </main>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { getMonthAttendance, logout } from '../api'

const router = useRouter()
const user = JSON.parse(localStorage.getItem('pt_user') || 'null')
const month = ref('2026-07')
const meta = ref({ workStart: '', workEnd: '' })
const employees = ref([])
const loading = ref(false)

const dayList = computed(() => {
  const [y, m] = month.value.split('-').map(Number)
  const days = new Date(y, m, 0).getDate()
  const list = []
  for (let d = 1; d <= days; d++) {
    const dow = new Date(y, m - 1, d).getDay()
    list.push({ day: d, week: '日一二三四五六'[dow], weekend: dow === 0 || dow === 6 })
  }
  return list
})

const recordsTotal = computed(() => employees.value.length * (dayList.value.length || 31))

async function load() {
  const [y, m] = month.value.split('-').map(Number)
  loading.value = true
  try {
    const res = await getMonthAttendance(y, m)
    if (res.code === 0) {
      meta.value = { workStart: res.data.workStart, workEnd: res.data.workEnd }
      employees.value = res.data.employees
    } else {
      ElMessage.error(res.message)
    }
  } catch (e) {
    ElMessage.error('加载考勤数据失败')
  } finally {
    loading.value = false
  }
}

function isWeekendDate(date) {
  const d = new Date(date)
  const dow = d.getDay()
  return dow === 0 || dow === 6
}

function statusClass(status) {
  return {
    '正常': 's-normal',
    '迟到': 's-late',
    '早退': 's-early',
    '迟到早退': 's-late',
    '请假': 's-leave',
    '缺勤': 's-absent',
    '休息': 's-rest'
  }[status] || ''
}

function cellText(r) {
  if (r.status === '休息') return '休'
  if (r.status === '请假') return '假'
  if (r.status === '缺勤') return '缺'
  if (r.status === '无记录') return ''
  return r.checkInTime ? r.checkInTime.slice(0, 5) : ''
}

function tooltip(r) {
  const lines = [`${r.date} ${r.weekday || ''}`, `状态：${r.status}`]
  if (r.checkInTime) lines.push(`上班：${r.checkInTime}`)
  if (r.checkOutTime) lines.push(`下班：${r.checkOutTime}`)
  if (r.workHours) lines.push(`工作时长：${r.workHours} 小时`)
  if (r.remark) lines.push(`备注：${r.remark}`)
  return lines.join('\n')
}

function count(emp, ...statuses) {
  return emp.records.filter((r) => statuses.includes(r.status)).length
}

function otCount(emp) {
  return emp.records.filter((r) => r.remark === '加班').length
}

async function handleLogout() {
  try {
    await logout()
  } catch (e) {
    /* ignore */
  }
  localStorage.removeItem('pt_token')
  localStorage.removeItem('pt_user')
  router.push('/login')
}

onMounted(load)
</script>

<style scoped>
.page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.header {
  background: #fff;
  padding: 14px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  position: sticky;
  top: 0;
  z-index: 10;
}

.header h2 {
  font-size: 18px;
  color: #1f6feb;
}

.header .sub {
  margin-left: 12px;
  color: #909399;
  font-size: 13px;
}

.header-right .user {
  margin-right: 14px;
  color: #606266;
  font-size: 13px;
}

.main {
  padding: 16px 20px;
  flex: 1;
}

.toolbar {
  display: flex;
  align-items: center;
  gap: 20px;
  margin-bottom: 14px;
  flex-wrap: wrap;
}

.legend {
  display: flex;
  gap: 14px;
  font-size: 12px;
  color: #606266;
}

.lg {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  display: inline-block;
}

.stats {
  margin-left: auto;
  color: #909399;
  font-size: 13px;
}

.table-wrap {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  overflow: auto;
  max-height: calc(100vh - 180px);
}

table.matrix {
  border-collapse: collapse;
  width: max-content;
  min-width: 100%;
  font-size: 12px;
}

.matrix th,
.matrix td {
  border: 1px solid #ebeef5;
  padding: 6px 4px;
  text-align: center;
}

.matrix thead th {
  background: #f5f7fa;
  color: #606266;
  font-weight: 500;
  position: sticky;
  top: 0;
  z-index: 2;
}

.col-day {
  min-width: 44px;
}

.col-day .d {
  font-size: 13px;
  color: #303133;
}

.col-day .w {
  font-size: 10px;
  color: #c0c4cc;
}

.col-day.weekend,
.matrix td.weekend {
  background: #fafafa;
}

th.col-emp,
td.col-emp {
  position: sticky;
  left: 0;
  z-index: 3;
  background: #fff;
  text-align: left;
  padding: 6px 10px;
  min-width: 150px;
  max-width: 150px;
}

thead th.col-emp {
  z-index: 5;
  background: #f5f7fa;
}

td.col-emp .name {
  font-weight: 600;
  color: #303133;
}

td.col-emp .meta {
  font-size: 11px;
  color: #909399;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

td.cell {
  font-size: 11px;
  color: #606266;
}

td.s-normal {
  color: #67c23a;
  background: #f0f9eb;
}

td.s-late {
  color: #e6a23c;
  background: #fdf6ec;
}

td.s-early {
  color: #e6a23c;
  background: #fdf6ec;
}

td.s-leave {
  color: #409eff;
  background: #ecf5ff;
}

td.s-absent {
  color: #f56c6c;
  background: #fef0f0;
}

td.s-rest {
  color: #c0c4cc;
  background: #fafafa;
}

td.sum {
  color: #303133;
  font-weight: 600;
}

th.col-sum {
  min-width: 40px;
}
</style>
