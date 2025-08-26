<template>
    <div>
        <h2 class="text-2xl font-bold mb-4">📊 Tổng quan nhà cung cấp</h2>

        <div v-if="loading" class="text-gray-500">Đang tải dữ liệu...</div>

        <div v-else>
            <!-- Map (5) + Stats (3) -->
            <div class="flex gap-4 mb-8 items-stretch">
                <!-- 📍 Bản đồ (5 phần) -->
                <div class="flex-[5] bg-white shadow-md rounded-xl p-4 flex flex-col h-[72vh]">
                    <h3 class="text-lg font-semibold text-gray-700 mb-2">📍 Các yêu cầu xung quanh</h3>

                    <div class="flex-1">
                        <LMap v-if="requestsNearby.length > 0" :zoom="13" :center="[
                            requestsNearby[0].field_location.coordinates.lat,
                            requestsNearby[0].field_location.coordinates.lng
                        ]" class="w-full h-full">
                            <LTileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                                attribution="&copy; OpenStreetMap contributors" />
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
                </div>

                <!-- 📊 Cột thống kê (3 phần) -->
                <div class="flex-[3] flex flex-col gap-4 max-h-[72vh] overflow-auto">
                    <!-- Thông tin nhanh -->
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

                    <!-- Bộ lọc thời gian -->
                    <div class="bg-white shadow-md rounded-xl p-4">
                        <div class="flex justify-between items-center">
                            <h3 class="text-md font-bold">📈 Thống kê theo {{ selectedRangeLabel }}</h3>
                            <select v-model="selectedRange" class="border rounded px-3 py-1 text-sm">
                                <option value="week">Tuần này</option>
                                <option value="month">Tháng này</option>
                                <option value="year">Năm nay</option>
                            </select>
                        </div>
                    </div>

                    <!-- Hóa đơn: Tổng / Đã TT / Chưa TT -->
                    <div class="bg-white p-4 rounded shadow">
                        <h4 class="text-gray-600">🧾 Hóa đơn</h4>
                        <div class="mt-2 grid grid-cols-3 gap-4">
                            <div>
                                <p class="text-xs text-gray-500">Tổng</p>
                                <p class="text-xl font-bold">{{ stats.invoices.total }}</p>
                            </div>
                            <div>
                                <p class="text-xs text-gray-500">Đã thanh toán</p>
                                <p class="text-xl font-bold text-green-600">{{ stats.invoices.paid }}</p>
                            </div>
                            <div>
                                <p class="text-xs text-gray-500">Chưa thanh toán</p>
                                <p class="text-xl font-bold text-red-600">{{ stats.invoices.unpaid }}</p>
                            </div>
                        </div>
                    </div>

                    <!-- Doanh thu -->
                    <div class="bg-white p-4 rounded shadow">
                        <h4 class="text-gray-600">💰 Doanh thu</h4>
                        <p class="text-2xl font-extrabold text-green-600 mt-1">
                            {{ formatCurrency(stats.revenue) }}
                        </p>
                    </div>
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

const provider = ref({ services: [], company_name: '' });
const requestCount = ref(0);
const loading = ref(true);
const requestsNearby = ref([]);

// 📊 Thống kê
const selectedRange = ref('month');
const stats = ref({
    requests: 0,
    invoices: { total: 0, paid: 0, unpaid: 0 },
    revenue: 0
});
const chartData = ref({ labels: [], datasets: [] });
const chartOptions = {
    responsive: true,
    plugins: { legend: { position: 'top' } }
};

const selectedRangeLabel = computed(() => {
    switch (selectedRange.value) {
        case 'week': return 'tuần';
        case 'month': return 'tháng';
        case 'year': return 'năm';
        default: return '';
    }
});

const formatCurrency = (v) =>
    (v || 0).toLocaleString('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 });

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
    // API mới: { summary: { requests, invoices: {total,paid,unpaid}, revenue }, chart }
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
