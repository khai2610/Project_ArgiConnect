<template>
    <div>
        <Bar :data="chartData" :options="options" />
    </div>
</template>

<script setup>
import { Bar } from 'vue-chartjs';
import {
    Chart as ChartJS,
    Title,
    Tooltip,
    Legend,
    BarElement,
    CategoryScale,
    LinearScale,
} from 'chart.js';

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale);

defineProps({
    chartData: Object
});

const options = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            labels: {
                color: '#fff' // màu chữ trong chú thích
            },
            position: 'top'
        },
        tooltip: {
            titleColor: '#fff',
            bodyColor: '#fff',
            backgroundColor: 'rgba(0,0,0,0.7)'
        },
        title: {
            display: false
        }
    },
    scales: {
        x: {
            ticks: {
                color: '#fff'
            },
            grid: {
                color: 'rgba(255,255,255,0.1)'
            }
        },
        y: {
            beginAtZero: true,
            ticks: {
                color: '#fff'
            },
            grid: {
                color: 'rgba(255,255,255,0.1)'
            }
        }
    }
};
</script>

<style scoped>
div {
    height: 300px;
}
</style>
  
