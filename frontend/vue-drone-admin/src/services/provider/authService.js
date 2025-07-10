// services/authService.js
import axios from 'axios';

const API = 'http://localhost:5000/api/auth';

export const loginProvider = (email, password) => {
  return axios.post(`${API}/login`, {
    email,
    password,
    role: 'provider'
  });
};

export const registerProvider = (data) => {
  return axios.post(`${API}/register`, {
    ...data,
    role: 'provider'
  });
};
