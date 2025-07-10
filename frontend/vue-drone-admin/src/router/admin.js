// router/admin.js ✅ CHỈ export array
import Dashboard from '@/views/Dashboard.vue';

export default [
  {
    path: '/admin',
    component: () => import('@/layouts/AdminLayout.vue'),
    children: [
      { path: '', name: 'AdminDashboard', component: Dashboard },
      { path: 'requests', component: () => import('@/views/RequestManagement.vue') },
      { path: 'providers', component: () => import('@/views/ProviderManagement.vue') },
      { path: 'farmers', component: () => import('@/views/FarmerManagement.vue') },
      { path: 'invoices', component: () => import('@/views/InvoiceManagement.vue') },
    ]
  },
  {
    path: '/admin/login',
    name: 'AdminLogin',
    component: () => import('@/views/Login.vue')
  }
  
];
