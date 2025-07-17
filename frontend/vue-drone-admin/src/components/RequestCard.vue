<template>
    <div class="bg-white p-4 rounded shadow-md border hover:bg-gray-50 transition mb-2">
        <div class="flex justify-between items-center">
            <router-link :to="`/provider/requests/${req._id}`" class="block">
                <p class="font-semibold text-lg">{{ req.service_type }}</p>
                <p class="text-sm text-gray-600">Ngày yêu cầu: {{ formatDate(req.createdAt) }}</p>
                <p class="text-sm text-gray-600">Trạng thái: {{ req.status }}</p>
                <p class="text-sm text-gray-600">Nông dân: {{ req.farmer_id?.name || '---' }}</p>
            </router-link>
            <div class="space-x-2 ml-4">
                <button v-if="req.status === 'PENDING'" @click="accept(req._id)" class="btn-blue">✅ Nhận</button>
                <button v-if="req.status === 'ACCEPTED'" @click="complete(req._id)" class="btn-green">🏁 Hoàn
                    thành</button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { defineProps } from 'vue';
import axios from 'axios';

const props = defineProps({ req: Object });

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const formatDate = (iso) => new Date(iso).toLocaleString('vi-VN');

const accept = async (id) => {
    try {
        await axios.patch(`http://localhost:5000/api/provider/requests/${id}/accept`, {}, { headers });
        window.location.reload();
    } catch (err) {
        alert(err.response?.data?.message || 'Lỗi khi nhận yêu cầu');
    }
};

const complete = async (id) => {
    const description = prompt('Nhập mô tả kết quả:');
    if (!description) return;

    try {
        await axios.patch(`http://localhost:5000/api/provider/requests/${id}/complete`, {
            description,
            attachments: []
        }, { headers });
        window.location.reload();
    } catch (err) {
        alert(err.response?.data?.message || 'Lỗi khi hoàn thành');
    }
};
</script>

<style scoped>
.btn-blue {
    background-color: #3b82f6;
    color: white;
    padding: 0.4rem 1rem;
    border-radius: 6px;
}

.btn-green {
    background-color: #22c55e;
    color: white;
    padding: 0.4rem 1rem;
    border-radius: 6px;
}
</style>
