<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">🛠 Quản lý Dịch vụ</h2>

        <div class="bg-white p-4 rounded shadow-md mb-6">
            <h3 class="font-semibold mb-2">➕ Thêm dịch vụ</h3>
            <form @submit.prevent="addService" class="space-y-2">
                <input v-model="newService.name" placeholder="Tên dịch vụ" class="input" />
                <input v-model="newService.description" placeholder="Mô tả" class="input" />
                <button class="btn">Thêm</button>
            </form>
        </div>

        <div v-if="services.length === 0" class="text-gray-500">Chưa có dịch vụ nào.</div>

        <div v-else class="space-y-4">
            <div v-for="(service, index) in services" :key="index"
                class="bg-white p-4 rounded shadow-md flex justify-between items-center">
                <div>
                    <p class="font-semibold">{{ service.name }}</p>
                    <p class="text-sm text-gray-600">{{ service.description || 'Không có mô tả' }}</p>
                </div>
                <div class="flex items-center space-x-2">
                    <button @click="editService(service)" class="text-blue-500 hover:underline">✏️</button>
                    <button @click="removeService(service.name)" class="text-red-500 hover:underline">🗑</button>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const services = ref([]);
const newService = ref({ name: '', description: '' });

const loadServices = async () => {
    const res = await axios.get('http://localhost:5000/api/provider/services', { headers });
    services.value = res.data;
};

const addService = async () => {
    try {
        await axios.post('http://localhost:5000/api/provider/services', newService.value, { headers });
        newService.value = { name: '', description: '' };
        await loadServices();
    } catch (err) {
        alert(err.response?.data?.message || 'Thêm thất bại');
    }
};

const removeService = async (name) => {
    if (!confirm(`Xoá dịch vụ "${name}"?`)) return;
    try {
        await axios.delete(`http://localhost:5000/api/provider/services/${encodeURIComponent(name)}`, { headers });
        await loadServices();
    } catch (err) {
        alert(err.response?.data?.message || 'Xoá thất bại');
    }
};

const editService = async (service) => {
    const newDesc = prompt('Nhập mô tả mới:', service.description || '');
    if (newDesc === null) return;

    try {
        await axios.patch(`http://localhost:5000/api/provider/services/${encodeURIComponent(service.name)}`, { description: newDesc }, { headers });
        await loadServices();
    } catch (err) {
        alert(err.response?.data?.message || 'Cập nhật thất bại');
    }
};

onMounted(loadServices);
</script>

<style scoped>
.input {
    display: block;
    width: 100%;
    border: 1px solid #ccc;
    padding: 0.5rem;
    border-radius: 6px;
}

.btn {
    background: #22c55e;
    color: white;
    padding: 0.4rem 1rem;
    border-radius: 6px;
}
</style>
  
