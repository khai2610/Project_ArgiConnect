<template>
    <div>
        <!-- Tiêu đề + Bộ lọc -->
        <div class="flex justify-between items-center mb-4 gap-4 flex-wrap">
            <h2 class="text-2xl font-bold">🧾 Danh sách Hóa đơn</h2>

            <div class="flex items-center gap-2">
                <label class="text-sm font-medium">Trạng thái:</label>
                <select v-model="filterStatus" class="border rounded px-2 py-1 text-sm">
                    <option value="">Tất cả</option>
                    <option value="PAID">Đã thanh toán</option>
                    <option value="UNPAID">Chưa thanh toán</option>
                </select>
            </div>

            <div class="flex items-center gap-2">
                <label class="text-sm font-medium">Sắp xếp:</label>
                <select v-model="sortOrder" class="border rounded px-2 py-1 text-sm">
                    <option value="newest">Mới nhất</option>
                    <option value="oldest">Cũ nhất</option>
                </select>
            </div>
        </div>

        <!-- Nội dung -->
        <div v-if="loading" class="text-gray-500">Đang tải hóa đơn...</div>
        <div v-else-if="sortedInvoices.length === 0" class="text-gray-500">Không có hóa đơn phù hợp.</div>

        <div v-else class="space-y-4">
            <router-link v-for="inv in sortedInvoices" :key="inv._id" :to="`/provider/invoices/${inv._id}`"
                class="block bg-white p-4 rounded shadow-md border hover:bg-gray-50 transition">
                <div class="flex justify-between items-start">
                    <div>
                        <p class="font-semibold text-lg">💼 Nông dân: {{ inv.farmer_id?.name || '---' }}</p>
                        <p class="text-sm text-gray-600">Loại dịch vụ: {{ inv.service_request_id?.service_type }}</p>
                        <p class="text-sm text-gray-600">
                            Ngày yêu cầu: {{ formatDate(inv.service_request_id?.preferred_date) }}
                        </p>
                        <p class="text-sm text-gray-600">Trạng thái: <strong>{{ inv.status }}</strong></p>
                    </div>
                    <div class="text-right">
                        <p class="text-lg font-bold text-green-600">
                            {{ inv.total_amount.toLocaleString() }} {{ inv.currency }}
                        </p>
                        <p class="text-sm text-gray-500">{{ formatDate(inv.createdAt) }}</p>
                    </div>
                </div>
                <p class="text-sm mt-2 text-gray-600 italic" v-if="inv.note">📝 Ghi chú: {{ inv.note }}</p>
            </router-link>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import axios from 'axios';

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const invoices = ref([]);
const loading = ref(true);
const filterStatus = ref('');
const sortOrder = ref('newest');

// ✅ Bước 1: lọc theo trạng thái
const filteredInvoices = computed(() => {
    if (!filterStatus.value) return invoices.value;
    return invoices.value.filter(inv => inv.status === filterStatus.value);
});

// ✅ Bước 2: sắp xếp
const sortedInvoices = computed(() => {
    const list = [...filteredInvoices.value];
    return list.sort((a, b) => {
        const dA = new Date(a.createdAt);
        const dB = new Date(b.createdAt);
        return sortOrder.value === 'newest' ? dB - dA : dA - dB;
    });
});

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

const formatDate = (iso) => {
    if (!iso) return '---';
    return new Date(iso).toLocaleDateString('vi-VN');
};

onMounted(loadInvoices);
</script>
