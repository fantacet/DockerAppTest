<script setup lang="ts">
import { ref, onMounted } from 'vue';
import axios from 'axios';
import Card from 'primevue/card';

const healthStatus = ref<any>(null);
const loading = ref(true);

const checkHealth = async () => {
    try {
        const response = await axios.get('/api/health');
        healthStatus.value = response.data;
    } catch(err) {
        healthStatus.value = { status: 'Error', error: String(err) };
    } finally {
        loading.value = false;
    }
}

onMounted(() => {
    checkHealth();
})
</script>

<template>
    <div>
        <h1 style="color: var(--p-surface-900); font-size: 2rem; font-weight: 700; margin-bottom: 2rem;">服務健康狀態</h1>
        
        <Card class="shadow-sm border-round-xl">
            <template #title>
              <div style="display:flex; align-items:center; gap: 0.5rem">
                <i class="pi pi-heart-fill" :style="{ color: healthStatus?.status === 'Healthy' ? 'var(--p-green-500)' : 'var(--p-red-500)' }"></i>
                <span>API Health Check</span>
              </div>
            </template>
            <template #content>
                <div v-if="loading" class="flex align-items-center justify-content-center p-4">
                    <i class="pi pi-spin pi-spinner" style="font-size: 2rem"></i>
                </div>
                <template v-else-if="healthStatus">
                    <pre style="background-color: var(--p-surface-100); padding: 1rem; border-radius: 8px; overflow-x: auto; color: var(--p-surface-800); font-family: monospace;">{{ JSON.stringify(healthStatus, null, 2) }}</pre>
                </template>
                <template v-else>
                    <div style="color: var(--p-surface-500)">目前無法取得健康狀態資訊。</div>
                </template>
            </template>
        </Card>
    </div>
</template>
