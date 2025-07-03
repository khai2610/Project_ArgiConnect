import { createRouter, createWebHistory } from 'vue-router';

import Dashboard from '@/views/Dashboard.vue';

const routes = [
  {
    path: '/admin',
    component: () => import('@/layouts/AdminLayout.vue'),
    children: [
      { path: '', name: 'Dashboard', component: Dashboard },
      { path: 'requests', component: () => import('@/views/RequestManagement.vue') },
      { path: 'providers', component: () => import('@/views/ProviderManagement.vue') },
      { path: 'farmers', component: () => import('@/views/FarmerManagement.vue') },
      { path: 'invoices', component: () => import('@/views/InvoiceManagement.vue') },
    ]
  },
  { path: '/login', component: () => import('@/views/Login.vue') },
  { path: '/:pathMatch(.*)*', redirect: '/admin' }
];

export default createRouter({
  history: createWebHistory(),
  routes
});
