<template>
    <div
        class="fixed top-4 right-6 w-[360px] h-[500px] bg-white shadow-xl rounded-xl border z-50 flex flex-col overflow-hidden">
        <!-- Header -->
        <div class="flex items-center justify-between px-4 py-2 border-b bg-purple-50">
            <h3 class="font-semibold text-purple-700 text-lg">💬 Tin nhắn</h3>
            <button @click="close" class="text-purple-600 hover:text-red-500 text-xl font-bold">×</button>
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
                        {{ getInitial(item.partner_name || item.partner_id) }}
                    </div>

                    <!-- Nội dung -->
                    <div class="flex-1">
                        <p class="font-semibold text-gray-800 truncate">
                            {{ item.partner_name || 'Người dùng' }}
                        </p>
                        <p class="text-sm text-gray-500 truncate">{{ item.last_message }}</p>
                    </div>
                </div>
            </div>

            <!-- 👉 Nội dung đoạn chat -->
            <ChatBox v-else :conversation="selected" @back="selected = null" />
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, watchEffect } from 'vue';
import ChatBox from './ChatBox.vue';
import api from '@/services/api';

const props = defineProps({
    farmerId: String
});

const emit = defineEmits(['close']);

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
    if (!conv?.partner_id) return;

    selected.value = {
        ...conv,
        farmerId: conv.farmerId ?? conv.partner_id,
        providerId: conv.providerId ?? myId
    };
};

// ✅ Nếu có farmerId truyền từ ngoài → mở luôn ChatBox
watchEffect(() => {
    if (props.farmerId && conversations.value.length > 0 && !selected.value) {
        const match = conversations.value.find(c => c.partner_id === props.farmerId);
        if (match) {
            select(match);
        } else {
            // nếu chưa có hội thoại trước đó
            selected.value = {
                partner_id: props.farmerId,
                partner_name: 'Người dùng',
                farmerId: props.farmerId,
                providerId: myId,
                messages: []
            };
        }
    }
});

// ✅ Đóng popup
const close = () => {
    selected.value = null;
    emit('close');
};

// ✅ Avatar mặc định
const getInitial = (nameOrId) => {
    return nameOrId?.toString()?.slice(0, 2).toUpperCase() || '??';
};

onMounted(loadConversations);
</script>
