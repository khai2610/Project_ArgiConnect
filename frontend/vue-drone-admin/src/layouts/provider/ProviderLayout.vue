<template>
    <div class="flex min-h-screen">
        <!-- Sidebar cố định -->
        <aside class="w-64 h-screen fixed top-0 left-0 bg-slate-800 text-white p-6 flex flex-col justify-between">
            <!-- Menu -->
            <div>
                <h1 class="text-2xl font-bold mb-6">Provider</h1>
                <nav class="space-y-2">
                    <RouterLink v-for="item in menu" :key="item.to" :to="item.to"
                        class="block px-3 py-2 rounded transition" :class="isActive(item.to)
                            ? 'bg-cyan-600 text-white font-semibold'
                            : 'text-gray-300 hover:bg-cyan-700 hover:text-white'">
                        {{ item.label }}
                    </RouterLink>
                </nav>
            </div>

            <!-- Logout -->
            <button @click="logout" class="block w-full px-3 py-2 rounded transition text-sm font-medium
            text-red-400 hover:bg-red-600 hover:text-white">
                🚪 Đăng xuất
            </button>
        </aside>

        <!-- Main Content dịch sang phải -->
        <main class="ml-64 flex-1 p-6 bg-gray-50">
            <router-view />
        </main>
    </div>
</template>
  

<script setup>
import { useRouter, useRoute } from 'vue-router';
const router = useRouter();
const route = useRoute();

const menu = [
    { label: '🏠 Dashboard', to: '/provider' },
    { label: '🛠 Dịch vụ', to: '/provider/services' },
    { label: '📋 Yêu cầu', to: '/provider/requests' },
    { label: '🧾 Hóa đơn', to: '/provider/invoices' },
    { label: '👤 Hồ sơ', to: '/provider/profile' }
];

const isActive = (path) => {
    if (path === '/provider') {
        return route.path === '/provider'; // chỉ chính xác
    }
    return route.path.startsWith(path);
};


const logout = () => {
    localStorage.removeItem('token');
    router.push('/provider/login');
};
</script>
  
