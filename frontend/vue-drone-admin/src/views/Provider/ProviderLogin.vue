<template>
    <div class="p-8 max-w-md mx-auto">
        <h2 class="text-2xl font-bold mb-4">Đăng nhập Nhà cung cấp</h2>
        <form @submit.prevent="handleLogin">
            <input v-model="email" type="email" placeholder="Email" class="input" />
            <input v-model="password" type="password" placeholder="Mật khẩu" class="input" />
            <button class="btn">Đăng nhập</button>
        </form>
        <p class="mt-2 text-sm text-red-500" v-if="error">{{ error }}</p>
        <p class="mt-4 text-sm text-center">
            Chưa có tài khoản?
            <RouterLink to="/provider/register" class="text-blue-600 hover:underline">Đăng ký ngay</RouterLink>
        </p>

    </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { loginProvider } from '@/services/provider/authService';

const email = ref('');
const password = ref('');
const error = ref('');
const router = useRouter();

const handleLogin = async () => {
    try {
        const res = await loginProvider(email.value, password.value);
        localStorage.setItem('token', res.data.token);
        localStorage.setItem('role', res.data.role); // nếu cần
        console.log('✅ Đăng nhập thành công');
        router.push('/provider'); // ✅ sửa lại đúng route
    } catch (err) {
        error.value = err.response?.data?.message || 'Đăng nhập thất bại';
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
    background: #38bdf8;
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 4px;
}
</style>
  
