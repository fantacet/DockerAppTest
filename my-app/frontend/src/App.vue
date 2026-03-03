<script setup lang="ts">
import AppLayout from './components/AppLayout.vue'
</script>

<template>
  <AppLayout>
    <router-view />
  </AppLayout>
</template>

<style>
body {
  margin: 0;
  font-family: var(--p-font-family, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif);
  background-color: var(--p-surface-50, #f8fafc);
  color: var(--p-text-color, #334155);
}

.card {
  background: var(--p-surface-0, #fff);
  padding: 1.5rem;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  border-radius: 12px;
  margin-bottom: 2rem;
  border: 1px solid var(--p-surface-200, #e2e8f0);
}

/* 簡單 Utility Classes */
.mt-4 { margin-top: 1rem; }
.mb-4 { margin-bottom: 1rem; }
.p-4 { padding: 1rem; }
.text-xl { font-size: 1.25rem; line-height: 1.75rem; }
.font-bold { font-weight: 700; }
</style>
