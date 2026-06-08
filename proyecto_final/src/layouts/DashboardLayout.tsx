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
    <div className="min-h-screen bg-[#F8FAFC] flex flex-col font-sans">
      {/* Header */}
      <header className="h-16 bg-white/70 backdrop-blur-xl border-b border-gray-100 flex items-center justify-between px-6 sticky top-0 z-50 shadow-sm shadow-black/[0.01]">
        <div className="flex items-center gap-8">
          <div 
            className="flex items-center gap-2.5 cursor-pointer hover:opacity-95 transition-all group"
            onClick={() => navigate('/dashboard')}
          >
            <div className="bg-black text-white w-7.5 h-7.5 rounded-xl flex items-center justify-center shadow-md shadow-black/10 group-hover:scale-105 transition-transform duration-300">
              <span className="font-extrabold text-sm tracking-tighter">P</span>
            </div>
            <span className="font-black text-lg tracking-tight text-slate-900 group-hover:text-black transition-colors">ProductTech<span className="text-gray-400 font-medium">360</span></span>
          </div>
          <nav className="flex items-center gap-1.5">
            {[
              { to: '/dashboard', label: 'Inicio', end: true },
              { to: '/dashboard/users', label: 'Usuarios' },
              { to: '/dashboard/products', label: 'Productos' },
              { to: '/dashboard/purchases', label: 'Compras' },
              { to: '/dashboard/account', label: 'Mi Cuenta' }
            ].map((link) => (
              <NavLink 
                key={link.to}
                to={link.to} 
                end={link.end}
                className={({ isActive }) => `px-4 py-2 text-sm font-semibold rounded-xl transition-all duration-300 ${
                  isActive 
                    ? 'text-black bg-gray-150/80 shadow-sm shadow-black/[0.02]' 
                    : 'text-slate-400 hover:text-slate-950 hover:bg-gray-50/50'
                }`}
              >
                {link.label}
              </NavLink>
            ))}
          </nav>
        </div>

        <div className="flex items-center gap-4">
          <div className="flex items-center gap-3 ml-2 pl-4 border-l border-gray-100">
            <button 
              onClick={async () => {
                await signOut(auth);
                toast.success('Sesión cerrada correctamente');
                navigate('/login');
              }} 
              className="w-9 h-9 rounded-xl bg-gray-50 text-slate-400 hover:text-red-600 hover:bg-red-50 hover:border-red-100 border border-gray-150/40 flex items-center justify-center transition-all duration-300"
              title="Cerrar Sesión"
            >
              <LogOut size={16} />
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
