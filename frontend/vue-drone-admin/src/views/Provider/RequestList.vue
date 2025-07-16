<template>
    <div>
        <!-- Tiêu đề + icon Chat bên phải -->
        <div class="flex justify-between items-center mb-4">
            <h2 class="text-2xl font-bold">📋 Danh sách yêu cầu dịch vụ</h2>
            <button @click="showChatPopup = true" class="text-blue-600 hover:text-blue-800 text-xl">
                💬
            </button>
        </div>

        <!-- ✅ Popup Chat -->
        <ChatPopup v-if="showChatPopup" @close="showChatPopup = false" />

        <!-- Danh sách yêu cầu -->
        <div v-if="loading" class="text-gray-500">Đang tải dữ liệu...</div>
        <div v-else-if="requests.length === 0" class="text-gray-500">Không có yêu cầu nào.</div>
        <div v-else class="space-y-4">
            <div v-for="req in requests" :key="req._id" class="bg-white p-4 rounded shadow-md border">
                <div class="flex justify-between items-center">
                    <div>
                        <p class="font-semibold text-lg">{{ req.service_type }}</p>
                        <p class="text-sm text-gray-600">Ngày yêu cầu: {{ formatDate(req.createdAt) }}</p>
                        <p class="text-sm text-gray-600">Trạng thái: <strong>{{ req.status }}</strong></p>
                        <p class="text-sm text-gray-600">Thanh toán: {{ req.payment_status || '---' }}</p>
                        <p class="text-sm text-gray-600">Nông dân: {{ req.farmer_id?.name || '---' }}</p>
                    </div>
                    <div class="space-x-2">
                        <button v-if="req.status === 'PENDING'" @click="accept(req._id)" class="btn-blue">✅
                            Nhận</button>
                        <button v-if="req.status === 'ACCEPTED'" @click="complete(req._id)" class="btn-green">🏁 Hoàn
                            thành</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';
import ChatPopup from '@/components/ChatPopup.vue';

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const requests = ref([]);
const loading = ref(true);
const showChatPopup = ref(false);

const loadRequests = async () => {
    try {
        const res = await axios.get('http://localhost:5000/api/provider/requests', { headers });
        requests.value = res.data;
    } catch (err) {
        alert('Lỗi khi tải yêu cầu');
    } finally {
        loading.value = false;
    }
};

const accept = async (id) => {
    try {
        await axios.patch(`http://localhost:5000/api/provider/requests/${id}/accept`, {}, { headers });
        await loadRequests();
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
        await loadRequests();
    } catch (err) {
        alert(err.response?.data?.message || 'Lỗi khi hoàn thành');
    }
};

const formatDate = (iso) => new Date(iso).toLocaleString('vi-VN');

onMounted(loadRequests);
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
  
