<template>
    <div>
        <!-- Title -->
        <h2 class="text-2xl font-bold mb-4">🧾 Danh sách Hóa đơn</h2>

        <div class="flex gap-4 items-stretch">
            <!-- LEFT (5 phần): List + filter -->
            <section class="flex-[5] bg-white rounded shadow p-4 flex flex-col h-[calc(100vh-140px)]">
                <!-- Filters -->
                <div class="flex flex-wrap items-center gap-2 mb-4">
                    <input v-model="q" type="text" class="input flex-1 min-w-[220px]"
                        placeholder="Tìm theo nông dân / dịch vụ…" />
                    <select v-model="filterStatus" class="input w-[180px]">
                        <option value="">Tất cả trạng thái</option>
                        <option value="PAID">Đã thanh toán</option>
                        <option value="UNPAID">Chưa thanh toán</option>
                    </select>
                    <select v-model="sortOrder" class="input w-[160px]">
                        <option value="newest">Mới nhất</option>
                        <option value="oldest">Cũ nhất</option>
                    </select>
                    <button class="btn" @click="reload">↻ Tải lại</button>
                </div>

                <!-- Loading / Empty -->
                <div v-if="loading" class="text-gray-500">Đang tải hóa đơn...</div>
                <div v-else-if="filteredSorted.length === 0" class="text-gray-500 italic">
                    Không có hóa đơn phù hợp.
                </div>

                <!-- List -->
                <div v-else class="flex-1 overflow-auto space-y-3 pr-1">
                    <article v-for="inv in filteredSorted" :key="inv._id"
                        class="rounded border border-gray-100 hover:border-gray-200 p-4 cursor-pointer"
                        @click="select(inv)">
                        <header class="flex justify-between items-start gap-3">
                            <div class="min-w-0">
                                <p class="font-semibold text-lg truncate">
                                    👨‍🌾 {{ inv.farmer_id?.name || '---' }}
                                </p>
                                <p class="text-sm text-gray-600">
                                    Dịch vụ: {{ prettyService(inv.service_request_id?.service_type) || '---' }}
                                </p>
                                <p class="text-sm text-gray-600">
                                    Ngày yêu cầu: {{ toDate(inv.service_request_id?.preferred_date) }}
                                </p>
                                <p class="text-sm">
                                    Trạng thái:
                                    <span :class="badgeClass(inv.status)">{{ inv.status }}</span>
                                </p>
                            </div>
                            <div class="shrink-0 text-right">
                                <p class="text-lg font-bold text-emerald-600">
                                    {{ toMoney(inv.total_amount) }} {{ inv.currency || 'VND' }}
                                </p>
                                <p class="text-xs text-gray-500">Tạo lúc: {{ toDate(inv.createdAt) }}</p>
                            </div>
                        </header>
                    </article>
                </div>
            </section>

            <!-- RIGHT (3 phần): Detail -->
            <aside class="flex-[3]">
                <div class="bg-white rounded shadow p-4 h-[calc(100vh-140px)] flex flex-col">
                    <div class="flex items-center justify-between mb-3">
                        <h3 class="font-semibold text-lg">📑 Chi tiết hóa đơn</h3>
                        <button v-if="selected" class="px-3 py-1.5 rounded bg-gray-100 hover:bg-gray-200 text-sm"
                            @click="selected = null">
                            ✖ Bỏ chọn
                        </button>
                    </div>

                    <!-- Placeholder -->
                    <div v-if="!selected" class="flex-1 flex items-center justify-center text-gray-500 italic">
                        Chọn một hóa đơn ở danh sách bên trái để xem chi tiết.
                    </div>

                    <!-- Detail -->
                    <div v-else class="flex-1 overflow-auto space-y-4">
                        <!-- General -->
                        <div class="grid grid-cols-2 gap-3">
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Nông dân</p>
                                <p class="font-semibold">{{ selected.farmer_id?.name || '---' }}</p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Dịch vụ</p>
                                <p class="font-semibold">
                                    {{ prettyService(selected.service_request_id?.service_type) || '---' }}
                                </p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Ngày yêu cầu</p>
                                <p class="font-semibold">{{ toDate(selected.service_request_id?.preferred_date) }}</p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Trạng thái</p>
                                <p class="font-semibold">
                                    <span :class="badgeClass(selected.status)">{{ selected.status }}</span>
                                </p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Tổng tiền</p>
                                <p class="font-semibold">
                                    {{ toMoney(selected.total_amount) }} {{ selected.currency || 'VND' }}
                                </p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Tạo lúc</p>
                                <p class="font-semibold">{{ toDate(selected.createdAt) }}</p>
                            </div>
                        </div>

                        <!-- Note -->
                        <div class="bg-slate-50 rounded p-3">
                            <h4 class="font-semibold mb-1">📝 Ghi chú</h4>
                            <p class="text-sm whitespace-pre-wrap">
                                {{ selected.note || '—' }}
                            </p>
                        </div>

                        <!-- Request result (nếu có) -->
                        <div v-if="selected.service_request_id?.result?.description" class="bg-slate-50 rounded p-3">
                            <h4 class="font-semibold mb-1">📌 Kết quả dịch vụ</h4>
                            <p class="text-sm whitespace-pre-wrap">
                                {{ selected.service_request_id.result.description }}
                            </p>
                        </div>
                    </div>

                    <!-- Action bar -->
                    <div v-if="selected" class="pt-3 border-t mt-3 flex flex-wrap items-center gap-2">
                        <!-- Gửi nhắc thanh toán -->
                        <button v-if="selected.status === 'UNPAID'"
                            class="px-3 py-1.5 rounded bg-amber-600 text-white hover:bg-amber-700"
                            :disabled="sendingMsg" @click="remindPayment(selected)">
                            🔔 Gửi nhắc thanh toán
                        </button>

                        <!-- Đánh dấu đã thanh toán (nếu bạn có endpoint này) -->
                        <button v-if="selected.status === 'UNPAID'"
                            class="px-3 py-1.5 rounded bg-emerald-600 text-white hover:bg-emerald-700"
                            :disabled="markingPaid" @click="markPaid(selected)">
                            ✅ Xác nhận đã thanh toán
                        </button>

                        <span v-if="lastNotice" class="text-sm text-slate-600 ml-auto">
                            {{ lastNotice }}
                        </span>
                    </div>
                </div>
            </aside>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, isRef, toRaw } from 'vue'
import axios from 'axios'

const BASE_URL = 'http://localhost:5000'
const token = localStorage.getItem('token')
const myId = localStorage.getItem('userId') // provider hiện tại
const headers = { Authorization: `Bearer ${token}` }

const invoices = ref([])
const loading = ref(true)

const q = ref('')
const filterStatus = ref('')
const sortOrder = ref('newest')

const selected = ref(null)

// trạng thái gửi tin / đánh dấu đã trả
const sendingMsg = ref(false)
const markingPaid = ref(false)
const lastNotice = ref('')

// ===== LOAD =====
const loadInvoices = async () => {
    try {
        const res = await axios.get(`${BASE_URL}/api/provider/invoices`, { headers })
        invoices.value = res.data || []
    } catch (err) {
        console.error(err)
        alert('Lỗi khi tải hóa đơn')
    } finally {
        loading.value = false
    }
}

const reload = async () => {
    loading.value = true
    await loadInvoices()
}

// ===== Helpers =====
const prettyService = (s) => s?.replaceAll('_', ' ') || '---'
const toDate = (iso) => (iso ? new Date(iso).toLocaleString('vi-VN') : '---')
const toMoney = (n) => (typeof n === 'number' ? n.toLocaleString('vi-VN') : '0')

const badgeClass = (st) => ({
    'inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-slate-100 text-slate-700': true,
    'bg-emerald-100 text-emerald-700': st === 'PAID',
    'bg-amber-100 text-amber-700': st === 'UNPAID',
})

const filteredSorted = computed(() => {
    const key = q.value.trim().toLowerCase()

    let base = invoices.value.filter((inv) => {
        const byStatus = !filterStatus.value || inv.status === filterStatus.value
        const byKey =
            !key ||
            (inv.farmer_id?.name && inv.farmer_id.name.toLowerCase().includes(key)) ||
            (inv.service_request_id?.service_type &&
                inv.service_request_id.service_type.toLowerCase().includes(key))
        return byStatus && byKey
    })

    base.sort((a, b) => {
        const dA = new Date(a.createdAt)
        const dB = new Date(b.createdAt)
        return sortOrder.value === 'newest' ? dB - dA : dA - dB
    })

    return base
})

const select = (inv) => {
    selected.value = inv
    lastNotice.value = ''
}

// ===== Chat helper =====
const normalizeId = (id) => {
    const raw = isRef(id) ? id.value : toRaw(id)
    if (raw && typeof raw === 'object') {
        return String(raw._id || raw.$oid || raw.oid || raw.id || raw)
    }
    return raw != null ? String(raw) : ''
}

// helper chung
const sendPaymentMessage = async (farmerId, payload, action = 'INVOICE_CARD') => {
    await axios.post(
        `${BASE_URL}/api/chat/between/${farmerId}/${myId}`,
        { content: payload, action },     // <-- content là OBJECT
        { headers }
    )
}

// nhấn nút "Gửi nhắc thanh toán"
const remindPayment = async (inv) => {
    if (!inv) return
    sendingMsg.value = true
    try {
        const farmerId = normalizeId(inv.farmer_id?._id ?? inv.farmer_id)
        const action = {
            type: 'INVOICE_CARD',
            payload: {
                invoice_id: String(inv._id),
                service: inv.service_request_id?.service_type,
                scheduled_at: inv.service_request_id?.preferred_date,
                amount: inv.total_amount,
                currency: inv.currency || 'VND',
                cta: { label: 'Thanh toán ngay', deeplink: `app://invoice/${inv._id}` }
            }
        }
        // content có thể là type ngắn gọn để app fallback khi không hỗ trợ card
        const content = 'INVOICE_REMINDER'
        await axios.post(
            `${BASE_URL}/api/chat/between/${farmerId}/${myId}`,
            { content, action, request_id: inv.service_request_id?._id ?? inv.service_request_id },
            { headers }
        )
        lastNotice.value = '✅ Đã gửi nhắc thanh toán.'
    } catch (e) {
        lastNotice.value = '⚠ Gửi nhắc thất bại.'
    } finally {
        sendingMsg.value = false
    }
}

const markPaid = async (inv) => {
    if (!inv?._id) return
    markingPaid.value = true
    try {
        // Nếu BE của bạn khác endpoint, sửa tại đây
        await axios.patch(`${BASE_URL}/api/provider/invoices/${inv._id}`, { status: 'PAID' }, { headers })
        // cập nhật local
        const idx = invoices.value.findIndex(i => i._id === inv._id)
        if (idx !== -1) invoices.value[idx].status = 'PAID'
        if (selected.value?._id === inv._id) selected.value.status = 'PAID'

        // Gửi chat xác nhận
        const farmerId = normalizeId(inv.farmer_id?._id ?? inv.farmer_id)
        const moneyText = toMoney(inv.total_amount)
        const svc = prettyService(inv.service_request_id?.service_type)
        const msg = `Hóa đơn dịch vụ "${svc}" đã được xác nhận thanh toán: ${moneyText} ${inv.currency || 'VND'}. Cảm ơn bạn!`
        const ok = await sendPaymentMessage(farmerId, msg, 'INVOICE_PAID')
        lastNotice.value = ok ? '✅ Đã đánh dấu đã thanh toán ' : '✅ Đã đánh dấu'
    } catch (err) {
        console.error(err)
        alert(err?.response?.data?.message || 'Cập nhật thất bại')
    } finally {
        markingPaid.value = false
    }
}

onMounted(loadInvoices)
</script>

<style scoped>
.input {
    display: block;
    width: 100%;
    border: 1px solid #e5e7eb;
    padding: 0.5rem 0.75rem;
    border-radius: 6px;
    outline: none;
}

.input:focus {
    border-color: #94a3b8;
}

.btn {
    background: #22c55e;
    color: white;
    padding: 0.45rem 1rem;
    border-radius: 6px;
}
</style>
