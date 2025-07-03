import api from './api';

export const getAllFarmers = () => api.get('/admin/farmers');
