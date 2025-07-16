<!-- components/ChatSidebar.vue -->
<template>
    <div class="w-1/3 p-4 border-r h-screen overflow-y-auto">
        <h2 class="text-xl font-semibold mb-4">Tin nhắn</h2>
        <ul>
            <li v-for="item in conversations" :key="item.partner_id" @click="$emit('select', item)"
                class="p-2 hover:bg-gray-100 cursor-pointer border-b">
                <p class="font-bold">{{ item.partner_name }}</p>
                <p class="text-sm text-gray-500 truncate">{{ item.last_message }}</p>
            </li>
        </ul>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

const conversations = ref([]);

onMounted(async () => {
    const res = await axios.get('/chat', {
        headers: { Authorization: 'Bearer ' + localStorage.getItem('token') }
    });
    conversations.value = res.data;
});
</script>
