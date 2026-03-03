<script setup lang="ts">
</script>

<template>
  <div class="layout-wrapper">
    <header class="header">
      <div class="logo">
        <i class="pi pi-box logo-icon"></i>
        <span>AIS Platform</span>
      </div>
      <div class="user-menu">
        <i class="pi pi-user p-mr-2"></i> 管理員
      </div>
    </header>

    <div class="main-container">
      <aside class="sidebar">
        <nav>
          <ul class="nav-list">
            <li>
              <router-link to="/" class="nav-item">
                <i class="pi pi-home"></i>
                <span>總覽面板</span>
              </router-link>
            </li>
            <li>
              <router-link to="/health" class="nav-item">
                <i class="pi pi-heart-fill"></i>
                <span>健康狀態</span>
              </router-link>
            </li>
            <li>
              <router-link to="/about" class="nav-item">
                <i class="pi pi-info-circle"></i>
                <span>關於系統</span>
              </router-link>
            </li>
          </ul>
        </nav>
      </aside>

      <main class="content">
        <slot></slot>
      </main>
    </div>
  </div>
</template>

<style scoped>
.layout-wrapper {
  display: flex;
  flex-direction: column;
  height: 100vh;
}

.header {
  height: 64px;
  background-color: var(--p-surface-0, #ffffff);
  border-bottom: 1px solid var(--p-surface-200, #e2e8f0);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 1.5rem;
  box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  z-index: 10;
}

.logo {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-weight: 700;
  font-size: 1.25rem;
  color: var(--p-primary-600, #0ea5e9);
}

.logo-icon {
  font-size: 1.5rem;
}

.user-menu {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--p-surface-600, #475569);
  font-weight: 500;
  cursor: pointer;
}

.main-container {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.sidebar {
  width: 260px;
  background-color: var(--p-surface-0, #ffffff);
  border-right: 1px solid var(--p-surface-200, #e2e8f0);
  padding: 1.5rem 1rem;
  box-shadow: 1px 0 2px 0 rgb(0 0 0 / 0.05);
  z-index: 5;
}

.nav-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  color: var(--p-surface-700, #334155);
  text-decoration: none;
  font-weight: 500;
  border-radius: 8px;
  transition: all 0.2s;
}

.nav-item:hover {
  background-color: var(--p-surface-100, #f1f5f9);
  color: var(--p-primary-600, #0ea5e9);
}

.nav-item.router-link-active {
  background-color: var(--p-primary-50, #f0f9ff);
  color: var(--p-primary-600, #0ea5e9);
  font-weight: 600;
}

.content {
  flex: 1;
  padding: 2rem;
  overflow-y: auto;
  background-color: var(--p-surface-50, #f8fafc);
}
</style>
