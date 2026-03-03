<script setup lang="ts">
import Card from 'primevue/card';
</script>

<template>
  <div class="about-container">
    <h1 style="color: var(--p-surface-900); font-size: 2rem; font-weight: 700; margin-bottom: 2rem;">關於系統</h1>
    <Card class="custom-card shadow-sm border-round-xl">
      <template #title>AIS Platform 前端架構</template>
      <template #content>
        <p style="color: var(--p-surface-700); line-height: 1.6;">
          本前端系統採用 <strong>Vue 3 (Composition API)</strong> 開發，基於 <strong>TypeScript</strong> 提供嚴格的型別檢查，確保高維護性。
          <br><br>
          使用 <strong>Vite</strong> 做為建置工具，獲得極速的啟動體驗與打包效能。
          介面採用 <strong>PrimeVue 4</strong> 企業級元件庫，大幅降低從頭開發 UI 的成本，並整合 <strong>Pinia</strong> 與 <strong>Vue Router</strong> 管理狀態與路由。
        </p>
      </template>
    </Card>
  </div>
</template>
