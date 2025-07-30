<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">📊 Tổng quan nhà cung cấp</h2>

        <div v-if="loading" class="text-gray-500">Đang tải dữ liệu...</div>

        <div v-else>
            <!-- Thống kê chung -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                <div class="bg-white shadow-md rounded-xl p-4">
                    <h3 class="text-lg font-semibold text-gray-700">🏢 Công ty</h3>
                    <p class="text-gray-900">{{ provider.company_name || '---' }}</p>
                </div>
                <div class="bg-white shadow-md rounded-xl p-4">
                    <h3 class="text-lg font-semibold text-gray-700">🛠 Số dịch vụ</h3>
                    <p class="text-gray-900">{{ provider.services?.length ?? 0 }}</p>
                </div>
                <div class="bg-white shadow-md rounded-xl p-4">
                    <h3 class="text-lg font-semibold text-gray-700">📋 Tổng yêu cầu</h3>
                    <p class="text-gray-900">{{ requestCount }}</p>
                </div>
            </div>

            <!-- 📍 Bản đồ -->
            <div class="bg-white shadow-md rounded-xl p-4 mb-8">
                <h3 class="text-lg font-semibold text-gray-700 mb-2">📍 Các yêu cầu xung quanh</h3>
                <LMap v-if="requestsNearby.length > 0" :zoom="13"
                    :center="[requestsNearby[0].field_location.coordinates.lat, requestsNearby[0].field_location.coordinates.lng]"
                    style="height: 400px; width: 100%">
                    <LTileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                        attribution="&copy; OpenStreetMap contributors" />

                    <!-- Marker các yêu cầu -->
                    <LMarker v-for="req in requestsNearby" :key="req._id"
                        :lat-lng="[req.field_location.coordinates.lat, req.field_location.coordinates.lng]">
                        <template #popup>
                            <div>
                                <p class="font-semibold">📋 {{ req.service_type }}</p>
                                <p>🌾 {{ req.crop_type }} | {{ req.area_ha }} ha</p>
                                <p>🗓 {{ new Date(req.preferred_date).toLocaleDateString() }}</p>
                            </div>
                        </template>
                    </LMarker>
                </LMap>
                <p v-else class="text-gray-500 italic">Không có yêu cầu nào có toạ độ</p>
            </div>

            <!-- 📊 Thống kê linh hoạt -->
            <div class="flex justify-between items-center mb-4">
                <h3 class="text-xl font-bold">📈 Thống kê theo {{ selectedRangeLabel }}</h3>
                <select v-model="selectedRange" class="border rounded px-3 py-1 text-sm">
                    <option value="week">Tuần này</option>
                    <option value="month">Tháng này</option>
                    <option value="year">Năm nay</option>
                </select>
            </div>

            <!-- Bảng thống kê -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                <div class="bg-white p-4 rounded shadow">
                    <h4 class="text-gray-600">📋 Yêu cầu</h4>
                    <p class="text-xl font-bold">{{ stats.requests }}</p>
                </div>
                <div class="bg-white p-4 rounded shadow">
                    <h4 class="text-gray-600">🧾 Hóa đơn</h4>
                    <p class="text-xl font-bold">{{ stats.invoices }}</p>
                </div>
                <div class="bg-white p-4 rounded shadow">
                    <h4 class="text-gray-600">💰 Đã thanh toán</h4>
                    <p class="text-xl font-bold">{{ stats.paidInvoices }}</p>
                </div>
            </div>

            <!-- Biểu đồ -->
            <div class="bg-white p-4 rounded shadow">
                <Bar :data="chartData" :options="chartOptions" />
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import axios from 'axios';
import { LMap, LTileLayer, LMarker } from '@vue-leaflet/vue-leaflet';
import 'leaflet/dist/leaflet.css';
import * as L from 'leaflet';

import { Bar } from 'vue-chartjs';
import {
    Chart as ChartJS,
    Title, Tooltip, Legend,
    CategoryScale, LinearScale, BarElement
} from 'chart.js';

ChartJS.register(Title, Tooltip, Legend, CategoryScale, LinearScale, BarElement);

// Fix icon Leaflet (Vite)
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: new URL('leaflet/dist/images/marker-icon-2x.png', import.meta.url).href,
    iconUrl: new URL('leaflet/dist/images/marker-icon.png', import.meta.url).href,
    shadowUrl: new URL('leaflet/dist/images/marker-shadow.png', import.meta.url).href
});

const token = localStorage.getItem('token');
const headers = { Authorization: `Bearer ${token}` };

const provider = ref({
    services: [],
    company_name: '',
});
const requestCount = ref(0);
const loading = ref(true);
const requestsNearby = ref([]);

// 📊 Thống kê
const selectedRange = ref('month');
const stats = ref({ requests: 0, invoices: 0, paidInvoices: 0 });
const chartData = ref({ labels: [], datasets: [] });
const chartOptions = {
    responsive: true,
    plugins: {
        legend: { position: 'top' }
    }
};
const selectedRangeLabel = computed(() => {
    switch (selectedRange.value) {
        case 'week': return 'tuần';
        case 'month': return 'tháng';
        case 'year': return 'năm';
        default: return '';
    }
});

const loadProviderData = async () => {
    const profileRes = await axios.get('http://localhost:5000/api/provider/profile', { headers });
    provider.value = profileRes.data;

    const requestRes = await axios.get('http://localhost:5000/api/provider/requests', { headers });
    requestCount.value = requestRes.data.length;

    // lọc các yêu cầu có toạ độ
    requestsNearby.value = requestRes.data.filter(r =>
        r.field_location?.coordinates?.lat &&
        r.field_location?.coordinates?.lng
    );
};

const loadStats = async () => {
    const res = await axios.get(`http://localhost:5000/api/provider/stats?range=${selectedRange.value}`, { headers });
    stats.value = res.data.summary;
    chartData.value = res.data.chart;
};

watch(selectedRange, loadStats);

onMounted(async () => {
    try {
        await loadProviderData();
        await loadStats();
    } catch (err) {
        console.error('Lỗi khi tải dashboard:', err);
    } finally {
        loading.value = false;
    }
});
</script>
