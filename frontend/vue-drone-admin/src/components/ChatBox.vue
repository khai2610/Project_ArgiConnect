<template>
    <div class="flex flex-col h-full">
        <!-- Header tuỳ ý, đang ẩn -->

        <!-- Message list -->
        <div ref="scrollEl" class="flex-1 overflow-y-auto p-3 space-y-2">
            <div v-if="loading" class="text-gray-500">Đang tải tin nhắn…</div>

            <template v-else>
                <div v-for="m in messages" :key="m._id" class="max-w-[85%] px-3 py-2 rounded shadow text-sm"
                    :class="bubbleClass(m)">
                    <div class="whitespace-pre-wrap">{{ m.content }}</div>
                    <div class="text-[10px] text-gray-500 mt-1 text-right">
                        {{ new Date(m.createdAt).toLocaleString() }}
                    </div>
                </div>
                <div v-if="!messages.length" class="text-gray-500 italic">
                    Chưa có tin nhắn.
                </div>
            </template>
        </div>

        <!-- Composer -->
        <div class="p-2 border-t bg-white">
            <form @submit.prevent="send">
                <div class="flex gap-2">
                    <input v-model="text" class="flex-1 border rounded px-3 py-2 outline-none"
                        placeholder="Nhập tin nhắn…" />
                    <button class="px-3 py-2 rounded bg-cyan-600 text-white hover:bg-cyan-700"
                        :disabled="!text.trim() || sending">
                        {{ sending ? 'Đang gửi…' : 'Gửi' }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</template>

<script setup>
import { ref, watch, onMounted, onBeforeUnmount } from 'vue'
import axios from 'axios'

const props = defineProps({
    conversation: { type: Object, required: true }
})

const token = localStorage.getItem('token')
const myId = localStorage.getItem('userId')
const myRole = localStorage.getItem('role') || 'provider'
const headers = { Authorization: `Bearer ${token}` }

const messages = ref([])
const loading = ref(false)
const sending = ref(false)
const text = ref('')

// --- polling ---
let timer = null
const POLL_MS = 2000
const lastMsgId = ref(null)

// scroll ref
const scrollEl = ref(null)
const scrollToBottom = () => {
    requestAnimationFrame(() => {
        const el = scrollEl.value
        if (el) el.scrollTop = el.scrollHeight
    })
}

const haveIds = () =>
    !!(props.conversation?.farmerId && props.conversation?.providerId)

const load = async ({ initial = false } = {}) => {
    if (!haveIds()) return
    if (initial) loading.value = true
    try {
        const { data } = await axios.get(
            `http://localhost:5000/api/chat/between/${props.conversation.farmerId}/${props.conversation.providerId}`,
            { headers }
        )
        const arr = Array.isArray(data) ? data : []
        // detect new
        const newLast = arr.length ? String(arr[arr.length - 1]._id || '') : null
        const changed = newLast && newLast !== lastMsgId.value

        messages.value = arr
        if (initial || changed) {
            lastMsgId.value = newLast
            scrollToBottom()
        }
    } catch (e) {
        console.error('Load messages error:', e)
    } finally {
        if (initial) loading.value = false
    }
}

const startPolling = () => {
    stopPolling()
    // load ngay 1 phát rồi setInterval
    load({ initial: true })
    timer = setInterval(load, POLL_MS)
}
const stopPolling = () => {
    if (timer) {
        clearInterval(timer)
        timer = null
    }
}

const send = async () => {
    const content = text.value.trim()
    if (!content || !haveIds() || sending.value) return
    sending.value = true
    try {
        await axios.post(
            `http://localhost:5000/api/chat/between/${props.conversation.farmerId}/${props.conversation.providerId}`,
            { content },
            { headers }
        )
        text.value = ''
        // gọi load ngay để thấy tin mới
        await load()
    } catch (e) {
        console.error('Send message error:', e)
    } finally {
        sending.value = false
    }
}

// Bóng chat trái/phải
const bubbleClass = (m) => {
    const mine =
        String(m.sender_id) === String(myId) ||
        (m.sender_role && m.sender_role === myRole)
    return mine ? 'bg-cyan-600 text-white ml-auto' : 'bg-gray-100 text-gray-800 mr-auto'
}

// restart polling khi đổi hội thoại
watch(
    () => [props.conversation?.farmerId, props.conversation?.providerId],
    () => {
        lastMsgId.value = null
        startPolling()
    },
    { immediate: true }
)

onMounted(startPolling)
onBeforeUnmount(stopPolling)
</script>
