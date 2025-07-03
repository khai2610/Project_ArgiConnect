import api from './api';

export const getAllInvoices = () => api.get('/admin/invoices');
