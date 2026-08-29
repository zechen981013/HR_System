<template>
  <div class="page">
    <header class="header">
      <div class="header-left">
        <h2>工资管理</h2>
        <span class="sub">2026 年 7 月 · 月底发薪（RabbitMQ 削峰填谷）</span>
      </div>
      <div class="header-right">
        <span class="user">{{ user?.name }}（{{ user?.departmentName }}）</span>
        <el-button size="small" @click="$router.push('/attendance')">考勤管理</el-button>
        <el-button size="small" @click="handleLogout">退出登录</el-button>
      </div>
    </header>

    <main class="main" v-loading="loading">
      <div class="toolbar">
        <el-date-picker v-model="month" type="month" value-format="YYYY-MM" @change="loadAll" />
        <el-button type="primary" :loading="calcLoading" @click="handleCalculate">计算工资</el-button>
        <el-button @click="loadAll">刷新</el-button>
        <el-button type="success" :disabled="!selected.length" @click="handleBatchPay">
          批量发放({{ selected.length }})
        </el-button>
        <el-button type="warning" :loading="simLoading" @click="handleSimulate">模拟并发发薪 20000</el-button>
        <span class="mq-tip">发薪请求全部进入消息队列，消费者按自身能力逐条处理</span>
      </div>

      <div class="stat-cards">
        <div class="card"><div class="num">{{ fmt(totalGross) }}</div><div class="label">应发总额</div></div>
        <div class="card hot"><div class="num">{{ fmt(totalNet) }}</div><div class="label">实发总额</div></div>
        <div class="card"><div class="num">{{ fmt(totalTax) }}</div><div class="label">个税总额</div></div>
        <div class="card"><div class="num">{{ fmt(totalSocial) }}</div><div class="label">五险一金</div></div>
        <div class="card"><div class="num">{{ employeeCount }}</div><div class="label">发薪人数</div></div>
      </div>

      <div class="dept-stats" v-if="deptStats.length">
        <table class="dept-table">
          <thead>
            <tr><th>部门</th><th>人数</th><th>平均应发</th><th>平均实发</th><th>实发合计</th></tr>
          </thead>
          <tbody>
            <tr v-for="d in deptStats" :key="d.department">
              <td>{{ d.department }}</td>
              <td>{{ d.count }}</td>
              <td>{{ fmt(d.avgGross) }}</td>
              <td>{{ fmt(d.avgNet) }}</td>
              <td>{{ fmt(d.totalNet) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="table-wrap">
        <el-table :data="list" border size="small" @selection-change="onSelectionChange">
          <el-table-column type="selection" width="42" :selectable="(r) => r.status === '待发放'" />
          <el-table-column prop="name" label="姓名" width="90" fixed />
          <el-table-column prop="departmentName" label="部门" width="90" />
          <el-table-column prop="position" label="职位" width="120" />
          <el-table-column label="类型" width="70">
            <template #default="{ row }">
              <el-tag size="small" :type="row.salaryType === 'SALES' ? 'warning' : 'primary'">
                {{ row.salaryType === 'SALES' ? '销售' : '固定' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="底薪" width="90" align="right">
            <template #default="{ row }">{{ fmt(row.baseSalary) }}</template>
          </el-table-column>
          <el-table-column label="考勤扣款" width="90" align="right">
            <template #default="{ row }">
              <span :class="{ negative: row.attendanceDeduction > 0 }">-{{ fmt(row.attendanceDeduction) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="提成" width="90" align="right">
            <template #default="{ row }">{{ fmt(row.commission) }}</template>
          </el-table-column>
          <el-table-column label="应发" width="100" align="right">
            <template #default="{ row }">{{ fmt(row.grossSalary) }}</template>
          </el-table-column>
          <el-table-column label="五险一金" width="90" align="right">
            <template #default="{ row }">{{ fmt(row.socialInsurance) }}</template>
          </el-table-column>
          <el-table-column label="个税" width="90" align="right">
            <template #default="{ row }">{{ fmt(row.tax) }}</template>
          </el-table-column>
          <el-table-column label="实发" width="110" align="right">
            <template #default="{ row }">
              <b class="net">{{ fmt(row.netSalary) }}</b>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="80">
            <template #default="{ row }">
              <el-tag size="small" :type="statusType(row.status)">{{ row.status }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="payDate" label="发放时间" width="160">
            <template #default="{ row }">{{ row.payDate ? row.payDate.replace('T', ' ').slice(0, 19) : '-' }}</template>
          </el-table-column>
          <el-table-column label="操作" width="80" fixed="right">
            <template #default="{ row }">
              <el-button size="small" type="primary" :disabled="row.status !== '待发放'" @click="handlePay([row.id])">
                发放
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </main>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { calculateSalary, getSalaryList, getSalaryStatistics, logout, paySalary, simulatePay } from '../api'

const router = useRouter()
const user = JSON.parse(localStorage.getItem('pt_user') || 'null')
const month = ref('2026-07')
const list = ref([])
const loading = ref(false)
const calcLoading = ref(false)
const simLoading = ref(false)
const selected = ref([])
const stats = ref(null)

const year = computed(() => Number(month.value.split('-')[0]))
const mon = computed(() => Number(month.value.split('-')[1]))
const totalGross = computed(() => stats.value?.totalGross || 0)
const totalNet = computed(() => stats.value?.totalNet || 0)
const totalTax = computed(() => stats.value?.totalTax || 0)
const totalSocial = computed(() => stats.value?.totalSocial || 0)
const employeeCount = computed(() => stats.value?.employeeCount || 0)
const deptStats = computed(() => stats.value?.deptStats || [])

const fmt = (v) => '¥' + Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
const statusType = (s) => ({ '待发放': 'info', '发放中': 'warning', '已发放': 'success', '发放失败': 'danger' }[s] || 'info')

function onSelectionChange(rows) {
  selected.value = rows
}

async function loadList() {
  const res = await getSalaryList(year.value, mon.value)
  if (res.code === 0) list.value = res.data
  else ElMessage.error(res.message)
}

async function loadStats() {
  const res = await getSalaryStatistics(year.value, mon.value)
  if (res.code === 0) stats.value = res.data
}

async function loadAll() {
  loading.value = true
  try {
    await Promise.all([loadList(), loadStats()])
  } catch (e) {
    ElMessage.error('加载工资数据失败')
  } finally {
    loading.value = false
  }
}

async function handleCalculate() {
  calcLoading.value = true
  try {
    const res = await calculateSalary(year.value, mon.value)
    if (res.code === 0) {
      ElMessage.success(`已计算 ${res.data.count} 名员工工资`)
      await loadAll()
    } else {
      ElMessage.error(res.message)
    }
  } finally {
    calcLoading.value = false
  }
}

async function handlePay(ids) {
  const res = await paySalary(ids)
  if (res.code === 0) {
    ElMessage.success(res.data.message)
    setTimeout(loadAll, 1200)
  } else {
    ElMessage.error(res.message)
  }
}

async function handleBatchPay() {
  await ElMessageBox.confirm(`确定批量发放选中的 ${selected.value.length} 份工资？`, '批量发放', { type: 'warning' })
  await handlePay(selected.value.map((r) => r.id))
}

async function handleSimulate() {
  await ElMessageBox.confirm('模拟 20000 人同时提交发薪请求，投递到 RabbitMQ 队列（消费者按自身能力逐条消费）。确认执行？', '模拟高并发', { type: 'warning' })
  simLoading.value = true
  try {
    const res = await simulatePay(20000)
    if (res.code === 0) ElMessage.success(res.data.message)
    else ElMessage.error(res.message)
  } finally {
    simLoading.value = false
  }
}

async function handleLogout() {
  try {
    await logout()
  } catch (e) { /* ignore */ }
  localStorage.removeItem('pt_token')
  localStorage.removeItem('pt_user')
  router.push('/login')
}

onMounted(loadAll)
</script>

<style scoped>
.page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: #f0f2f5;
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
  gap: 12px;
  margin-bottom: 14px;
  flex-wrap: wrap;
}

.mq-tip {
  margin-left: auto;
  font-size: 12px;
  color: #b8860b;
}

.stat-cards {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
  margin-bottom: 14px;
}

.card {
  background: #fff;
  border-radius: 8px;
  padding: 14px 16px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.card .num {
  font-size: 22px;
  font-weight: 700;
  color: #303133;
}

.card.hot .num {
  color: #f56c6c;
}

.card .label {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}

.dept-stats {
  background: #fff;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 14px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.dept-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.dept-table th,
.dept-table td {
  border: 1px solid #ebeef5;
  padding: 8px 12px;
  text-align: left;
}

.dept-table th {
  background: #f5f7fa;
  color: #606266;
}

.negative {
  color: #f56c6c;
}

.net {
  color: #1f6feb;
}
</style>
