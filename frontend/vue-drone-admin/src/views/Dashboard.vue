<template>
    <div class="text-white drop-shadow-md">
        <h1 class="text-2xl font-bold mb-6 drop-shadow-lg">📊 Drone Admin Dashboard</h1>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div class="p-4 bg-black/30 backdrop-blur rounded">
                <h2 class="text-sm drop-shadow">Tổng nhà cung cấp</h2>
                <p class="text-2xl font-bold drop-shadow">{{ stats.totalProviders }}</p>
            </div>
            <div class="p-4 bg-black/30 backdrop-blur rounded">
                <h2 class="text-sm drop-shadow">Yêu cầu chờ xử lý</h2>
                <p class="text-2xl font-bold drop-shadow">{{ stats.pendingRequests }}</p>
            </div>
            <div class="p-4 bg-black/30 backdrop-blur rounded">
                <h2 class="text-sm drop-shadow">Doanh thu tháng</h2>
                <p class="text-2xl font-bold text-green-400 drop-shadow">{{ formatCurrency(stats.monthlyRevenue) }}</p>
            </div>
            <div class="p-4 bg-black/30 backdrop-blur rounded">
                <h2 class="text-sm drop-shadow">Tổng nông dân</h2>
                <p class="text-2xl font-bold drop-shadow">{{ stats.totalFarmers }}</p>
            </div>
        </div>

        <div class="p-6 mb-8 bg-black/30 backdrop-blur rounded">
            <h3 class="text-lg font-semibold mb-4 drop-shadow">🗓 Gần đây nhất</h3>
            <ul class="space-y-2">
                <li v-for="item in recentRequests" :key="item._id"
                    class="border border-white/30 p-3 rounded bg-white/10 backdrop-blur-sm text-white drop-shadow">
                    <div class="text-sm">{{ item.preferred_date }}</div>
                    <div class="font-medium">{{ item.service_type }} tại {{ item.field_location?.province }}</div>
                </li>
            </ul>
        </div>

        <div class="p-6 mb-8 bg-black/30 backdrop-blur rounded">
            <h3 class="text-lg font-semibold mb-4 drop-shadow">📈 Biểu đồ yêu cầu theo tháng</h3>
            <BarChart v-if="chartData" :chart-data="chartData" />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="p-6 bg-black/30 backdrop-blur rounded">
                <h3 class="text-lg font-semibold mb-4 drop-shadow">👨‍🌾 Biểu đồ nông dân đăng ký theo tháng</h3>
                <BarChart v-if="farmerChartData" :chart-data="farmerChartData" />
            </div>
            <div class="p-6 bg-black/30 backdrop-blur rounded">
                <h3 class="text-lg font-semibold mb-4 drop-shadow">🏢 Biểu đồ nhà cung cấp đăng ký theo tháng</h3>
                <BarChart v-if="providerChartData" :chart-data="providerChartData" />
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { getAllRequests } from '@/services/requestService';
import { getAllFarmers } from '@/services/farmerService';
import { getAllInvoices } from '@/services/invoiceService';
import { getAllProviders } from '@/services/providerService';
import BarChart from '@/components/BarChart.vue';

const stats = ref({
    totalProviders: 0,
    pendingRequests: 0,
    monthlyRevenue: 0,
    totalFarmers: 0
});

const recentRequests = ref([]);
const chartData = ref(null);
const farmerChartData = ref(null);
const providerChartData = ref(null);

function formatCurrency(value) {
    return value.toLocaleString('vi-VN', { style: 'currency', currency: 'VND' });
}

function buildMonthlyChart(data, label, color) {
    const monthlyCounts = Array(12).fill(0);
    data.forEach(item => {
        const m = new Date(item.createdAt).getMonth();
        monthlyCounts[m]++;
    });
    return {
        labels: ['Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6', 'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12'],
        datasets: [{ label, backgroundColor: color, data: monthlyCounts }]
    };
}

onMounted(async () => {
    try {
        const [requestsRes, farmersRes, invoicesRes, providersRes] = await Promise.all([
            getAllRequests(),
            getAllFarmers(),
            getAllInvoices(),
            getAllProviders()
        ]);

        const requests = requestsRes.data;
        stats.value.pendingRequests = requests.filter(r => r.status === 'PENDING').length;
        recentRequests.value = requests.slice(0, 3);
        chartData.value = buildMonthlyChart(requests, 'Số yêu cầu', '#3b82f6');

        const farmers = farmersRes.data;
        stats.value.totalFarmers = farmers.length;
        farmerChartData.value = buildMonthlyChart(farmers, 'Nông dân đăng ký', '#10b981');

        const providers = providersRes.data;
        stats.value.totalProviders = providers.length;
        providerChartData.value = buildMonthlyChart(providers, 'Nhà cung cấp đăng ký', '#f59e0b');

        stats.value.monthlyRevenue = invoicesRes.data.reduce((sum, i) => {
            const month = new Date(i.createdAt).getMonth();
            const now = new Date().getMonth();
            return month === now && i.status === 'PAID' ? sum + i.total_amount : sum;
        }, 0);

    } catch (err) {
        console.error('Lỗi khi tải dữ liệu dashboard:', err);
    }
});
</script>

<style scoped></style>
