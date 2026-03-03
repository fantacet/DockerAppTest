<template>
  <div class="container">
    <h1>{{ data?.message ?? (lang === 'en' ? 'Hello! This is a .NET app from Docker.' : 'Hello! 這是來自 Docker 的 .NET 應用。') }}</h1>

    <p v-if="data">
      {{ lang === 'en' ? `Database access count: ${data.count}.` : `資料庫已累計存取 ${data.count} 次。` }}
    </p>
    <p v-if="data">
      {{ lang === 'en' ? `App Version: ${data.version}` : `應用程式版本：${data.version}` }}
    </p>

    <p v-if="error" class="error">{{ error }}</p>
    <p v-if="loading">Loading…</p>

    <div class="actions">
      <button @click="recordVisit">{{ lang === 'en' ? 'Record Visit' : '記錄訪問' }}</button>
      <button @click="toggleLang">{{ lang === 'en' ? '切換為繁體中文' : 'Switch to English' }}</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

interface VisitResponse {
  message: string
  db_stats: string
  count: number
  version: string
  lang: string
}

interface CountResponse {
  count: number
}

const lang = ref<string>('zh-TW')
const data = ref<VisitResponse | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)

async function recordVisit() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(`/api/visits?lang=${lang.value}`, { method: 'POST' })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    data.value = await res.json() as VisitResponse
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : String(e)
  } finally {
    loading.value = false
  }
}

async function loadCount() {
  try {
    const res = await fetch('/api/visits/count')
    if (!res.ok) return
    const json = await res.json() as CountResponse
    if (!data.value) {
      data.value = {
        message: lang.value === 'en' ? 'Hello! This is a .NET app from Docker.' : 'Hello! 這是來自 Docker 的 .NET 應用。',
        db_stats: '',
        count: json.count,
        version: '',
        lang: lang.value
      }
      // Fetch version from health
      const h = await fetch('/api/health')
      if (h.ok) {
        const hj = await h.json() as { status: string; version: string }
        data.value.version = hj.version
      }
    }
  } catch { /* ignore */ }
}

async function toggleLang() {
  lang.value = lang.value === 'zh-TW' ? 'en' : 'zh-TW'
  await recordVisit()
}

onMounted(() => loadCount())
</script>

<style scoped>
.container {
  font-family: Arial, sans-serif;
  max-width: 600px;
  margin: 60px auto;
  padding: 24px;
  border: 1px solid #ddd;
  border-radius: 8px;
}
.actions {
  margin-top: 16px;
  display: flex;
  gap: 8px;
}
button {
  padding: 8px 16px;
  cursor: pointer;
}
.error {
  color: red;
}
</style>
