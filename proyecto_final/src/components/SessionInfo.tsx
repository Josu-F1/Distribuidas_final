import React from 'react';
import { useAuth } from '../services/AuthContext';
import { signOut } from 'firebase/auth';
import { auth } from '../services/firebase';
import { LogOut, UserCheck } from 'lucide-react';

const SessionInfo: React.FC = () => {
  const { user } = useAuth();

  const handleLogout = () => {
    signOut(auth);
  };

  if (!user) return null;

  return (
    <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 max-w-4xl w-full">
      <div className="flex justify-between items-center mb-8 border-b border-gray-50 pb-6">
        <div>
          <h2 className="text-xl font-bold text-gray-900">Perfil de Usuario</h2>
          <p className="text-sm text-gray-500 mt-1">Información técnica de tu sesión actual.</p>
        </div>
        <div className="flex items-center gap-2 bg-black px-3.5 py-1.5 rounded-full border border-black/10 shadow-sm">
          <div className="w-2 h-2 bg-white rounded-full animate-pulse"></div>
          <span className="text-[10px] font-bold text-white uppercase tracking-wider">Sesión Activa</span>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div>
          <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Nombre de Usuario</label>
          <div className="p-3 bg-gray-50 border border-gray-100 rounded-xl text-sm font-semibold text-gray-900">
            {user.displayName || user.email?.split('@')[0]}
          </div>
        </div>
        <div>
          <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Correo Electrónico</label>
          <div className="p-3 bg-gray-50 border border-gray-100 rounded-xl text-sm font-medium text-gray-600">
            {user.email}
          </div>
        </div>
        <div>
          <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Estado de Cuenta</label>
          <div className="p-3 bg-gray-50 border border-gray-100 rounded-xl text-sm font-bold text-gray-900 flex items-center gap-2">
            <UserCheck size={16} className="text-black" />
            <span>Verificada y Activa</span>
          </div>
        </div>
      </div>

      <div className="pt-6 border-t border-gray-50 flex items-center justify-between">
        <p className="text-xs text-gray-400 italic">ProductTech v1.0 • Seguridad por Firebase Auth</p>
        <button
          onClick={handleLogout}
          className="flex items-center gap-2 bg-black text-white hover:bg-black/90 px-6 py-2.5 rounded-xl transition-all font-bold text-sm border border-black/10 shadow-sm"
        >
          <LogOut size={18} />
          Cerrar Sesión
        </button>
      </div>
    </div>
  );
};

export default SessionInfo;
