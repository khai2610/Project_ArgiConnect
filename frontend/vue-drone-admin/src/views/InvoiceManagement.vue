// 📁 src/views/InvoiceManagement.vue
<template>
    <div>
        <h1 class="text-2xl font-bold mb-6">💰 Quản lý hóa đơn</h1>
        <div class="space-y-4">
            <div v-for="invoice in invoices" :key="invoice._id" class="bg-white p-4 rounded shadow">
                <div class="flex justify-between">
                    <div>
                        <p class="font-semibold">{{ invoice.total_amount.toLocaleString() }} {{ invoice.currency }}</p>
                        <p class="text-sm text-gray-500">Dịch vụ: {{ invoice.service_request_id?.service_type }} - {{
                            invoice.service_request_id?.preferred_date }}</p>
                    </div>
                    <span class="text-sm px-3 py-1 rounded-full font-medium" :class="statusClass(invoice.status)">{{
                        invoice.status }}</span>
                </div>
                <p class="text-sm text-gray-500 mt-2">Nông dân: {{ invoice.farmer_id?.name }}</p>
                <p class="text-sm text-gray-500">Nhà cung cấp: {{ invoice.provider_id?.company_name }}</p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { getAllInvoices } from '@/services/invoiceService';

const invoices = ref([]);

onMounted(async () => {
    const res = await getAllInvoices();
    invoices.value = res.data;
});

function statusClass(status) {
    return {
        PAID: 'bg-green-100 text-green-800',
        UNPAID: 'bg-red-100 text-red-800'
    }[status] || 'bg-gray-100 text-gray-600';
}
</script>

<style scoped></style>
