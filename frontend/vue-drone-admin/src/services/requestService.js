import api from './api';

export const getAllRequests = () => api.get('/admin/requests');
export const getRequestById = (id) => api.get(`/admin/requests/${id}`);
export const updateRequestStatus = (id, status) => api.patch(`/admin/requests/${id}`, { status });
