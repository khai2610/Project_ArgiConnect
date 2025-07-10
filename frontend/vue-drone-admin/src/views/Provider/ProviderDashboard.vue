<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">📊 Tổng quan nhà cung cấp</h2>

        <div v-if="loading" class="text-gray-500">Đang tải dữ liệu...</div>

        <div v-else>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div class="bg-white shadow-md rounded-xl p-4">
                    <h3 class="text-lg font-semibold text-gray-700">🏢 Công ty</h3>
                    <p class="text-gray-900">{{ provider.company_name }}</p>
                </div>
                <div class="bg-white shadow-md rounded-xl p-4">
                    <h3 class="text-lg font-semibold text-gray-700">🛠 Số dịch vụ</h3>
                    <p class="text-gray-900">{{ provider.services.length }}</p>
                </div>
                <div class="bg-white shadow-md rounded-xl p-4">
                    <h3 class="text-lg font-semibold text-gray-700">📋 Tổng yêu cầu</h3>
                    <p class="text-gray-900">{{ requestCount }}</p>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

const provider = ref({});
const requestCount = ref(0);
const loading = ref(true);

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

onMounted(async () => {
    try {
        const profileRes = await axios.get('http://localhost:5000/api/provider/profile', { headers });
        provider.value = profileRes.data;

        const requestRes = await axios.get('http://localhost:5000/api/provider/requests', { headers });
        requestCount.value = requestRes.data.length;
    } catch (err) {
        console.error('Lỗi khi tải dashboard:', err);
    } finally {
        loading.value = false;
    }
});
</script>
  
