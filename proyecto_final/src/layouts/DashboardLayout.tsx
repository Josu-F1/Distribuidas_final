import React, { useEffect, useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../services/AuthContext';
import { signOut } from 'firebase/auth';
import { auth } from '../services/firebase';
import { getUsers } from '../services/api';
import toast from 'react-hot-toast';
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
  const { user, loading } = useAuth();

  const [checkingRole, setCheckingRole] = useState(true);

  useEffect(() => {
    const verifyRole = async () => {
      if (loading) return;

      if (!user) {
        navigate('/login');
        setCheckingRole(false);
        return;
      }

      try {
        const allUsers = await getUsers();
        const dbUser = allUsers.find(u => 
          u.firebase_uid === user.uid || 
          u.email.toLowerCase() === user.email?.toLowerCase()
        );

        if (dbUser && dbUser.rol === 'ADMIN') {
          setCheckingRole(false);
        } else {
          toast.error('Acceso denegado. Esta plataforma es exclusiva para administradores.');
          await signOut(auth);
          navigate('/login');
        }
      } catch (err) {
        console.error('Error al verificar rol de administrador:', err);
        toast.error('Sesión no autorizada o error de red.');
        await signOut(auth);
        navigate('/login');
      }
    };

    verifyRole();
  }, [user, loading, navigate]);

  if (loading || checkingRole) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-gray-500 font-medium italic animate-pulse">Verificando credenciales...</div>
      </div>
    );
  }

  if (!user) return null;

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
