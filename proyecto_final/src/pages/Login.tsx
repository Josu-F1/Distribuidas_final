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
    <div className="min-h-screen flex bg-[#FAFBFD] font-sans">
      {/* Left side */}
      <div className="hidden md:flex md:w-1/2 flex-col justify-between p-16 bg-slate-50 border-r border-slate-100">
        <div>
          <div className="flex items-center gap-2.5 mb-8">
            <div className="bg-black text-white w-8 h-8 rounded-xl flex items-center justify-center shadow-md shadow-black/15">
              <span className="font-extrabold text-sm tracking-tighter">P</span>
            </div>
            <span className="font-black text-lg tracking-tight text-slate-900">ProductTech<span className="text-slate-400 font-semibold">360</span></span>
          </div>
          
          <div className="mt-24 max-w-md">
            <span className="px-3 py-1 bg-slate-200/50 text-[10px] font-bold text-slate-500 uppercase tracking-widest rounded-full border border-slate-200">
              Panel Administrativo
            </span>
            <h1 className="text-5xl font-black mt-6 leading-tight text-slate-900 tracking-tight">
              Gestiona tu negocio con <span className="bg-gradient-to-r from-indigo-600 to-indigo-850 bg-clip-text text-transparent">claridad.</span>
            </h1>
            <p className="text-slate-500 mt-6 text-base font-medium leading-relaxed">
              Usuarios, productos y compras — todo en un solo lugar, diseñado para ir al grano y operar en tiempo real.
            </p>
          </div>
        </div>

        <div className="space-y-4 max-w-sm">
          {[
            { label: 'Gestionar usuarios y accesos', desc: 'Controla perfiles de clientes y del personal.' },
            { label: 'Gestionar inventario de productos', desc: 'Modifica catálogo, stocks y precios.' },
            { label: 'Consultar compras y logística', desc: 'Inspecciona facturación y rutas de despacho.' }
          ].map((item, idx) => (
            <div key={idx} className="flex items-start gap-4 p-3 bg-white/60 hover:bg-white rounded-2xl border border-slate-100/50 hover:border-slate-150 transition-all duration-300">
              <div className="p-2 border border-slate-100 rounded-xl bg-white text-slate-800 shadow-sm">
                 <Layout size={16} />
              </div>
              <div>
                <p className="font-bold text-sm text-slate-900">{item.label}</p>
                <p className="text-xs text-slate-400 font-medium mt-0.5">{item.desc}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="text-slate-400 text-xs font-semibold tracking-wider uppercase">
          © 2026 ProductTech 360. Todos los derechos reservados.
        </div>
      </div>

      {/* Right side - Login Form */}
      <div className="flex-1 flex flex-col justify-center items-center p-8 bg-gradient-to-br from-white to-slate-50/20">
        <div className="w-full max-w-md bg-white p-12 rounded-3xl shadow-xl shadow-slate-100/60 border border-slate-100">
          <div className="flex items-center gap-2 mb-8">
            <div className="bg-black text-white w-7 h-7 rounded-lg flex items-center justify-center shadow-md shadow-black/10">
              <span className="font-bold text-xs">P</span>
            </div>
            <span className="font-black text-base tracking-tight text-slate-900">ProductTech</span>
          </div>

          <h2 className="text-3xl font-black text-slate-900 tracking-tight mb-2">Iniciar sesión</h2>
          <p className="text-slate-400 text-sm font-medium mb-8">Accede al panel de administración central</p>

          <form onSubmit={handleLogin} noValidate className="space-y-6">
            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Correo electrónico</label>
              <div className="relative">
                <input
                  type="email"
                  placeholder="admin@techstore.com"
                  className="w-full px-4 py-3 border border-slate-200/70 rounded-xl focus:outline-none focus:ring-2 focus:ring-black/5 focus:border-slate-900 disabled:opacity-50 disabled:bg-slate-50 font-medium text-slate-800 placeholder-slate-350 text-sm transition-all"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                  required
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between items-center mb-2">
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">Contraseña</label>
              </div>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  placeholder="••••••••••••"
                  className="w-full px-4 py-3 border border-slate-200/70 rounded-xl focus:outline-none focus:ring-2 focus:ring-black/5 focus:border-slate-900 disabled:opacity-50 disabled:bg-slate-50 font-medium text-slate-800 placeholder-slate-350 text-sm transition-all"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-950 transition-colors disabled:opacity-30"
                  disabled={loading}
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-slate-950 text-white py-3.5 rounded-xl font-bold hover:bg-black transition-all hover:shadow-lg hover:shadow-black/10 active:scale-98 disabled:opacity-50 flex items-center justify-center gap-2 text-sm"
            >
              {loading ? (
                <>
                  <div className="w-4.5 h-4.5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
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
