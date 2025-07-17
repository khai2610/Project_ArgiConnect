<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import axios from 'axios';

const route = useRoute();
const invoice = ref(null);
const loading = ref(true);

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const loadDetail = async () => {
    try {
        const res = await axios.get('http://localhost:5000/api/provider/invoices', { headers });
        invoice.value = res.data.find(i => i._id === route.params.id);
    } catch (err) {
        alert('Lỗi khi tải chi tiết hóa đơn');
    } finally {
        loading.value = false;
    }
};

const formatDate = (iso) => {
    if (!iso) return '---';
    return new Date(iso).toLocaleDateString('vi-VN');
};

// ✅ Gửi tin nhắn nhắc thanh toán (gồm detail)
const notifyFarmer = async () => {
    const inv = invoice.value;
    const farmerId = inv.farmer_id._id;
    const providerId = inv.provider_id?._id || inv.provider_id;

    try {
        await axios.post(
            `http://localhost:5000/api/chat/between/${farmerId}/${providerId}`,
            {
                content: '🔔 Bạn có một hóa đơn chưa thanh toán.',
                action: {
                    type: 'PAYMENT',
                    invoiceId: inv._id,
                    detail: {
                        amount: inv.total_amount,
                        currency: inv.currency,
                        serviceType: inv.service_request_id?.service_type,
                        preferredDate: inv.service_request_id?.preferred_date,
                        note: inv.note
                    }
                }
            },
            { headers }
        );

        alert('✅ Đã gửi tin nhắn đến nông dân');
    } catch (err) {
        alert('❌ Lỗi khi gửi tin nhắn');
        console.error(err);
    }
};

onMounted(loadDetail);
</script>

<template>
    <div>
        <div v-if="loading" class="text-gray-500">Đang tải chi tiết hóa đơn...</div>
        <div v-else-if="!invoice" class="text-red-500">Không tìm thấy hóa đơn.</div>
        <div v-else class="space-y-4">
            <h2 class="text-2xl font-bold">🧾 Chi tiết Hóa đơn</h2>

            <div class="bg-white p-6 rounded shadow border space-y-3">
                <p><strong>💼 Nông dân:</strong> {{ invoice.farmer_id?.name || '---' }}</p>
                <p><strong>🛠 Dịch vụ:</strong> {{ invoice.service_request_id?.service_type || '---' }}</p>
                <p><strong>📅 Ngày yêu cầu:</strong> {{ formatDate(invoice.service_request_id?.preferred_date) }}</p>
                <p><strong>🧾 Ngày lập hóa đơn:</strong> {{ formatDate(invoice.createdAt) }}</p>
                <p><strong>💰 Tổng tiền:</strong> {{ invoice.total_amount.toLocaleString() }} {{ invoice.currency }}</p>
                <p><strong>📌 Trạng thái:</strong> {{ invoice.status }}</p>
                <p v-if="invoice.service_request_id?.result?.description">
                    📝 <strong>Mô tả từ nhà cung cấp:</strong>
                    {{ invoice.service_request_id.result.description }}
                </p>
                <p v-if="invoice.note" class="italic text-gray-600">🧾 Ghi chú: {{ invoice.note }}</p>
            </div>

            <button v-if="invoice.status === 'UNPAID'" @click="notifyFarmer" class="btn-orange">
                🔔 Gửi tin nhắn nhắc thanh toán
            </button>
        </div>
    </div>
</template>

<style scoped>
.btn-orange {
    background-color: #f97316;
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 6px;
}
</style>
