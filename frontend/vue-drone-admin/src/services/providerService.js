// 📁 src/services/providerService.js
import api from './api';

export const getAllProviders = () => api.get('/admin/providers');
export const getPendingProviders = () => api.get('/admin/providers/pending');
export const approveProvider = (id) => api.patch(`/admin/providers/${id}/approve`);
export const rejectProvider = (id) => api.patch(`/admin/providers/${id}/reject`);
