<template>
    <div class="p-8 max-w-md mx-auto">
        <h2 class="text-2xl font-bold mb-4">Đăng ký Nhà cung cấp</h2>
        <form @submit.prevent="handleRegister">
            <input v-model="company_name" placeholder="Tên công ty" class="input" />
            <input v-model="email" type="email" placeholder="Email" class="input" />
            <input v-model="phone" placeholder="Số điện thoại" class="input" />
            <input v-model="address" placeholder="Địa chỉ" class="input" />
            <input v-model="password" type="password" placeholder="Mật khẩu" class="input" />
            <button class="btn">Đăng ký</button>
        </form>
        <p class="mt-2 text-sm text-red-500" v-if="error">{{ error }}</p>
    </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { registerProvider } from '@/services/provider/authService';

const company_name = ref('');
const email = ref('');
const phone = ref('');
const address = ref('');
const password = ref('');
const error = ref('');
const router = useRouter();

const handleRegister = async () => {
    try {
        await registerProvider({ company_name: company_name.value, email: email.value, phone: phone.value, address: address.value, password: password.value });
        router.push('/provider/login');
    } catch (err) {
        error.value = err.response?.data?.message || 'Đăng ký thất bại';
    }
};
</script>

<style scoped>
.input {
    display: block;
    margin-bottom: 1rem;
    padding: 0.5rem;
    width: 100%;
    border: 1px solid #ccc;
    border-radius: 4px;
}

.btn {
    background: #4ade80;
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 4px;
}
</style>
  
