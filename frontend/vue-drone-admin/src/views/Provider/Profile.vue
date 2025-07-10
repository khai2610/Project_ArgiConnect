<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">👤 Hồ sơ nhà cung cấp</h2>

        <div v-if="loading" class="text-gray-500">Đang tải thông tin...</div>

        <form v-else @submit.prevent="updateProfile" class="space-y-4 max-w-md">
            <div>
                <label class="block mb-1">Tên công ty</label>
                <input v-model="form.company_name" class="input" />
            </div>
            <div>
                <label class="block mb-1">Email</label>
                <input :value="form.email" disabled class="input bg-gray-100" />
            </div>
            <div>
                <label class="block mb-1">Số điện thoại</label>
                <input v-model="form.phone" class="input" />
            </div>
            <div>
                <label class="block mb-1">Địa chỉ</label>
                <input v-model="form.address" class="input" />
            </div>
            <div>
                <label class="block mb-1">Loại dịch vụ (cách nhau bằng dấu phẩy)</label>
                <input v-model="serviceTypesInput" class="input" />
            </div>
            <button class="btn">Lưu thay đổi</button>
        </form>

        <p class="text-green-600 mt-4" v-if="successMsg">{{ successMsg }}</p>
        <p class="text-red-500 mt-4" v-if="errorMsg">{{ errorMsg }}</p>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const loading = ref(true);
const form = ref({
    company_name: '',
    email: '',
    phone: '',
    address: '',
    service_types: []
});

const serviceTypesInput = ref('');
const successMsg = ref('');
const errorMsg = ref('');

const loadProfile = async () => {
    try {
        const res = await axios.get('http://localhost:5000/api/provider/profile', { headers });
        form.value = res.data;
        serviceTypesInput.value = res.data.service_types?.join(', ') || '';
    } catch (err) {
        errorMsg.value = 'Lỗi khi tải hồ sơ';
    } finally {
        loading.value = false;
    }
};

const updateProfile = async () => {
    try {
        const updatedData = {
            ...form.value,
            service_types: serviceTypesInput.value.split(',').map(s => s.trim())
        };
        await axios.patch('http://localhost:5000/api/provider/profile', updatedData, { headers });
        successMsg.value = 'Cập nhật thành công!';
        errorMsg.value = '';
    } catch (err) {
        successMsg.value = '';
        errorMsg.value = err.response?.data?.message || 'Cập nhật thất bại';
    }
};

onMounted(loadProfile);
</script>

<style scoped>
.input {
    display: block;
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #ccc;
    border-radius: 6px;
}

.btn {
    background-color: #3b82f6;
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 6px;
}
</style>
  
