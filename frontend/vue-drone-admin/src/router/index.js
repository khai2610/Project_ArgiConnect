// router/index.js
import { createRouter, createWebHistory } from 'vue-router';
import adminRoutes from './admin';
import providerRoutes from './provider';

const routes = [
  ...adminRoutes,     // ✅ Mảng route từ admin.js
  ...providerRoutes,  // ✅ Mảng route từ provider.js
  { path: '/', redirect: '/provider/login' },
  { path: '/:pathMatch(.*)*', redirect: '/provider/login' }
];

export default createRouter({
  history: createWebHistory(),
  routes
});
