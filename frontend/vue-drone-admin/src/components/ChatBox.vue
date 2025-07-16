<template>
    <div class="flex flex-col h-full">
        <!-- Tiêu đề + nút trở lại -->
        <div class="flex items-center gap-2 px-4 py-2 border-b bg-gray-50">
            <button @click="$emit('back')" class="text-gray-600 hover:text-blue-600 text-lg font-bold">←</button>
            <h2 class="text-base font-semibold text-gray-800 truncate">
                {{ props.conversation?.partner_name || 'Tin nhắn' }}
            </h2>
        </div>

        <!-- Danh sách tin nhắn -->
        <div ref="chatArea" class="flex-1 overflow-y-auto px-3 py-4 space-y-3">
            <div v-for="msg in messages" :key="msg._id"
                :class="isMine(msg) ? 'flex justify-end' : 'flex justify-start'">
                <div class="flex items-end gap-2" :class="isMine(msg) ? 'flex-row-reverse' : ''">
                    <!-- Avatar -->
                    <div
                        class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center text-white text-xs font-bold">
                        {{ getInitial(msg.sender_id) }}
                    </div>

                    <!-- Nội dung -->
                    <div>
                        <div :class="[
                            'px-3 py-2 rounded-xl text-sm max-w-[240px] break-words',
                            isMine(msg)
                                ? 'bg-blue-500 text-white text-right'
                                : 'bg-gray-200 text-gray-800 text-left'
                        ]">
                            {{ msg.content }}
                        </div>
                        <div class="text-[11px] text-gray-400 mt-0.5" :class="isMine(msg) ? 'text-right' : ''">
                            {{ formatTime(msg.createdAt) }}
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Nhập tin nhắn -->
        <div class="p-2 border-t bg-gray-50 flex items-center">
            <input v-model="text" @keyup.enter="send" placeholder="Nhập tin nhắn..."
                class="flex-1 border rounded-full px-3 py-2 text-sm" />
            <button @click="send" class="ml-2 bg-blue-500 text-white px-4 py-2 rounded text-sm">Gửi</button>
        </div>
    </div>
</template>

<script setup>
import { ref, watch, nextTick, onUnmounted } from 'vue';
import { jwtDecode } from 'jwt-decode';
import api from '@/services/api';

const props = defineProps(['conversation']);
const text = ref('');
const messages = ref([]);
const chatArea = ref(null);

// ✅ Lấy myId từ token
const token = localStorage.getItem('token');
const decoded = token ? jwtDecode(token) : {};
const myId = decoded.id || null;

// ✅ Cuộn xuống cuối
const scrollToBottom = () => {
    nextTick(() => {
        if (chatArea.value) {
            chatArea.value.scrollTop = chatArea.value.scrollHeight;
        }
    });
};

// ✅ Polling
let pollingInterval;

const fetchMessages = async () => {
    if (!props.conversation?.farmerId || !props.conversation?.providerId) return;

    const res = await api.get(`/chat/between/${props.conversation.farmerId}/${props.conversation.providerId}`);
    messages.value = res.data;
    scrollToBottom();
};

watch(() => props.conversation, (val) => {
    clearInterval(pollingInterval);

    if (val?.farmerId && val?.providerId) {
        fetchMessages(); // Lần đầu
        pollingInterval = setInterval(fetchMessages, 3000); // Lặp lại mỗi 3 giây
    }
}, { immediate: true });

onUnmounted(() => {
    clearInterval(pollingInterval);
});

// ✅ Gửi tin nhắn
const send = async () => {
    if (!text.value.trim()) return;
    const { farmerId, providerId } = props.conversation;
    const res = await api.post(`/chat/between/${farmerId}/${providerId}`, { content: text.value });
    messages.value.push(res.data.data);
    text.value = '';
    scrollToBottom();
};

// ✅ Helpers
const formatTime = (iso) => {
    const d = new Date(iso);
    return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
};

const getInitial = (id) => {
    const str = typeof id === 'object' ? id?._id?.toString() : id?.toString();
    return str?.slice(-2)?.toUpperCase() || '??';
};

const isMine = (msg) => {
    const sender = typeof msg.sender_id === 'object' ? msg.sender_id._id : msg.sender_id;
    return sender?.toString() === myId;
};
</script>
