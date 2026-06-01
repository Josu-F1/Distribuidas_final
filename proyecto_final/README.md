# ProductTech - TechStore Management

Este proyecto es un Panel de Administración moderno construido con **React**, **TypeScript** y **Tailwind CSS**, diseñado para gestionar usuarios, productos y compras utilizando la API de ProductTech.

## Características

- 🔐 **Pantalla de Login**: Interfaz elegante y funcional.
- 📊 **Dashboard General**: Resumen de estadísticas clave.
- 👥 **Gestión de Usuarios**: Listado completo obtenido de la API.
- 📦 **Gestión de Productos**: Control de inventario y catálogo.
- 🛒 **Historial de Compras**: Registro detallado de transacciones.
- 🎨 **Diseño Moderno**: Inspirado en interfaces limpias y minimalistas con Lucide Icons.

## API Utilizada

Este proyecto consume datos de: [https://techstore-flask-api.onrender.com/](https://techstore-flask-api.onrender.com/)

## Tecnologías

- **Vite**: Build tool rápido para React.
- **Tailwind CSS v4**: Estilizado moderno y eficiente.
- **React Router 7**: Navegación fluida entre secciones.
- **Axios**: Cliente HTTP para el consumo de la API.
- **Lucide React**: Iconografía minimalista.

## Comenzar

1. Instalar dependencias:
   ```bash
   npm install
   ```

2. Iniciar servidor de desarrollo:
   ```bash
   npm run dev
   ```

3. Abrir en el navegador: `http://localhost:5173/`

## Estructura del Proyecto

- `src/pages`: Pantallas principales (Login, Users, Products, Purchases).
- `src/layouts`: Componentes de estructura como el DashboardLayout.
- `src/services`: Lógica de consumo de API con Axios.
- `src/types`: Definiciones de interfaces TypeScript.
