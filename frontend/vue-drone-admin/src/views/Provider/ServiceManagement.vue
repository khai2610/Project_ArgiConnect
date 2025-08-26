<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">🛠 Quản lý Dịch vụ</h2>

        <div class="flex gap-4 items-stretch">
            <!-- LEFT: Main (5) -->
            <section class="flex-[5] bg-white p-4 rounded shadow-md flex flex-col h-[72vh]">
                <!-- Tools -->
                <div class="flex items-center gap-2 mb-4">
                    <input v-model="q" type="text" placeholder="Tìm theo tên dịch vụ…" class="input flex-1" />
                    <button class="btn" @click="reload">↻ Tải lại</button>
                </div>

                <!-- Empty -->
                <div v-if="filteredServices.length === 0" class="text-gray-500 italic">
                    Chưa có dịch vụ nào (hoặc không khớp bộ lọc).
                </div>

                <!-- List -->
                <div v-else class="flex-1 overflow-auto space-y-3 pr-1">
                    <div v-for="(service, index) in filteredServices" :key="service.name + index"
                        class="rounded border border-gray-100 hover:border-gray-200 p-3">
                        <!-- Header -->
                        <div class="flex justify-between items-start">
                            <div class="min-w-0">
                                <p class="font-semibold truncate">{{ service.name }}</p>
                                <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
                                    <p class="text-sm text-gray-600 break-words">
                                        {{ service.description || 'Không có mô tả' }}
                                    </p>
                                    <span class="text-sm text-emerald-700 font-semibold">
                                        • Giá: {{ formatCurrency(service.price) }} / {{ service.unit || 'VNĐ/ha' }}
                                    </span>
                                </div>
                            </div>
                            <div class="flex items-center gap-2 shrink-0">
                                <button @click="toggleEdit(index)"
                                    class="px-2 py-1 rounded bg-blue-50 text-blue-600 hover:bg-blue-100">✏️ Sửa</button>
                                <button @click="removeService(service.name)"
                                    class="px-2 py-1 rounded bg-red-50 text-red-600 hover:bg-red-100">🗑 Xoá</button>
                            </div>
                        </div>

                        <!-- Form chỉnh sửa -->
                        <div v-if="editingIndex === index" class="mt-3 p-3 bg-gray-50 rounded">
                            <label class="block text-sm font-medium text-gray-700">Mô tả</label>
                            <textarea v-model="editForm.description" class="input w-full mb-2"></textarea>

                            <label class="block text-sm font-medium text-gray-700">Giá (VND)</label>
                            <input v-model.number="editForm.price" type="number" min="0" step="1000"
                                class="input w-full mb-2" />

                            <label class="block text-sm font-medium text-gray-700">Đơn vị</label>
                            <input v-model="editForm.unit" class="input w-full mb-3" />

                            <div class="flex gap-2">
                                <button class="btn" @click="saveEdit(service.name)">💾 Lưu</button>
                                <button class="px-3 py-2 rounded bg-gray-200 hover:bg-gray-300" @click="cancelEdit">
                                    ❌ Huỷ
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Add custom -->
                <div class="mt-4 pt-4 border-t border-gray-100">
                    <h3 class="font-semibold mb-2">➕ Thêm dịch vụ tuỳ chỉnh</h3>
                    <div class="grid grid-cols-1 md:grid-cols-4 gap-2">
                        <input v-model="newService.name" class="input md:col-span-1" placeholder="Tên dịch vụ" />
                        <input v-model="newService.description" class="input md:col-span-2" placeholder="Mô tả" />
                        <input v-model.number="newService.price" type="number" min="0" step="1000"
                            class="input md:col-span-1" placeholder="Giá (VND)" />
                    </div>
                    <button class="btn mt-3" @click="addCustomService">Thêm</button>
                </div>
            </section>

            <!-- RIGHT: Stats + Presets (3) -->
            <aside class="flex-[3] flex flex-col gap-4 max-h-[72vh] overflow-auto">
                <!-- Stats -->
                <div class="bg-white p-4 rounded shadow-md">
                    <h3 class="font-semibold text-gray-700">📊 Thống kê</h3>
                    <div class="mt-2 grid grid-cols-3 gap-4">
                        <div>
                            <p class="text-xs text-gray-500">Tổng dịch vụ</p>
                            <p class="text-xl font-bold">{{ services.length }}</p>
                        </div>
                        <div>
                            <p class="text-xs text-gray-500">Đang chọn thêm</p>
                            <p class="text-xl font-bold text-cyan-600">{{ selectedToAdd.length }}</p>
                        </div>
                        <div>
                            <p class="text-xs text-gray-500">Trùng (bỏ qua)</p>
                            <p class="text-xl font-bold text-amber-600">{{ dupCount }}</p>
                        </div>
                    </div>
                </div>

                <!-- Presets -->
                <div class="bg-white p-4 rounded shadow-md">
                    <div class="flex justify-between items-center mb-2">
                        <h3 class="font-semibold">🧩 Chọn dịch vụ có sẵn</h3>
                        <button class="px-2 py-1 rounded bg-gray-100 hover:bg-gray-200 text-sm" @click="toggleAll">
                            {{ allChecked ? 'Bỏ chọn' : 'Chọn tất cả' }}
                        </button>
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                        <label v-for="(item, index) in allAvailableServices" :key="item.name + index"
                            class="flex items-start gap-2 p-2 rounded border border-gray-100 hover:border-gray-200">
                            <input type="checkbox" :value="item" v-model="selectedToAdd" />
                            <div class="min-w-0">
                                <div class="flex items-center gap-2">
                                    <p class="font-medium truncate">{{ item.name }}</p>
                                    <span class="text-xs text-emerald-700 font-semibold">
                                        {{ formatCurrency(item.price) }}
                                    </span>
                                </div>
                                <p class="text-xs text-gray-600 break-words">{{ item.description }}</p>
                            </div>
                        </label>
                    </div>

                    <button class="btn mt-3" :disabled="selectedToAdd.length === 0" @click="addSelectedServices">
                        ➕ Thêm các dịch vụ đã chọn
                    </button>
                </div>
            </aside>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import axios from 'axios'

const token = localStorage.getItem('token')
const headers = { Authorization: `Bearer ${token}` }

const services = ref([])
const q = ref('')
const selectedToAdd = ref([])

const allAvailableServices = ref([
    { name: 'Phun thuốc', description: 'Dịch vụ phun thuốc trừ sâu', price: 150000 },
    { name: 'Bón phân', description: 'Dịch vụ bón phân hữu cơ/vô cơ', price: 120000 },
    { name: 'Khảo sát đất', description: 'Đánh giá chất lượng đất', price: 200000 },
    { name: 'Tưới tiêu', description: 'Lắp đặt/tư vấn hệ thống tưới', price: 180000 },
    { name: 'Gieo hạt', description: 'Dịch vụ gieo hạt giống tự động', price: 140000 }
])

const newService = ref({ name: '', description: '', price: 0 })

// Edit mode
const editingIndex = ref(null)
const editForm = ref({ description: '', price: 0, unit: 'VNĐ/ha' })

const filteredServices = computed(() => {
    const s = q.value.trim().toLowerCase()
    if (!s) return services.value
    return services.value.filter(x => x.name?.toLowerCase().includes(s))
})

const dupCount = computed(() => {
    const set = new Set(services.value.map(s => s.name))
    return selectedToAdd.value.filter(x => set.has(x.name)).length
})

const allChecked = computed(() =>
    selectedToAdd.value.length === allAvailableServices.value.length
)

const toggleAll = () => {
    if (allChecked.value) selectedToAdd.value = []
    else selectedToAdd.value = [...allAvailableServices.value]
}

const formatCurrency = (v) =>
    (Number(v) || 0).toLocaleString('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 })

const loadServices = async () => {
    const res = await axios.get('http://localhost:5000/api/provider/services', { headers })
    services.value = (res.data || []).map(s => ({ price: 0, unit: 'VNĐ/ha', ...s }))
}

const reload = async () => { await loadServices() }

const addSelectedServices = async () => {
    const exists = new Set(services.value.map(s => s.name))
    const toCreate = selectedToAdd.value.filter(item => !exists.has(item.name))
    if (toCreate.length === 0) {
        selectedToAdd.value = []
        return
    }
    try {
        await Promise.all(
            toCreate.map(item =>
                axios.post('http://localhost:5000/api/provider/services',
                    { name: item.name, description: item.description, price: item.price ?? 0, unit: 'VNĐ/ha' },
                    { headers }
                )
            )
        )
        selectedToAdd.value = []
        await loadServices()
    } catch (err) {
        alert('Lỗi khi thêm dịch vụ: ' + (err.response?.data?.message || err.message))
    }
}

const addCustomService = async () => {
    const payload = {
        name: (newService.value.name || '').trim(),
        description: (newService.value.description || '').trim(),
        price: Number(newService.value.price) || 0,
        unit: 'VNĐ/ha'
    }
    if (!payload.name) return alert('Vui lòng nhập tên dịch vụ')
    if (services.value.some(s => s.name === payload.name)) {
        return alert('Tên dịch vụ đã tồn tại')
    }
    try {
        await axios.post('http://localhost:5000/api/provider/services', payload, { headers })
        newService.value = { name: '', description: '', price: 0 }
        await loadServices()
    } catch (err) {
        alert('Lỗi khi thêm: ' + (err.response?.data?.message || err.message))
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

const toggleEdit = (index) => {
    if (editingIndex.value === index) {
        editingIndex.value = null
    } else {
        const s = filteredServices.value[index]
        editForm.value = {
            description: s.description || '',
            price: s.price || 0,
            unit: s.unit || 'VNĐ/ha'
        }
        editingIndex.value = index
    }
}

const cancelEdit = () => {
    editingIndex.value = null
}

const saveEdit = async (serviceName) => {
    try {
        await axios.patch(
            `http://localhost:5000/api/provider/services/${encodeURIComponent(serviceName)}`,
            editForm.value,
            { headers }
        )
        await loadServices()
        editingIndex.value = null
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
    border: 1px solid #e5e7eb;
    padding: 0.5rem 0.75rem;
    border-radius: 6px;
    outline: none;
}

.input:focus {
    border-color: #94a3b8;
}

.btn {
    background: #22c55e;
    color: white;
    padding: 0.45rem 1rem;
    border-radius: 6px;
}

.btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}
</style>
