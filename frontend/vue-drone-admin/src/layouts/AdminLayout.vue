<template>
    <div class="bg-cover bg-no-repeat bg-center min-h-screen overflow-hidden"
        style="background-image: url('/admin-bg.jpg')">
        <div class="min-h-screen">
            <div class="flex">
                <!-- Sidebar cố định -->
                <div class="fixed top-0 left-0 h-screen w-64 z-50">
                    <Sidebar />
                </div>

                <!-- Nội dung đẩy sang phải -->
                <main class="ml-64 flex-1 p-6 overflow-y-auto h-screen bg-transparent">
                    <router-view />
                </main>
            </div>
        </div>
    </div>
</template>

<script setup>
import Sidebar from '@/components/Sidebar.vue';
</script>

<style scoped>
main {
    scrollbar-gutter: stable;
    background-color: transparent;
}
</style>
  
