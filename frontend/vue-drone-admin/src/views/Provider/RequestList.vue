<template>
    <div>
        <!-- Tiêu đề -->
        <div class="flex justify-between items-center mb-4">
            <h2 class="text-2xl font-bold">📋 Danh sách yêu cầu dịch vụ</h2>
            <button @click="showChatPopup = true" class="text-blue-600 hover:text-blue-800 text-xl">💬</button>
        </div>

        <!-- Chat popup -->
        <ChatPopup v-if="showChatPopup" @close="showChatPopup = false" />

        <!-- Loading -->
        <div v-if="loading" class="text-gray-500">Đang tải dữ liệu...</div>

        <!-- Danh sách theo nhóm -->
        <div v-else>
            <!-- 📦 Yêu cầu đã nhận -->
            <div v-if="acceptedRequests.length" class="mb-6">
                <div class="flex justify-between items-center mb-2">
                    <h3 class="text-xl font-semibold">📦 Yêu cầu đã nhận</h3>
                    <select v-model="filterInvoiceStatus" class="border rounded px-2 py-1 text-sm">
                        <option value="">Tất cả</option>
                        <option value="yes">Đã lập hóa đơn</option>
                        <option value="no">Chưa có hóa đơn</option>
                    </select>
                </div>

                <RequestCard v-for="r in filteredAcceptedRequests" :key="r._id" :req="r" />
            </div>

            <!-- 📬 Yêu cầu được chỉ định -->
            <div v-if="assignedRequests.length" class="mb-6">
                <h3 class="text-xl font-semibold mb-2">📬 Yêu cầu được chỉ định</h3>
                <RequestCard v-for="r in assignedRequests" :key="r._id" :req="r" />
            </div>

            <!-- 🌐 Yêu cầu tự do -->
            <div v-if="openRequests.length" class="mb-6">
                <h3 class="text-xl font-semibold mb-2">🌐 Yêu cầu tự do</h3>
                <RequestCard v-for="r in openRequests" :key="r._id" :req="r" />
            </div>

            <div v-if="!acceptedRequests.length && !assignedRequests.length && !openRequests.length"
                class="text-gray-500">
                Không có yêu cầu nào.
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';
import ChatPopup from '@/components/ChatPopup.vue';
import RequestCard from '@/components/RequestCard.vue';

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const acceptedRequests = ref([]);
const assignedRequests = ref([]);
const openRequests = ref([]);
const invoices = ref([]);
const invoiceMap = ref({});

const loading = ref(true);
const showChatPopup = ref(false);
const filterInvoiceStatus = ref(''); // '', 'yes', 'no'

const loadRequests = async () => {
    try {
        const res = await axios.get('http://localhost:5000/api/provider/requests', { headers });
        const all = res.data;
        const myId = JSON.parse(atob(token.split('.')[1])).id;

        // Lấy danh sách hóa đơn
        const invoiceRes = await axios.get('http://localhost:5000/api/provider/invoices', { headers });
        invoices.value = invoiceRes.data;
        invoiceMap.value = Object.fromEntries(
            invoices.value.map(i => [i.service_request_id._id, i])
        );

        // Phân loại yêu cầu
        assignedRequests.value = all.filter(r => {
            const pid = r.provider_id?._id || r.provider_id;
            return pid === myId && r.status === 'PENDING';
        });

        acceptedRequests.value = all.filter(r => {
            const pid = r.provider_id?._id || r.provider_id;
            return pid === myId && ['ACCEPTED', 'COMPLETED'].includes(r.status);
        });

        openRequests.value = all.filter(r => !r.provider_id && r.status === 'PENDING');

    } catch (err) {
        console.error('Lỗi khi tải yêu cầu:', err);
        alert('Không thể tải yêu cầu');
    } finally {
        loading.value = false;
    }
};

// ✅ Danh sách yêu cầu đã nhận có lọc theo hóa đơn
const filteredAcceptedRequests = computed(() => {
    return acceptedRequests.value.filter(r => {
        const hasInvoice = !!invoiceMap.value[r._id];
        if (filterInvoiceStatus.value === 'yes') return hasInvoice;
        if (filterInvoiceStatus.value === 'no') return !hasInvoice;
        return true;
    });
});

onMounted(loadRequests);
</script>

<style scoped>
select {
    min-width: 150px;
}
</style>
