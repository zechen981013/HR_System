<template>
  <div class="login-page">
    <el-card class="login-card" shadow="always">
      <div class="title">
        <h1>员工考勤系统</h1>
        <p>登录后查看 2026 年 7 月全员考勤数据</p>
      </div>
      <el-form :model="form" size="large" @submit.prevent>
        <el-form-item>
          <el-input v-model="form.username" placeholder="用户名" :prefix-icon="User" clearable />
        </el-form-item>
        <el-form-item>
          <el-input
            v-model="form.password"
            type="password"
            placeholder="密码"
            :prefix-icon="Lock"
            show-password
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        <el-button type="primary" size="large" class="login-btn" :loading="loading" @click="handleLogin">
          登 录
        </el-button>
      </el-form>
      <el-alert
        type="info"
        :closable="false"
        class="tip"
        title="演示账号：任意员工用户名，如 wangfang；密码统一为 123456"
      />
    </el-card>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { login } from '../api'

const router = useRouter()
const form = reactive({ username: 'wangfang', password: '' })
const loading = ref(false)

async function handleLogin() {
  if (!form.username || !form.password) {
    ElMessage.warning('请输入用户名和密码')
    return
  }
  loading.value = true
  try {
    const res = await login(form.username.trim(), form.password)
    if (res.code === 0) {
      localStorage.setItem('pt_token', res.data.token)
      localStorage.setItem('pt_user', JSON.stringify(res.data))
      ElMessage.success(`欢迎，${res.data.name}`)
      router.push('/attendance')
    } else {
      ElMessage.error(res.message)
    }
  } catch (e) {
    ElMessage.error(e.response?.data?.message || '登录失败，请检查网络')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1f6feb 0%, #3b82f6 50%, #60a5fa 100%);
}

.login-card {
  width: 400px;
  padding: 10px 14px 18px;
  border-radius: 12px;
}

.title {
  text-align: center;
  margin-bottom: 24px;
}

.title h1 {
  font-size: 26px;
  color: #1f6feb;
}

.title p {
  margin-top: 8px;
  color: #909399;
  font-size: 13px;
}

.login-btn {
  width: 100%;
  letter-spacing: 6px;
}

.tip {
  margin-top: 16px;
}
</style>
