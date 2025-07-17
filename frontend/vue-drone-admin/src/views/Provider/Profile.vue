<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">👤 Hồ sơ nhà cung cấp</h2>

        <template v-if="loading">
            <div class="text-gray-500">Đang tải thông tin...</div>
        </template>

        <template v-else>
            <div class="mb-4">
                <label class="block mb-1">Ảnh đại diện</label>
                <div class="flex items-center space-x-4">
                    <img :src="avatarPreviewUrl" alt="Avatar" class="w-24 h-24 rounded-full border object-cover"
                        v-if="avatarPreviewUrl" />
                    <input type="file" @change="handleFileChange" accept="image/*" />
                </div>
            </div>

            <form @submit.prevent="updateProfile" class="space-y-4 max-w-md">
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
                <!-- <div>
                    <label class="block mb-1">Loại dịch vụ (cách nhau bằng dấu phẩy)</label>
                    <input v-model="serviceTypesInput" class="input" />
                </div> -->
                <button class="btn">Lưu thay đổi</button>
            </form>
        </template>

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
    service_types: [],
    avatar: ''
});

const serviceTypesInput = ref('');
const successMsg = ref('');
const errorMsg = ref('');

const avatarFile = ref(null);
const avatarPreviewUrl = ref('');

const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    avatarFile.value = file;
    avatarPreviewUrl.value = URL.createObjectURL(file);
};

const uploadAvatar = async () => {
    if (!avatarFile.value) return;

    const formData = new FormData();
    formData.append('avatar', avatarFile.value);

    try {
        const res = await axios.post('http://localhost:5000/api/provider/avatar/upload', formData, {
            headers: {
                Authorization: `Bearer ${token}`,
                'Content-Type': 'multipart/form-data'
            }
        });
        form.value.avatar = res.data.avatar;
    } catch (err) {
        console.error('Lỗi upload avatar:', err);
    }
};

const updateProfile = async () => {
    try {
        await uploadAvatar();

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

const loadProfile = async () => {
    try {
        const res = await axios.get('http://localhost:5000/api/provider/profile', { headers });
        form.value = res.data;
        serviceTypesInput.value = res.data.service_types?.join(', ') || '';
        avatarPreviewUrl.value = res.data.avatar ? 'http://localhost:5000' + res.data.avatar : '';
    } catch (err) {
        errorMsg.value = 'Lỗi khi tải hồ sơ';
    } finally {
        loading.value = false;
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
