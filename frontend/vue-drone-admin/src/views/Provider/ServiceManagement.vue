<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">🛠 Quản lý Dịch vụ</h2>

        <!-- Chọn từ danh sách dịch vụ có sẵn -->
        <div class="bg-white p-4 rounded shadow-md mb-6">
            <h3 class="font-semibold mb-2">➕ Chọn dịch vụ để thêm</h3>
            <div class="grid grid-cols-2 gap-2">
                <label v-for="(item, index) in allAvailableServices" :key="index" class="flex items-center space-x-2">
                    <input type="checkbox" :value="item" v-model="selectedToAdd" />
                    <span>{{ item.name }}</span>
                </label>
            </div>
            <button class="btn mt-3" @click="addSelectedServices">Thêm các dịch vụ đã chọn</button>
        </div>

        <!-- Danh sách dịch vụ đã có -->
        <div v-if="services.length === 0" class="text-gray-500">Chưa có dịch vụ nào.</div>

        <div v-else class="space-y-4">
            <h3 class="font-semibold mb-2">✅ Dịch vụ đang cung cấp:</h3>

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
import { ref, onMounted } from 'vue'
import axios from 'axios'

const token = localStorage.getItem('token')
const headers = { Authorization: `Bearer ${token}` }

const services = ref([])
const selectedToAdd = ref([])

// Danh sách dịch vụ cố định ở frontend
const allAvailableServices = ref([
    { name: 'Phun thuốc', description: 'Dịch vụ phun thuốc trừ sâu' },
    { name: 'Bón phân', description: 'Dịch vụ bón phân hữu cơ/vô cơ' },
    { name: 'Khảo sát đất', description: 'Đánh giá chất lượng đất' },
    { name: 'Tưới tiêu', description: 'Lắp đặt/tư vấn hệ thống tưới' },
    { name: 'Gieo hạt', description: 'Dịch vụ gieo hạt giống tự động' }
])

const loadServices = async () => {
    const res = await axios.get('http://localhost:5000/api/provider/services', { headers })
    services.value = res.data
}

const addSelectedServices = async () => {
    const promises = []

    for (const item of selectedToAdd.value) {
        const exists = services.value.some(s => s.name === item.name)
        if (exists) continue

        promises.push(
            axios.post('http://localhost:5000/api/provider/services', {
                name: item.name,
                description: item.description
            }, { headers })
        )
    }

    try {
        await Promise.all(promises)
        selectedToAdd.value = []
        await loadServices()
    } catch (err) {
        alert('Lỗi khi thêm dịch vụ: ' + (err.response?.data?.message || err.message))
    }
}

const removeService = async (name) => {
    if (!confirm(`Xoá dịch vụ "${name}"?`)) return
    try {
        await axios.delete(`http://localhost:5000/api/provider/services/${encodeURIComponent(name)}`, { headers })
        await loadServices()
    } catch (err) {
        alert(err.response?.data?.message || 'Xoá thất bại')
    }
}

const editService = async (service) => {
    const newDesc = prompt('Nhập mô tả mới:', service.description || '')
    if (newDesc === null) return

    try {
        await axios.patch(`http://localhost:5000/api/provider/services/${encodeURIComponent(service.name)}`, { description: newDesc }, { headers })
        await loadServices()
    } catch (err) {
        alert(err.response?.data?.message || 'Cập nhật thất bại')
    }
}

onMounted(loadServices)
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
  
