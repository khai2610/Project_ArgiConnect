// 📁 src/views/ProviderManagement.vue
<template>
    <div>
        <h1 class="text-2xl font-bold mb-6">👷 Quản lý nhà cung cấp</h1>

        <h2 class="text-lg font-semibold mb-2">Chờ duyệt</h2>
        <div v-if="pending.length === 0" class="text-sm text-gray-500 mb-4">Không có nhà cung cấp chờ duyệt.</div>
        <ul class="space-y-3 mb-8">
            <li v-for="p in pending" :key="p._id" class="border p-4 rounded bg-white">
                <div class="font-semibold">{{ p.company_name }}</div>
                <div class="text-sm text-gray-500">{{ p.email }}</div>
                <div class="mt-2 space-x-2">
                    <button @click="approve(p._id)" class="bg-green-600 text-white px-3 py-1 rounded">Duyệt</button>
                    <button @click="reject(p._id)" class="bg-red-600 text-white px-3 py-1 rounded">Từ chối</button>
                </div>
            </li>
        </ul>

        <h2 class="text-lg font-semibold mb-2">Tất cả nhà cung cấp</h2>
        <ul class="space-y-2">
            <li v-for="p in providers" :key="p._id" class="border p-4 rounded bg-white">
                <div class="font-semibold">{{ p.company_name }}</div>
                <div class="text-sm text-gray-500">{{ p.email }}</div>
            </li>
        </ul>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { getAllProviders, getPendingProviders, approveProvider, rejectProvider } from '@/services/providerService';

const providers = ref([]);
const pending = ref([]);

async function fetchData() {
    providers.value = (await getAllProviders()).data;
    pending.value = (await getPendingProviders()).data;
}

async function approve(id) {
    await approveProvider(id);
    fetchData();
}

async function reject(id) {
    await rejectProvider(id);
    fetchData();
}

onMounted(fetchData);
</script>

<style scoped></style>
