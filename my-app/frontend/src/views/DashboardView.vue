<script setup lang="ts">
import { ref, onMounted } from 'vue';
import axios from 'axios';
import Card from 'primevue/card';

const message = ref('歡迎來到 AIS Platform');
const visitStats = ref<{ count?: number, db_stats?: any } | null>(null);
const loading = ref(true);

const fetchVisits = async () => {
  try {
    const response = await axios.post('/api/visits');
    visitStats.value = response.data;
  } catch (error) {

    console.error('API Error:', error);
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchVisits();
});
</script>

<template>
  <div class="dashboard-wrapper">
    <h1 style="color: var(--p-surface-900); font-size: 2rem; font-weight: 700; margin-bottom: 2rem;">總覽面板</h1>
    
    <div class="grid-container">
      <Card class="custom-card shadow-sm border-round-xl">
        <template #title>
          <div class="card-title">平台狀態</div>
        </template>
        <template #content>
          <p class="text-surface-700 m-0">
            目前由 Vue 3 + Vite + PrimeVue 建構的母版架構已準備就緒！<br>
            {{ message }}
          </p>
        </template>
      </Card>

      <Card class="custom-card border-round-xl" style="background: linear-gradient(135deg, var(--p-primary-500) 0%, var(--p-primary-700) 100%); color: white;">
        <template #title>
          <div style="font-size: 1.1rem; opacity: 0.9;">系統總訪問次數</div>
        </template>
        <template #content>
          <div v-if="loading" style="font-size: 2.5rem; font-weight: bold; opacity: 0.8;">
            <i class="pi pi-spin pi-spinner"></i>
          </div>
          <div v-else class="count-val">
            {{ visitStats ? visitStats.count : 'N/A' }}
          </div>
        </template>
      </Card>
    </div>
  </div>
</template>

<style scoped>
.grid-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 1.5rem;
}
.card-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--p-surface-900);
}
.count-val {
  font-size: 3rem;
  font-weight: 800;
  line-height: 1.2;
}
</style>
