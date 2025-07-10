<template>
    <aside class="w-64 bg-[#1f2937] text-white h-screen p-6 flex flex-col items-center space-y-6">
        <!-- Logo -->
        <div class="flex flex-col items-center">
            <img src="/drone-icon.png" alt="Drone Logo" class="w-16 h-16 mb-2" />
            <h2 class="text-xl font-bold tracking-wide">DRONE ADMIN</h2>
        </div>

        <!-- Menu điều hướng -->
        <nav class="w-full space-y-2 flex-1">
            <router-link v-for="item in menu" :key="item.name" :to="item.to"
                class="block px-4 py-2 rounded transition text-sm font-medium" :class="isActive(item.to)
                    ? 'bg-white text-[#1f2937] font-bold shadow'
                    : 'text-gray-300 hover:bg-gray-700 hover:text-white'">
                {{ item.name }}
            </router-link>
        </nav>

        <!-- Nút đăng xuất -->
        <button @click="logout"
            class="w-full text-left px-4 py-2 rounded text-red-400 hover:bg-red-600 hover:text-white transition text-sm font-medium">
            🚪 Đăng xuất
        </button>
    </aside>
</template>

<script setup>
import { useRouter, useRoute } from 'vue-router';
const router = useRouter();
const route = useRoute();

const menu = [
    { name: 'Dashboard', to: '/admin' },
    { name: 'Yêu cầu dịch vụ', to: '/admin/requests' },
    { name: 'Nhà cung cấp', to: '/admin/providers' },
    { name: 'Nông dân', to: '/admin/farmers' },
    { name: 'Hóa đơn', to: '/admin/invoices' }
];

function isActive(path) {
    return route.path === path || (path !== '/admin' && route.path.startsWith(path));
}

function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('role'); // nếu dùng
    router.push('/admin/login');
}
</script>

<style scoped></style>
  
