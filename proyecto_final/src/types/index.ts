export interface User {
  id: string; // UUID
  firebase_uid: string;
  nombres: string;
  apellidos: string;
  email: string;
  rol: 'ADMIN' | 'CLIENTE';
  telefono?: string;
  cedula?: string;
  estado: boolean;
  eliminado?: boolean;
  created_at: string;
}

export interface Product {
  id: string; // UUID
  nombre: string;
  descripcion: string;
  precio: number;
  stock: number;
  imagen_url?: string;
  activo: boolean;
  eliminado?: boolean;
  created_at: string;
  updated_at: string;
}

export interface Purchase {
  id: string; // UUID
  usuario_id: string;
  fecha_compra: string;
  subtotal: number;
  iva: number;
  total: number;
  estado: 'PENDIENTE' | 'PAGADA' | 'FACTURADA' | 'CANCELADA';
  direccion_origen?: string;
  direccion_destino?: string;
  eliminado?: boolean;
}
