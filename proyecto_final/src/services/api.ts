import axios from 'axios';
import { User, Product, Purchase } from '../types';
import { auth } from './firebase';

const API_URL = 'https://techstore-flask-api.onrender.com';

export const api = axios.create({
  baseURL: API_URL,
});

// Interceptor para añadir el token de Firebase a las peticiones
api.interceptors.request.use(async (config) => {
  const user = auth.currentUser;
  if (user) {
    const token = await user.getIdToken();
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Tipos para las respuestas de la API
interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
}

export const getUsers = () => api.get<ApiResponse<User[]>>('/api/usuarios').then(res => res.data.data);
export const deleteUser = (id: string) => api.delete<ApiResponse<any>>(`/api/usuarios/${id}`).then(res => res.data);
export const updateUser = (id: string, data: Partial<User>) => api.put<ApiResponse<User>>(`/api/usuarios/${id}`, data).then(res => res.data.data);

export const getProducts = () => api.get<ApiResponse<Product[]>>('/api/productos').then(res => res.data.data);
export const createProduct = (data: Partial<Product>) => api.post<ApiResponse<Product>>('/api/productos', data).then(res => res.data.data);
export const deleteProduct = (id: string) => api.delete<ApiResponse<any>>(`/api/productos/${id}`).then(res => res.data);
export const updateProduct = (id: string, data: Partial<Product>) => api.put<ApiResponse<Product>>(`/api/productos/${id}`, data).then(res => res.data.data);

export const getPurchases = () => api.get<ApiResponse<Purchase[]>>('/api/compras').then(res => res.data.data);
