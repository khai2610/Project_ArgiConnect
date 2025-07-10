<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">🧾 Danh sách Hóa đơn</h2>

        <div v-if="loading" class="text-gray-500">Đang tải hóa đơn...</div>
        <div v-else-if="invoices.length === 0" class="text-gray-500">Chưa có hóa đơn nào.</div>

        <div v-else class="space-y-4">
            <div v-for="inv in invoices" :key="inv._id" class="bg-white p-4 rounded shadow-md border">
                <div class="flex justify-between items-start">
                    <div>
                        <p class="font-semibold text-lg">💼 Nông dân: {{ inv.farmer_id?.name || '---' }}</p>
                        <p class="text-sm text-gray-600">Loại dịch vụ: {{ inv.service_request_id?.service_type }}</p>
                        <p class="text-sm text-gray-600">Ngày yêu cầu: {{
                            formatDate(inv.service_request_id?.preferred_date) }}</p>
                        <p class="text-sm text-gray-600">Trạng thái: <strong>{{ inv.status }}</strong></p>
                    </div>
                    <div class="text-right">
                        <p class="text-lg font-bold text-green-600">{{ inv.total_amount.toLocaleString() }} {{
                            inv.currency }}</p>
                        <p class="text-sm text-gray-500">{{ formatDate(inv.createdAt) }}</p>
                    </div>
                </div>
                <p class="text-sm mt-2 text-gray-600 italic" v-if="inv.note">📝 Ghi chú: {{ inv.note }}</p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const invoices = ref([]);
const loading = ref(true);

const loadInvoices = async () => {
    try {
        const res = await axios.get('http://localhost:5000/api/provider/invoices', { headers });
        invoices.value = res.data;
    } catch (err) {
        alert('Lỗi khi tải hóa đơn');
    } finally {
        loading.value = false;
    }
};

const formatDate = (iso) => new Date(iso).toLocaleDateString('vi-VN');

onMounted(loadInvoices);
</script>
  
