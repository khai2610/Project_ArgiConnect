<!-- components/ChatPopup.vue -->
<template>
    <div
        class="fixed top-4 right-6 w-[360px] h-[500px] bg-white shadow-xl rounded-xl border z-50 flex flex-col overflow-hidden">
        <!-- Header -->
        <!-- Header chỉ hiển thị khi chưa chọn -->
        <div v-if="!selected" class="flex items-center justify-between px-4 py-2 border-b bg-purple-50">
            <h3 class="font-semibold text-purple-700 text-lg">
                💬 Tin nhắn
            </h3>
            <button @click="$emit('close')" class="text-purple-600 hover:text-red-500 text-xl font-bold">×</button>
        </div>

        <!-- Nội dung -->
        <div class="flex-1 overflow-y-auto">
            <!-- 👉 Danh sách hội thoại -->
            <div v-if="!selected" class="divide-y">
                <div v-for="item in conversations" :key="item.partner_id" @click="select(item)"
                    class="flex items-center gap-3 px-4 py-3 cursor-pointer hover:bg-purple-50 border-b">
                    <!-- Avatar -->
                    <div
                        class="w-10 h-10 rounded-full bg-gray-300 text-white flex items-center justify-center text-sm font-bold">
                        {{ getInitial(item.partner_id) }}
                    </div>

                    <!-- Nội dung -->
                    <div class="flex-1">
                        <p class="font-semibold text-gray-800 truncate">
                            {{ item.partner_name }}
                        </p>
                        <p class="text-sm text-gray-500 truncate">
                            {{ item.last_message }}
                        </p>
                    </div>
                </div>

            </div>

            <!-- 👉 Nội dung đoạn chat -->
            <ChatBox v-else :conversation="selected" @back="selected = null" />
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import ChatBox from './ChatBox.vue';
import api from '@/services/api'; // dùng api.js để đảm bảo có baseURL + token

const myId = localStorage.getItem('userId');
const conversations = ref([]);
const selected = ref(null);

const loadConversations = async () => {
    try {
        const res = await api.get('/chat');
        conversations.value = res.data;
    } catch (err) {
        console.error('❌ Lỗi khi gọi /chat:', err);
    }
};

const select = (conv) => {
    if (!conv?.partner_id) {
        console.warn('⚠️ Dữ liệu conversation không hợp lệ:', conv);
        return;
    }

    selected.value = {
        ...conv,
        farmerId: conv.farmerId ?? conv.partner_id,
        providerId: conv.providerId ?? myId
    };
};

const getInitial = (id) => {
    return id?.toString()?.slice(-2)?.toUpperCase() || '??';
};

onMounted(loadConversations);
</script>
