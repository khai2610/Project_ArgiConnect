// 📁 src/views/FarmerManagement.vue
<template>
    <div>
        <h1 class="text-2xl font-bold mb-6">🌾 Quản lý nông dân</h1>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div v-for="f in farmers" :key="f._id" class="bg-white p-4 rounded shadow">
                <h2 class="text-lg font-semibold">{{ f.name }}</h2>
                <p class="text-sm text-gray-500">📧 {{ f.email }}</p>
                <p class="text-sm text-gray-500">📞 {{ f.phone }}</p>
                <p class="text-sm text-gray-500">📍 {{ f.location?.province }}</p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { getAllFarmers } from '@/services/farmerService';

const farmers = ref([]);

onMounted(async () => {
    const res = await getAllFarmers();
    farmers.value = res.data;
});
</script>

<style scoped></style>
