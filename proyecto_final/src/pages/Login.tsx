import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Layout, Mail, Lock, Eye, EyeOff, Globe } from 'lucide-react';
import { signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { auth } from '../services/firebase';
import { getUsers } from '../services/api';
import toast from 'react-hot-toast';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();

    const trimmedEmail = email.trim();
    if (!trimmedEmail) {
      toast.error('El correo electrónico es requerido.');
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(trimmedEmail)) {
      toast.error('Por favor, ingresa un correo electrónico válido.');
      return;
    }

    if (!password) {
      toast.error('La contraseña es requerida.');
      return;
    }

    if (password.length < 6) {
      toast.error('La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    try {
      setLoading(true);
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const firebaseUser = userCredential.user;

      // Obtener usuarios para verificar el rol administrador
      const allUsers = await getUsers();
      const dbUser = allUsers.find(u => 
        u.firebase_uid === firebaseUser.uid || 
        u.email.toLowerCase() === firebaseUser.email?.toLowerCase()
      );

      if (!dbUser || dbUser.rol !== 'ADMIN') {
        await signOut(auth);
        toast.error('Acceso denegado. Solo administradores pueden ingresar.');
        return;
      }

      toast.success('¡Iniciado sesión correctamente!');
      navigate('/dashboard');
    } catch (err: any) {
      toast.error('Error al iniciar sesión. Verifica tus credenciales.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex bg-gray-50 font-sans">
      {/* Left side */}
      <div className="hidden md:flex md:w-1/2 flex-col justify-between p-12 bg-gray-100 border-r border-gray-200">
        <div>
          <div className="flex items-center gap-2 mb-8">
            <div className="bg-black text-white p-1 rounded">
              <span className="font-bold text-lg">P</span>
            </div>
            <span className="font-bold text-xl">ProductTech</span>
          </div>
          
          <div className="mt-20 max-w-md">
            <h2 className="text-sm font-bold uppercase tracking-widest text-gray-400 mb-4 flex items-center gap-2">
              <span className="w-8 h-[1px] bg-gray-300"></span>
              Panel de Administración
            </h2>
            <h1 className="text-5xl font-extrabold mt-6 leading-tight text-gray-900">
              Gestiona tu negocio con <span className="text-gray-400">claridad.</span>
            </h1>
            <p className="text-gray-500 mt-6 text-lg">
              Usuarios, productos y compras — todo en un solo lugar, diseñado para ir al grano.
            </p>
          </div>
        </div>

        <div className="space-y-4">
          <div className="flex items-center gap-4 text-gray-700">
            <div className="p-2 border border-gray-200 rounded-lg bg-white">
               <Layout size={20} />
            </div>
            <span className="font-medium">Gestionar usuarios</span>
          </div>
          <div className="flex items-center gap-4 text-gray-700">
            <div className="p-2 border border-gray-200 rounded-lg bg-white">
               <Layout size={20} />
            </div>
            <span className="font-medium">Gestionar productos</span>
          </div>
          <div className="flex items-center gap-4 text-gray-700">
            <div className="p-2 border border-gray-200 rounded-lg bg-white">
               <Layout size={20} />
            </div>
            <span className="font-medium">Consultar compras</span>
          </div>
        </div>

        <div className="text-gray-400 text-sm">
          © 2025 ProductTech. Todos los derechos reservados.
        </div>
      </div>

      {/* Right side - Login Form */}
      <div className="flex-1 flex flex-col justify-center items-center p-8">
        <div className="w-full max-w-md bg-white p-10 rounded-2xl shadow-sm border border-gray-100">
          <div className="flex items-center gap-2 mb-10">
            <div className="bg-black text-white p-1 rounded">
              <span className="font-bold text-sm">P</span>
            </div>
            <span className="font-bold text-base">ProductTech</span>
          </div>

          <h2 className="text-2xl font-bold mb-2">Iniciar sesión</h2>
          <p className="text-gray-400 mb-8">Accede a tu panel de administración</p>

          <form onSubmit={handleLogin} noValidate className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Correo electrónico</label>
              <div className="relative">
                <input
                  type="email"
                  placeholder="admin@empresa.com"
                  className="w-full px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 disabled:opacity-50 disabled:bg-gray-50"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                  required
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between items-center mb-2">
                <label className="block text-sm font-medium text-gray-700">Contraseña</label>
              </div>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  placeholder="••••••••••••"
                  className="w-full px-4 py-3 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 disabled:opacity-50 disabled:bg-gray-50"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-black disabled:opacity-30"
                  disabled={loading}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-[#111] text-white py-3 rounded-lg font-bold hover:bg-black transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Iniciando sesión...
                </>
              ) : (
                'Iniciar sesión'
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Login;
