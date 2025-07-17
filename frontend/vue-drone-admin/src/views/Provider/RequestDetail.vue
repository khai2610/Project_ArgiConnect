<template>
    <div>
        <!-- Tiêu đề + icon chat -->
        <div class="flex justify-between items-center mb-4">
            <h2 class="text-2xl font-bold">📄 Chi tiết yêu cầu</h2>
            <button @click="showChatPopup = true" class="text-blue-600 hover:text-blue-800 text-2xl" title="Mở chat">
                💬
            </button>
        </div>

        <!-- Popup chat -->
        <ChatPopup v-if="showChatPopup && request?.farmer_id" :farmer-id="request.farmer_id._id"
            @close="showChatPopup = false" />

        <div v-if="loading" class="text-gray-500">Đang tải chi tiết...</div>

        <div v-else-if="!request" class="text-red-500">Không tìm thấy yêu cầu.</div>

        <div v-else class="space-y-3">
            <p><strong>Dịch vụ:</strong> {{ request.service_type }}</p>
            <p><strong>Trạng thái:</strong> {{ request.status }}</p>
            <p><strong>Ngày yêu cầu:</strong> {{ formatDate(request.createdAt) }}</p>
            <p><strong>Nông dân:</strong> {{ request.farmer_id?.name || '---' }}</p>
            <p><strong>Địa điểm:</strong> {{ request.field_location?.province || '---' }}</p>
            <p><strong>Mô tả kết quả:</strong> {{ request.result?.description || '---' }}</p>

            <div class="flex items-center space-x-4 mt-4">
                <button @click="showChatPopup = true" class="btn-blue">💬 Nhắn tin</button>

                <button v-if="request.status === 'COMPLETED' && !hasInvoice" @click="createInvoice" class="btn-green">
                    🧾 Lập hóa đơn
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import axios from 'axios';
import ChatPopup from '@/components/ChatPopup.vue';

const route = useRoute();
const request = ref(null);
const hasInvoice = ref(false);
const loading = ref(true);
const showChatPopup = ref(false);

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const formatDate = (iso) => new Date(iso).toLocaleString('vi-VN');

const loadDetail = async () => {
    try {
        const res = await axios.get('http://localhost:5000/api/provider/requests', { headers });
        request.value = res.data.find(r => r._id === route.params.id);
        if (!request.value) return;

        const invoiceRes = await axios.get('http://localhost:5000/api/provider/invoices', { headers });
        hasInvoice.value = invoiceRes.data.some(i => i.service_request_id._id === request.value._id);
    } catch (err) {
        alert('Lỗi khi tải chi tiết yêu cầu');
    } finally {
        loading.value = false;
    }
};

const createInvoice = async () => {
    const amount = prompt('Nhập tổng tiền (VND):');
    if (!amount || isNaN(amount)) return alert('Số tiền không hợp lệ');

    try {
        await axios.post('http://localhost:5000/api/provider/invoices', {
            request_id: request.value._id,
            total_amount: Number(amount),
            note: ''
        }, { headers });

        alert('✅ Lập hóa đơn thành công!');
        hasInvoice.value = true;
    } catch (err) {
        alert(err.response?.data?.message || 'Lỗi khi lập hóa đơn');
    }
};

onMounted(loadDetail);
</script>

<style scoped>
.btn-blue {
    background-color: #3b82f6;
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 6px;
}

.btn-green {
    background-color: #22c55e;
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 6px;
}
</style>
