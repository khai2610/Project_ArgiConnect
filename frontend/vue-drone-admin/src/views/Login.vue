<template>
    <div class="min-h-screen flex items-center justify-center bg-gray-100 px-4">
        <div class="bg-white p-8 rounded shadow w-full max-w-sm">
            <h1 class="text-2xl font-bold mb-6 text-center">🔐 Đăng nhập Admin</h1>
            <form @submit.prevent="login" class="space-y-4">
                <input v-model="email" type="email" placeholder="Email"
                    class="w-full px-4 py-2 border rounded focus:outline-none focus:ring" required />

                <input v-model="password" type="password" placeholder="Mật khẩu"
                    class="w-full px-4 py-2 border rounded focus:outline-none focus:ring" required />

                <button type="submit"
                    class="w-full bg-blue-600 text-white font-semibold py-2 rounded hover:bg-blue-700 transition">
                    Đăng nhập
                </button>
            </form>

            <p v-if="error" class="text-red-600 text-sm mt-4 text-center">{{ error }}</p>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';

const router = useRouter();
const email = ref('');
const password = ref('');
const error = ref('');

onMounted(() => {
    const token = localStorage.getItem('token');
    if (token) router.push('/admin');
});

async function login() {
    try {
        const res = await axios.post('http://localhost:5000/api/auth/login', {
            email: email.value,
            password: password.value,
            role: 'admin'
        });

        localStorage.setItem('token', res.data.token);
        router.push('/admin');
    } catch (err) {
        error.value = err.response?.data?.message || 'Đăng nhập thất bại';
    }
}
</script>

<style scoped></style>
  
