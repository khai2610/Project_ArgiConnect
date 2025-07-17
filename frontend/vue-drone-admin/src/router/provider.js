// src/router/provider.js
export default [
    {
      path: '/provider',
      component: () => import('@/layouts/provider/ProviderLayout.vue'),
      children: [
        { path: '', name: 'ProviderDashboard', component: () => import('@/views/provider/ProviderDashboard.vue') },
        { path: 'services', component: () => import('@/views/provider/ServiceManagement.vue') },
        { path: 'requests', component: () => import('@/views/provider/RequestList.vue') },
        { path: 'invoices', component: () => import('@/views/provider/InvoiceList.vue') },
        { path: 'profile', component: () => import('@/views/provider/Profile.vue') },
        { path: 'requests/:id', name: 'ProviderRequestDetail', component: () => import('@/views/provider/RequestDetail.vue') }, // ✅ thêm dòng này
        { path: 'invoices/:id', name: 'ProviderInvoiceDetail', component: () => import('@/views/provider/InvoiceDetail.vue') }
      ]
    },
    {
      path: '/provider/login',
      name: 'ProviderLogin',
      component: () => import('@/views/provider/ProviderLogin.vue')
    },
    {
      path: '/provider/register',
      name: 'ProviderRegister',
      component: () => import('@/views/provider/ProviderRegister.vue')
    }
  ];
  