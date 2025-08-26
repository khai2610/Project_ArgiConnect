<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">📋 Danh sách yêu cầu dịch vụ</h2>

        <div class="flex gap-4 items-stretch">
            <!-- LEFT: Request list -->
            <section class="flex-[5] bg-white rounded shadow p-4 flex flex-col h-[calc(100vh-140px)]">
                <!-- Filter / search -->
                <div class="flex flex-wrap items-center gap-2 mb-4">
                    <input v-model="q" type="text" class="input flex-1 min-w-[220px]"
                        placeholder="Tìm theo loại dịch vụ / nông dân…" />
                    <select v-model="status" class="input w-[180px]">
                        <option value="">Tất cả trạng thái</option>
                        <option value="PENDING">Đang chờ</option>
                        <option value="ACCEPTED">Đã nhận</option>
                        <option value="COMPLETED">Hoàn thành</option>
                        <option value="REJECTED">Từ chối</option>
                    </select>
                    <button class="btn" @click="reload">↻ Tải lại</button>
                </div>

                <!-- Empty -->
                <div v-if="filtered.length === 0" class="text-gray-500 italic">
                    Không có yêu cầu nào.
                </div>

                <!-- List -->
                <div v-else class="flex-1 overflow-auto space-y-3 pr-1">
                    <article v-for="req in filtered" :key="req._id"
                        class="rounded border border-gray-100 hover:border-gray-200 p-4">
                        <header class="flex justify-between items-start gap-3">
                            <div class="min-w-0">
                                <h3 class="font-semibold text-lg truncate">
                                    {{ prettyService(req.service_type) }}
                                </h3>
                                <p class="text-sm text-gray-600">
                                    Ngày yêu cầu: {{ formatDateTime(req.createdAt) }}
                                </p>
                                <p class="text-sm">
                                    Trạng thái:
                                    <span :class="badgeClass(req.status)">{{ req.status }}</span>
                                </p>
                                <p class="text-sm text-gray-700">
                                    Nông dân: {{ farmerName(req) }}
                                </p>
                            </div>

                            <div class="shrink-0 flex gap-2">
                                <button class="px-3 py-1.5 rounded bg-cyan-600 text-white hover:bg-cyan-700"
                                    @click="showDetail(req)">
                                    Xem chi tiết
                                </button>
                                <button class="px-3 py-1.5 rounded bg-gray-100 hover:bg-gray-200"
                                    @click="openChatWith(req)">
                                    💬 Nhắn tin
                                </button>
                            </div>
                        </header>
                    </article>
                </div>
            </section>

            <!-- RIGHT: Chi tiết + Hóa đơn + Đánh giá -->
            <aside class="flex-[3]">
                <div class="bg-white rounded shadow p-4 h-[calc(100vh-140px)] flex flex-col">
                    <div class="flex items-center justify-between mb-3">
                        <h3 class="font-semibold text-lg">🧾 Chi tiết yêu cầu</h3>
                        <button v-if="selected" class="px-3 py-1.5 rounded bg-gray-100 hover:bg-gray-200 text-sm"
                            @click="clearSelection">
                            ✖ Bỏ chọn
                        </button>
                    </div>

                    <!-- Placeholder -->
                    <div v-if="!selected" class="flex-1 flex items-center justify-center text-gray-500 italic">
                        Chọn một yêu cầu ở danh sách bên trái để xem chi tiết.
                    </div>

                    <!-- Nội dung chi tiết -->
                    <div v-else class="flex-1 overflow-auto space-y-4">
                        <!-- Info grid -->
                        <div class="grid grid-cols-2 gap-3">
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Loại dịch vụ</p>
                                <p class="font-semibold">{{ prettyService(selected.service_type) }}</p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Nông dân</p>
                                <p class="font-semibold">{{ farmerName(selected) }}</p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Diện tích (ha)</p>
                                <p class="font-semibold">{{ selected.area_ha ?? '—' }}</p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Cây trồng</p>
                                <p class="font-semibold">{{ selected.crop_type || '—' }}</p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Ngày mong muốn</p>
                                <p class="font-semibold">{{ toDate(selected.preferred_date) }}</p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Trạng thái</p>
                                <p class="font-semibold">
                                    <span :class="badgeClass(selected.status)">{{ selected.status }}</span>
                                </p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Thanh toán</p>
                                <p class="font-semibold">
                                    {{ selected.payment_status || (hasInvoice ? 'UNPAID' : '—') }}
                                </p>
                            </div>
                            <div class="bg-slate-50 rounded p-3">
                                <p class="text-xs text-slate-500">Tạo lúc</p>
                                <p class="font-semibold">{{ formatDateTime(selected.createdAt) }}</p>
                            </div>
                        </div>

                        <!-- Map -->
                        <div class="bg-slate-50 rounded p-3">
                            <div class="flex justify-between items-center mb-2">
                                <h4 class="font-semibold">📍 Vị trí thửa</h4>
                                <span class="text-xs text-slate-500">
                                    {{ selected.field_location?.province || '—' }}
                                </span>
                            </div>

                            <div v-if="hasCoords" class="h-56 rounded overflow-hidden border">
                                <LMap :zoom="13" :center="[
                                    selected.field_location.coordinates.lat,
                                    selected.field_location.coordinates.lng
                                ]" style="height: 100%; width: 100%">
                                    <LTileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                                        attribution="&copy; OpenStreetMap contributors" />
                                    <LMarker :lat-lng="[
                                        selected.field_location.coordinates.lat,
                                        selected.field_location.coordinates.lng
                                    ]" />
                                </LMap>
                            </div>
                            <div v-else class="text-gray-500 italic">Chưa có toạ độ.</div>
                        </div>

                        <!-- Notes -->
                        <div class="bg-slate-50 rounded p-3">
                            <h4 class="font-semibold mb-1">📝 Ghi chú</h4>
                            <p class="text-sm whitespace-pre-wrap">
                                {{ selected.result?.description || selected.comment || '—' }}
                            </p>
                        </div>

                        <!-- ⭐ Đánh giá cho yêu cầu này (nếu có) -->
                        <div v-if="currentReview.hasAny" class="bg-slate-50 rounded p-3">
                            <h4 class="font-semibold mb-2">⭐ Đánh giá của nông dân</h4>
                            <!-- Hàng sao -->
                            <div class="flex items-center gap-2">
                                <div class="text-yellow-500 text-lg leading-none">
                                    <span v-for="i in 5" :key="i">
                                        {{ i <= currentReview.stars ? '★' : '☆' }} </span>
                                </div>
                                <span class="text-sm text-slate-600">({{ currentReview.stars }}/5)</span>
                            </div>
                            <!-- Nội dung ngay dưới sao -->
                            <p class="text-sm whitespace-pre-wrap mt-1">
                                {{ currentReview.comment || '—' }}
                            </p>
                            <p v-if="currentReview.date" class="text-xs text-slate-500 mt-1">
                                Cập nhật: {{ currentReview.date }}
                            </p>
                        </div>

                        <!-- ⭐ Các đánh giá khác về nhà cung cấp -->
                        <div class="bg-slate-50 rounded p-3">
                            <div class="flex items-center justify-between">
                                <h4 class="font-semibold">⭐ Các đánh giá khác về nhà cung cấp</h4>
                                <span v-if="ratings.length" class="text-xs text-slate-500">Tổng: {{ ratings.length
                                    }}</span>
                            </div>

                            <p v-if="!ratings.length" class="text-sm text-slate-500 italic mt-1">
                                Chưa có đánh giá khác.
                            </p>

                            <div v-else class="mt-2 space-y-3">
                                <div v-for="(r, idx) in visibleRatings" :key="idx"
                                    class="border-b border-gray-200 pb-2 last:border-0">
                                    <!-- Hàng sao -->
                                    <div class="flex items-center gap-2">
                                        <div class="text-yellow-500 text-lg leading-none">
                                            <span v-for="i in 5" :key="i">
                                                {{ i <= (r.rating || 0) ? '★' : '☆' }} </span>
                                        </div>
                                        <span class="text-sm text-slate-600">({{ r.rating || 0 }}/5)</span>
                                    </div>
                                    <!-- Nội dung ngay dưới sao -->
                                    <p class="text-sm whitespace-pre-wrap mt-1">
                                        {{ r.comment || 'Không có nhận xét' }}
                                    </p>
                                    <p class="text-xs text-slate-500 mt-1">
                                        Cây trồng: {{ r.crop_type || '—' }} • Ngày yêu cầu: {{ toDate(r.preferred_date)
                                        }}
                                    </p>
                                </div>

                                <div v-if="ratings.length > limit" class="pt-1">
                                    <button class="text-sm text-cyan-700 hover:underline" @click="toggleMore">
                                        {{ showAll ? 'Thu gọn' : `Xem thêm ${ratings.length - limit} đánh giá` }}
                                    </button>
                                </div>
                            </div>
                        </div>

                        <!-- LẬP HÓA ĐƠN (inline, BE tự tính) -->
                        <div v-if="selected && canShowInvoicePanel"
                            class="bg-amber-50 border border-amber-200 rounded-lg p-3 space-y-2">
                            <div class="flex items-center justify-between">
                                <h4 class="font-semibold">🧾 Lập hoá đơn</h4>
                                <button class="text-sm text-slate-600 hover:underline"
                                    @click="toggleInvoicePanel(false)">
                                    Ẩn
                                </button>
                            </div>

                            <div class="text-sm text-slate-600">
                                Tổng tiền sẽ được tính tự động theo giá dịch vụ và diện tích. Bạn chỉ
                                cần nhập ghi chú (nếu có).
                            </div>

                            <textarea v-model="invoiceNote" class="input w-full" rows="3"
                                placeholder="Ghi chú (tùy chọn)…"></textarea>

                            <div class="flex gap-2 justify-end">
                                <button class="px-3 py-1.5 rounded bg-gray-100" @click="toggleInvoicePanel(false)">
                                    Hủy
                                </button>
                                <button class="px-3 py-1.5 rounded bg-amber-600 text-white hover:bg-amber-700"
                                    :disabled="creatingInvoice" @click="createInvoice">
                                    🧾 Tạo hoá đơn
                                </button>
                            </div>

                            <p v-if="lastInvoiceAmount !== null" class="text-sm text-amber-700">
                                ✅ Đã lập hóa đơn. Số tiền: {{ formatVND(lastInvoiceAmount) }}.
                            </p>
                        </div>
                    </div>

                    <!-- Action bar -->
                    <div v-if="selected" class="pt-3 border-t mt-3 flex items-center gap-2">
                        <button class="px-3 py-1.5 rounded bg-cyan-600 text-white hover:bg-cyan-700"
                            @click="openChatWith(selected)">
                            💬 Nhắn tin
                        </button>

                        <button v-if="selected.status === 'PENDING'"
                            class="px-3 py-1.5 rounded bg-emerald-600 text-white hover:bg-emerald-700"
                            @click="acceptSelected">
                            Nhận yêu cầu
                        </button>
                        <button v-if="selected.status === 'PENDING'"
                            class="px-3 py-1.5 rounded bg-rose-600 text-white hover:bg-rose-700"
                            @click="rejectSelected">
                            Từ chối
                        </button>
                        <button v-if="selected.status === 'ACCEPTED'"
                            class="px-3 py-1.5 rounded bg-indigo-600 text-white hover:bg-indigo-700"
                            @click="completeSelected">
                            Đánh dấu hoàn thành
                        </button>

                        <!-- Nút mở panel tạo hóa đơn khi đã hoàn thành và chưa có hóa đơn -->
                        <button v-if="selected.status === 'COMPLETED' && showCreateInvoiceButton"
                            class="ml-auto px-3 py-1.5 rounded bg-amber-600 text-white hover:bg-amber-700"
                            @click="toggleInvoicePanel(true)">
                            🧾 Tạo hoá đơn
                        </button>
                    </div>
                </div>
            </aside>
        </div>

        <!-- Chat popup trượt từ dưới lên -->
        <ChatPopup v-if="showChat" :farmerId="popupFarmerId" @close="showChat = false" />
    </div>
</template>

<script setup>
import { ref, computed, onMounted, isRef, toRaw } from 'vue'
import axios from 'axios'
import ChatPopup from '@/components/ChatPopup.vue'

// Map
import { LMap, LTileLayer, LMarker } from '@vue-leaflet/vue-leaflet'
import 'leaflet/dist/leaflet.css'
import * as L from 'leaflet'

// Fix icon Leaflet (Vite)
delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
    iconRetinaUrl: new URL('leaflet/dist/images/marker-icon-2x.png', import.meta.url).href,
    iconUrl: new URL('leaflet/dist/images/marker-icon.png', import.meta.url).href,
    shadowUrl: new URL('leaflet/dist/images/marker-shadow.png', import.meta.url).href
})

const BASE_URL = 'http://localhost:5000'
const token = localStorage.getItem('token')
const headers = { Authorization: `Bearer ${token}` }

const list = ref([])
const q = ref('')
const status = ref('')

// Request đang chọn
const selected = ref(null)

// ===== invoices state =====
const hasInvoice = ref(false)
const showInvoicePanel = ref(false)
const invoiceNote = ref('')
const creatingInvoice = ref(false)
const lastInvoiceAmount = ref(null)

// ===== ratings state =====
const ratings = ref([])     // danh sách đánh giá khác về provider (từ API public)
const limit = ref(3)        // số đánh giá mặc định hiển thị
const showAll = ref(false)
const visibleRatings = computed(() => showAll.value ? ratings.value : ratings.value.slice(0, limit.value))
const toggleMore = () => { showAll.value = !showAll.value }

// === Fetch Requests ===
const loadRequests = async () => {
    const res = await axios.get(`${BASE_URL}/api/provider/requests`, { headers })
    list.value = res.data || []
}

// Khi chọn 1 request, kiểm tra luôn hóa đơn + lấy đánh giá provider
const checkInvoice = async (reqId) => {
    try {
        const res = await axios.get(`${BASE_URL}/api/provider/invoices`, { headers })
        hasInvoice.value = Array.isArray(res.data) && res.data.some(i => {
            const sid = i.service_request_id?._id || i.service_request_id
            return String(sid) === String(reqId)
        })
    } catch (e) {
        hasInvoice.value = false
    }
}

const loadProviderRatings = async (providerId) => {
    try {
        const res = await axios.get(`${BASE_URL}/api/public/provider/${providerId}/ratings`)
        ratings.value = Array.isArray(res.data) ? res.data : []
    } catch (e) {
        ratings.value = []
    }
}

// === Helpers ===
const filtered = computed(() => {
    const key = q.value.trim().toLowerCase()
    return list.value.filter(r => {
        const byStatus = !status.value || r.status === status.value
        const fn = farmerName(r).toLowerCase()
        const byKey =
            !key ||
            (r.service_type && r.service_type.toLowerCase().includes(key)) ||
            fn.includes(key)
        return byStatus && byKey
    })
})

const toDate = (d) => (d ? new Date(d).toLocaleDateString('vi-VN') : '—')
const formatDateTime = (d) => {
    const dt = new Date(d)
    return `${dt.toLocaleTimeString('vi-VN')} ${dt.toLocaleDateString('vi-VN')}`
}
const formatVND = n => new Intl.NumberFormat('vi-VN').format(Number(n || 0))
const prettyService = (s) => (s ? s.replaceAll('_', ' ') : '---')

const badgeClass = (st) => ({
    'inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-slate-100 text-slate-700': true,
    'bg-yellow-100 text-yellow-700': st === 'PENDING',
    'bg-blue-100 text-blue-700': st === 'ACCEPTED',
    'bg-green-100 text-green-700': st === 'COMPLETED',
    'bg-red-100 text-red-700': st === 'REJECTED'
})

const hasCoords = computed(() =>
    !!(
        selected.value &&
        selected.value.field_location?.coordinates?.lat &&
        selected.value.field_location?.coordinates?.lng
    )
)

// ===== farmer name resolver =====
const farmerName = (row) => {
    const name =
        row?.farmer?.name ||
        row?.farmer_id?.name ||
        row?.farmer_name || ''
    if (name) return name

    const id =
        row?.farmer_id?._id ||
        row?.farmer_id ||
        row?.farmer?.id ||
        row?.farmerId || ''
    if (!id) return '---'
    const s = String(id)
    return 'Farmer ' + s.slice(-4)
}

// ⭐ Review của chính yêu cầu đang xem (nếu có)
const currentReview = computed(() => {
    const s = selected.value || {}
    const rating =
        s?.rating ??
        s?.result?.rating ??
        s?.review?.rating ??
        null

    const comment =
        s?.comment ??
        s?.result?.feedback ??
        s?.review?.comment ??
        s?.feedback ??
        ''

    const ratedAt =
        s?.ratedAt ??
        s?.result?.ratedAt ??
        s?.review?.updatedAt ??
        s?.updatedAt ??
        null

    const starsNum = Math.max(0, Math.min(5, Number(rating ?? 0)))
    const hasAny = Boolean((rating != null && !Number.isNaN(starsNum)) || comment)
    return {
        stars: Number.isFinite(starsNum) ? starsNum : 0,
        comment: comment || '',
        date: ratedAt ? new Date(ratedAt).toLocaleString('vi-VN') : '',
        hasAny
    }
})

// === Actions ===
const reload = async () => { await loadRequests() }

const showDetail = async (req) => {
    selected.value = req
    lastInvoiceAmount.value = null
    invoiceNote.value = ''
    showInvoicePanel.value = false

    await checkInvoice(req._id)

    // Lấy danh sách đánh giá công khai theo provider
    const providerId = req?.provider_id?._id || req?.provider_id
    if (providerId) {
        await loadProviderRatings(providerId)
    } else {
        ratings.value = []
    }
}

const clearSelection = () => {
    selected.value = null
    showInvoicePanel.value = false
    hasInvoice.value = false
    lastInvoiceAmount.value = null
    ratings.value = []
}

// ====== CHAT ======
const showChat = ref(false)
const popupFarmerId = ref(null)

const normalizeId = (id) => {
    const raw = isRef(id) ? id.value : toRaw(id)
    if (raw && typeof raw === 'object') {
        return String(raw._id || raw.$oid || raw.oid || raw.id || raw)
    }
    return raw != null ? String(raw) : ''
}

const openChatWith = (req) => {
    const farmerId = normalizeId(
        req.farmer_id ?? req.farmer?._id ?? req.farmerId ?? req.farmer?.id
    )
    if (!farmerId) return
    popupFarmerId.value = farmerId
    showChat.value = true
}

// ====== Update status theo route BE ======
const acceptSelected = async () => {
    if (!selected.value) return
    try {
        await axios.patch(`${BASE_URL}/api/provider/requests/${selected.value._id}/accept`, {}, { headers })
        selected.value.status = 'ACCEPTED'
        const idx = list.value.findIndex(r => r._id === selected.value._id)
        if (idx !== -1) list.value[idx].status = 'ACCEPTED'
    } catch (e) {
        console.error('accept error:', e)
        alert('Không thể nhận yêu cầu.')
    }
}

const rejectSelected = async () => {
    if (!selected.value) return
    try {
        await axios.patch(`${BASE_URL}/api/provider/requests/${selected.value._id}/reject`, {}, { headers })
        selected.value.status = 'REJECTED'
        const idx = list.value.findIndex(r => r._id === selected.value._id)
        if (idx !== -1) list.value[idx].status = 'REJECTED'
    } catch (e) {
        console.error('reject error:', e)
        alert('Không thể từ chối yêu cầu.')
    }
}

const completeSelected = async () => {
    if (!selected.value) return
    try {
        await axios.patch(`${BASE_URL}/api/provider/requests/${selected.value._id}/complete`, {}, { headers })
        selected.value.status = 'COMPLETED'
        const idx = list.value.findIndex(r => r._id === selected.value._id)
        if (idx !== -1) list.value[idx].status = 'COMPLETED'
    } catch (e) {
        console.error('complete error:', e)
        alert('Không thể đánh dấu hoàn thành.')
    }
}

// ====== INVOICE ======
const showCreateInvoiceButton = computed(() => {
    if (!selected.value) return false
    const noInvoiceYet = !hasInvoice.value && !selected.value.payment_status
    return selected.value.status === 'COMPLETED' && noInvoiceYet
})

const toggleInvoicePanel = (open) => {
    showInvoicePanel.value = open
}

const canShowInvoicePanel = computed(() => {
    return showInvoicePanel.value && selected.value && showCreateInvoiceButton.value
})

const createInvoice = async () => {
    if (!selected.value) return
    creatingInvoice.value = true
    try {
        const res = await axios.post(
            `${BASE_URL}/api/provider/invoices`,
            { request_id: selected.value._id, note: invoiceNote.value || '' },
            { headers }
        )
        const amount = res?.data?.invoice?.total_amount ?? null
        lastInvoiceAmount.value = amount
        hasInvoice.value = true
        selected.value.payment_status = 'UNPAID'
        alert('✅ Lập hoá đơn thành công' + (amount ? `: ${formatVND(amount)} VND` : ''))
        showInvoicePanel.value = false
    } catch (e) {
        console.error('create invoice error:', e)
        alert(e?.response?.data?.message || 'Không thể lập hoá đơn.')
    } finally {
        creatingInvoice.value = false
    }
}

// === init ===
onMounted(async () => {
    await loadRequests()
})
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

.btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}
</style>
