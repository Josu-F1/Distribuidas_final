import React from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Users, 
  Package, 
  ShoppingCart, 
  UserCircle, 
  ArrowRight,
  ShieldCheck,
  TrendingUp,
  CreditCard
} from 'lucide-react';

const homeCards = [
  {
    title: 'Gestionar Usuarios',
    description: 'Administra roles, estados y accesos del personal.',
    icon: <Users className="text-blue-500" size={24} />,
    path: '/dashboard/users',
    color: 'bg-blue-50',
    borderColor: 'border-blue-100',
    stats: 'Control Total'
  },
  {
    title: 'Catálogo de Productos',
    description: 'Controla el inventario, precios y visualización.',
    icon: <Package className="text-emerald-500" size={24} />,
    path: '/dashboard/products',
    color: 'bg-emerald-50',
    borderColor: 'border-emerald-100',
    stats: 'Actualizado'
  },
  {
    title: 'Reportes de Compras',
    description: 'Visualiza el historial de transacciones y estados.',
    icon: <ShoppingCart className="text-amber-500" size={24} />,
    path: '/dashboard/purchases',
    color: 'bg-amber-50',
    borderColor: 'border-amber-100',
    stats: 'Monitoreo'
  },
  {
    title: 'Información de Cuenta',
    description: 'Verifica tu sesión y credenciales de acceso JWT.',
    icon: <UserCircle className="text-purple-500" size={24} />,
    path: '/dashboard/account',
    color: 'bg-purple-50',
    borderColor: 'border-purple-100',
    stats: 'Mi Perfil'
  }
];

const Home: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="max-w-2xl">
        <h1 className="text-4xl font-extrabold text-gray-900 tracking-tight">
          Bienvenido a <span className="text-black">ProductTech</span>
        </h1>
        <p className="text-lg text-gray-500 mt-3 leading-relaxed">
          Has accedido al panel de administración centralizado. Desde aquí puedes gestionar todos los recursos estratégicos de la plataforma con herramientas de alta precisión.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="bg-gray-50 p-3 rounded-xl border border-gray-100">
             <ShieldCheck className="text-gray-900" size={20} />
          </div>
          <div>
            <p className="text-[10px] font-bold text-gray-400 uppercase">Seguridad</p>
            <p className="text-sm font-bold text-gray-900">Protección Activa</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="bg-gray-50 p-3 rounded-xl border border-gray-100">
             <TrendingUp className="text-gray-900" size={20} />
          </div>
          <div>
            <p className="text-[10px] font-bold text-gray-400 uppercase">Rendimiento</p>
            <p className="text-sm font-bold text-gray-900">Alta Disponibilidad</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
          <div className="bg-gray-50 p-3 rounded-xl border border-gray-100">
             <CreditCard className="text-gray-900" size={20} />
          </div>
          <div>
            <p className="text-[10px] font-bold text-gray-400 uppercase">Plataforma</p>
            <p className="text-sm font-bold text-gray-900">API Conectada</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {homeCards.map((card, idx) => (
          <div 
            key={idx}
            onClick={() => navigate(card.path)}
            className="group relative bg-white border border-gray-100 p-8 rounded-3xl hover:shadow-xl hover:shadow-black/5 transition-all cursor-pointer overflow-hidden"
          >
            <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:scale-110 transition-transform">
              {React.cloneElement(card.icon as React.ReactElement<any>, { size: 120 })}
            </div>
            
            <div className={`p-4 rounded-2xl ${card.color} ${card.borderColor} border w-fit mb-6 shadow-sm`}>
              {card.icon}
            </div>
            
            <div className="flex justify-between items-end">
              <div className="space-y-2">
                <span className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">{card.stats}</span>
                <h3 className="text-2xl font-bold text-gray-900 pr-12">{card.title}</h3>
                <p className="text-gray-500 text-sm max-w-64">{card.description}</p>
              </div>
              
              <div className="bg-black text-white p-3 rounded-full opacity-0 group-hover:opacity-100 translate-x-4 group-hover:translate-x-0 transition-all shadow-lg">
                <ArrowRight size={20} />
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-12 p-8 bg-black rounded-3xl text-white overflow-hidden relative">
        <div className="relative z-10">
          <h2 className="text-2xl font-bold mb-2">Manual de Operaciones</h2>
          <p className="text-gray-400 text-sm max-w-lg">
            Recuerda que todos los cambios realizados en este panel impactan directamente en la base de datos de producción y los servidores de ProductTech.
          </p>
        </div>
        <div className="absolute top-1/2 -right-10 -translate-y-1/2 opacity-10">
           <ShieldCheck size={200} />
        </div>
      </div>
    </div>
  );
};

export default Home;