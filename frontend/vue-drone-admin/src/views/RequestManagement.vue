// 📁 src/views/RequestManagement.vue
<template>
    <div>
        <h1 class="text-2xl font-bold mb-6">📋 Quản lý yêu cầu dịch vụ drone</h1>

        <div class="flex flex-wrap gap-4 mb-4">
            <select v-model="filterStatus" class="border px-3 py-2 rounded">
                <option value="">Tất cả trạng thái</option>
                <option value="PENDING">Chờ xử lý</option>
                <option value="ACCEPTED">Đã nhận</option>
                <option value="COMPLETED">Hoàn thành</option>
            </select>
            <input type="text" v-model="searchText" placeholder="Tìm theo vị trí..." class="border px-3 py-2 rounded" />
        </div>

        <div class="bg-white shadow rounded divide-y">
            <div v-for="req in filteredRequests" :key="req._id" class="p-4">
                <div class="flex justify-between items-center">
                    <div>
                        <h2 class="font-semibold text-lg">{{ req.service_type }} - {{ req.area_ha }}ha</h2>
                        <p class="text-sm text-gray-500">{{ req.field_location?.province || 'Không rõ vị trí' }} • {{
                            req.preferred_date }}</p>
                    </div>
                    <span class="text-sm px-3 py-1 rounded-full font-medium" :class="statusColor(req.status)">{{
                        req.status }}</span>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { getAllRequests } from '@/services/requestService';

const filterStatus = ref('');
const searchText = ref('');
const requests = ref([]);

onMounted(async () => {
    try {
        const res = await getAllRequests();
        requests.value = res.data;
        console.log('[DEBUG] Loaded requests:', requests.value);
    } catch (err) {
        console.error('Lỗi khi tải yêu cầu:', err);
    }
});

const filteredRequests = computed(() => {
    return requests.value.filter(r => {
        const province = r.field_location?.province || '';
        const matchStatus = filterStatus.value ? r.status === filterStatus.value : true;
        const matchText = province.toLowerCase().includes(searchText.value.toLowerCase());
        return matchStatus && matchText;
    });
});

function statusColor(status) {
    return {
        PENDING: 'bg-yellow-100 text-yellow-800',
        ACCEPTED: 'bg-blue-100 text-blue-800',
        COMPLETED: 'bg-green-100 text-green-800'
    }[status] || 'bg-gray-100 text-gray-600';
}
</script>

<style scoped></style>
