import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../services/AuthContext';
import { 
  Users, 
  Package, 
  ShoppingCart, 
  UserCircle, 
  ArrowRight,
  ShieldCheck,
  TrendingUp,
  Activity
} from 'lucide-react';

const homeCards = [
  {
    title: 'Gestionar Usuarios',
    description: 'Controla roles, activa/desactiva cuentas y supervisa permisos.',
    icon: <Users className="text-indigo-650" size={24} />,
    path: '/dashboard/users',
    color: 'bg-indigo-50/50',
    borderColor: 'border-indigo-100/70',
    accentColor: 'text-indigo-600',
    stats: 'Usuarios Activos'
  },
  {
    title: 'Catálogo de Productos',
    description: 'Administra inventarios, modifica precios y controla el catálogo.',
    icon: <Package className="text-emerald-650" size={24} />,
    path: '/dashboard/products',
    color: 'bg-emerald-50/50',
    borderColor: 'border-emerald-100/70',
    accentColor: 'text-emerald-600',
    stats: 'Catálogo General'
  },
  {
    title: 'Reportes de Compras',
    description: 'Monitorea transacciones, envíos logísticos y estados de facturas.',
    icon: <ShoppingCart className="text-amber-650" size={24} />,
    path: '/dashboard/purchases',
    color: 'bg-amber-50/50',
    borderColor: 'border-amber-100/70',
    accentColor: 'text-amber-600',
    stats: 'Historial y Rutas'
  },
  {
    title: 'Información de Cuenta',
    description: 'Supervisa tu sesión administrativa actual y tokens JWT.',
    icon: <UserCircle className="text-slate-650" size={24} />,
    path: '/dashboard/account',
    color: 'bg-slate-50/50',
    borderColor: 'border-slate-200/50',
    accentColor: 'text-slate-600',
    stats: 'Perfil Admin'
  }
];

const Home: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return '¡Buenos días';
    if (hour < 18) return '¡Buenas tardes';
    return '¡Buenas noches';
  };

  const displayName = user?.displayName || user?.email?.split('@')[0] || 'Administrador';

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="max-w-2xl">
          <h1 className="text-4xl font-black text-slate-900 tracking-tight leading-none">
            {getGreeting()}, <span className="bg-gradient-to-r from-black to-slate-600 bg-clip-text text-transparent">{displayName}!</span>
          </h1>
          <p className="text-base text-slate-500 mt-3 font-medium leading-relaxed">
            Bienvenido al panel centralizado de <span className="font-bold text-slate-900">ProductTech360</span>. Controla el ecosistema de ventas en tiempo real con herramientas de precisión.
          </p>
        </div>

        <div className="bg-white px-5 py-3.5 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-3">
          <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></div>
          <span className="text-xs font-bold text-slate-600 uppercase tracking-widest flex items-center gap-1.5">
            Sistemas Online <span className="text-slate-350">|</span> <span className="font-semibold text-slate-400">Render API</span>
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="bg-gradient-to-br from-white to-slate-50/40 p-6 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4 hover:shadow-md transition-shadow">
          <div className="bg-indigo-50/50 text-indigo-600 p-3.5 rounded-xl border border-indigo-100/50">
             <ShieldCheck size={20} />
          </div>
          <div>
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Seguridad JWT</p>
            <p className="text-sm font-extrabold text-slate-900">Protección Activa</p>
          </div>
        </div>

        <div className="bg-gradient-to-br from-white to-slate-50/40 p-6 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4 hover:shadow-md transition-shadow">
          <div className="bg-emerald-50/50 text-emerald-600 p-3.5 rounded-xl border border-emerald-100/50">
             <TrendingUp size={20} />
          </div>
          <div>
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Rendimiento</p>
            <p className="text-sm font-extrabold text-slate-900">Alta Disponibilidad</p>
          </div>
        </div>

        <div className="bg-gradient-to-br from-white to-slate-50/40 p-6 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4 hover:shadow-md transition-shadow sm:col-span-2 lg:col-span-1">
          <div className="bg-amber-50/50 text-amber-600 p-3.5 rounded-xl border border-amber-100/50">
             <Activity size={20} />
          </div>
          <div>
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Actividad</p>
            <p className="text-sm font-extrabold text-slate-900">Monitoreo en Tiempo Real</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {homeCards.map((card, idx) => (
          <div 
            key={idx}
            onClick={() => navigate(card.path)}
            className="group relative bg-white border border-slate-100 p-8 rounded-3xl hover:shadow-xl hover:shadow-slate-100/70 transition-all cursor-pointer overflow-hidden hover:-translate-y-1 duration-300"
          >
            <div className={`absolute top-0 right-0 p-8 opacity-5 group-hover:scale-105 group-hover:opacity-10 transition-all duration-300 ${card.accentColor}`}>
              {React.cloneElement(card.icon as React.ReactElement<any>, { size: 130 })}
            </div>
            
            <div className={`p-3.5 rounded-2xl ${card.color} border ${card.borderColor} w-fit mb-6 shadow-sm`}>
              {card.icon}
            </div>
            
            <div className="flex justify-between items-end">
              <div className="space-y-2">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">{card.stats}</span>
                <h3 className="text-2xl font-black text-slate-900 tracking-tight pr-12 group-hover:text-black transition-colors">{card.title}</h3>
                <p className="text-slate-500 text-sm max-w-sm font-medium leading-relaxed">{card.description}</p>
              </div>
              
              <div className="bg-black text-white p-2.5 rounded-xl opacity-0 group-hover:opacity-100 translate-x-4 group-hover:translate-x-0 transition-all shadow-md shadow-black/20">
                <ArrowRight size={18} />
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-12 p-8 bg-slate-950 rounded-3xl text-white overflow-hidden relative shadow-lg shadow-slate-950/10 border border-slate-900">
        <div className="relative z-10 max-w-xl">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest bg-slate-900 border border-slate-800 px-3 py-1 rounded-full w-fit">Información de Seguridad</span>
          <h2 className="text-2xl font-black tracking-tight mt-4 mb-2">Manual de Operaciones Críticas</h2>
          <p className="text-slate-400 text-sm font-medium leading-relaxed">
            Cualquier acción realizada sobre usuarios, catálogos de productos o registros de compras impacta directamente en las bases de datos de producción conectadas a la aplicación móvil. Por favor, proceda con precaución.
          </p>
        </div>
        <div className="absolute top-1/2 -right-10 -translate-y-1/2 opacity-5">
           <ShieldCheck size={240} />
        </div>
      </div>
    </div>
  );
};

export default Home;
