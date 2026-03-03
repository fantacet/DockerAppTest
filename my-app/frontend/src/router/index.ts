import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
    history: createWebHistory(),
    routes: [
        {
            path: '/',
            name: 'home',
            component: () => import('../views/DashboardView.vue'),
            meta: { title: '總覽' }
        },
        {
            path: '/health',
            name: 'health',
            component: () => import('../views/monitor/HealthView.vue'),
            meta: { title: '健康狀態' }
        },
        {
            path: '/about',
            name: 'about',
            component: () => import('../views/AboutView.vue'),
            meta: { title: '關於系統' }
        }
    ]
})

router.beforeEach((to, from, next) => {
    document.title = `${to.meta.title} - AIS Platform` || 'AIS Platform'
    next()
})

export default router
