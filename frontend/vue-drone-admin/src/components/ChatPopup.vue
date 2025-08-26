<template>
    <div
        class="fixed top-4 right-6 w-[360px] h-[500px] bg-white shadow-xl rounded-xl border z-[9999] flex flex-col overflow-hidden">
        <div class="flex items-center justify-between px-4 py-2 border-b bg-purple-50">
            <h3 class="font-semibold text-purple-700 text-lg">
                <template v-if="!selected">💬 Tin nhắn</template>
                <template v-else>💬 {{ selected.partner_name || 'Người dùng' }}</template>
            </h3>
            <div class="flex items-center gap-2">
                <!-- <button v-if="selected" @click="selected = null"
                    class="text-purple-600 hover:text-purple-800 text-sm px-2 py-1 rounded bg-white border">
                    ← Danh sách
                </button>
                <button @click="loadConversations"
                    class="text-purple-600 hover:text-purple-800 text-sm px-2 py-1 rounded bg-white border">
                    Làm mới
                </button> -->
                <button @click="close"
                    class="text-purple-600 hover:text-red-500 text-xl font-bold leading-none">×</button>
            </div>
        </div>

        <div class="flex-1 overflow-y-auto">
            <!-- LIST -->
            <div v-if="!selected" class="divide-y">
                <div v-if="loading" class="p-4 text-gray-500">Đang tải cuộc trò chuyện…</div>

                <template v-else>
                    <div v-if="!conversations.length" class="p-4 text-gray-500 italic">
                        Chưa có cuộc trò chuyện.
                    </div>

                    <div v-for="item in conversations" :key="item.partner_id" @click="select(item)"
                        class="flex items-center gap-3 px-4 py-3 cursor-pointer hover:bg-purple-50 border-b">
                        <div
                            class="w-10 h-10 rounded-full bg-gray-300 text-white flex items-center justify-center text-sm font-bold">
                            {{ getInitial(item.partner_name || item.partner_id) }}
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="font-semibold text-gray-800 truncate">{{ item.partner_name || 'Người dùng' }}</p>
                            <p class="text-sm text-gray-500 truncate">{{ item.last_message || '—' }}</p>
                        </div>
                        <span class="text-[11px] text-gray-400 ml-2 shrink-0">{{ shortDate(item.updated_at) }}</span>
                    </div>
                </template>
            </div>

            <!-- DETAIL -->
            <ChatBox v-else :conversation="selected" @back="selected = null" />
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, watch, watchEffect } from 'vue'
import ChatBox from './ChatBox.vue'
import axios from 'axios'

const props = defineProps({
    farmerId: String,
    role: { type: String, default: () => localStorage.getItem('role') || 'provider' }
})
const emit = defineEmits(['close'])

const token = localStorage.getItem('token')
const headers = { Authorization: `Bearer ${token}` }
const myId = localStorage.getItem('userId')

const conversations = ref([])
const selected = ref(null)
const loading = ref(false)

const loadConversations = async () => {
    loading.value = true
    try {
        // 🔗 ĐÚNG VỚI ROUTE: GET /api/chat
        const { data } = await axios.get('http://localhost:5000/api/chat', { headers })
        conversations.value = data || []
        // đồng bộ khi đang mở sẵn
        if (selected.value) {
            const again = conversations.value.find(c => c.partner_id === selected.value.partner_id)
            if (again) selected.value = { ...again }
        }
    } catch (e) {
        console.error('Load conversations error:', e)
    } finally {
        loading.value = false
    }
}

const select = (conv) => {
    if (!conv?.partner_id) return
    // controller đã trả farmerId/providerId; nếu thiếu thì fallback theo role hiện tại
    selected.value = {
        ...conv,
        farmerId: conv.farmerId ?? (props.role === 'provider' ? conv.partner_id : myId),
        providerId: conv.providerId ?? (props.role === 'provider' ? myId : conv.partner_id)
    }
}

// Tự mở theo farmerId truyền từ ngoài (nếu có)
const tryOpenByFarmerProp = () => {
    if (!props.farmerId || selected.value || !conversations.value.length) return
    const match = conversations.value.find(c => String(c.partner_id) === String(props.farmerId))
    if (match) select(match)
    else {
        selected.value = {
            partner_id: String(props.farmerId),
            partner_name: 'Người dùng',
            farmerId: props.role === 'provider' ? String(props.farmerId) : myId,
            providerId: props.role === 'provider' ? myId : String(props.farmerId),
            messages: []
        }
    }
}
watchEffect(tryOpenByFarmerProp)
watch(() => props.farmerId, tryOpenByFarmerProp)

const close = () => { selected.value = null; emit('close') }
const getInitial = (s) => s?.toString()?.slice(0, 2).toUpperCase() || '??'
const shortDate = (d) => (d ? new Date(d).toLocaleDateString() : '')

onMounted(loadConversations)
</script>
