import React from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { 
  Users as UsersIcon, 
  ShoppingBag, 
  ShoppingCart, 
  LogOut, 
  Bell,
  User,
  LayoutDashboard
} from 'lucide-react';

const DashboardLayout: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-[#F9FAFB] flex flex-col font-sans">
      {/* Header */}
      <header className="h-16 bg-white border-b border-gray-100 flex items-center justify-between px-6 sticky top-0 z-10">
        <div className="flex items-center gap-8">
          <div 
            className="flex items-center gap-2 cursor-pointer hover:opacity-80 transition-opacity"
            onClick={() => navigate('/dashboard')}
          >
            <div className="bg-black text-white p-1 rounded">
              <span className="font-bold text-xs">P</span>
            </div>
            <span className="font-bold text-base">ProductTech</span>
          </div>
          <nav className="flex items-center gap-1">
            <NavLink 
              to="/dashboard" 
              end
              className={({ isActive }) => `px-4 py-2 text-sm font-medium transition-colors ${isActive ? 'text-black' : 'text-gray-400 hover:text-black'}`}
            >
              Inicio
            </NavLink>
            <NavLink 
              to="/dashboard/users" 
              className={({ isActive }) => `px-4 py-2 text-sm font-medium transition-colors ${isActive ? 'text-black' : 'text-gray-400 hover:text-black'}`}
            >
              Usuarios
            </NavLink>
            <NavLink 
              to="/dashboard/products" 
              className={({ isActive }) => `px-4 py-2 text-sm font-medium transition-colors ${isActive ? 'text-black' : 'text-gray-400 hover:text-black'}`}
            >
              Productos
            </NavLink>
            <NavLink 
              to="/dashboard/purchases" 
              className={({ isActive }) => `px-4 py-2 text-sm font-medium transition-colors ${isActive ? 'text-black' : 'text-gray-400 hover:text-black'}`}
            >
              Compras
            </NavLink>
            <NavLink 
              to="/dashboard/account" 
              className={({ isActive }) => `px-4 py-2 text-sm font-medium transition-colors ${isActive ? 'text-black' : 'text-gray-400 hover:text-black'}`}
            >
              Mi Cuenta
            </NavLink>
          </nav>
        </div>

        <div className="flex items-center gap-4">
          <div className="flex items-center gap-3 ml-2 pl-4 border-l border-gray-100">
            <button onClick={() => navigate('/login')} className="text-gray-400 hover:text-red-500">
              <LogOut size={18} />
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 p-8 max-w-7xl mx-auto w-full">
        <Outlet />
      </main>
    </div>
  );
};

export default DashboardLayout;
