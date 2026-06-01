import React from 'react';
import { useAuth } from '../services/AuthContext';
import { signOut } from 'firebase/auth';
import { auth } from '../services/firebase';
import { LogOut, Copy } from 'lucide-react';
import toast from 'react-hot-toast';

const SessionInfo: React.FC = () => {
  const { user, token } = useAuth();

  const handleLogout = () => {
    signOut(auth);
  };

  const copyToken = () => {
    if (token) {
      navigator.clipboard.writeText(token);
      toast.success('Token copiado al portapapeles');
    }
  };

  if (!user) return null;

  return (
    <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 max-w-2xl w-full">
      <div className="flex justify-between items-center mb-8 border-b border-gray-50 pb-6">
        <div>
          <h2 className="text-xl font-bold text-gray-900">Perfil de Usuario</h2>
          <p className="text-sm text-gray-500 mt-1">Información técnica de tu sesión actual.</p>
        </div>
        <div className="flex items-center gap-2 bg-green-50 px-3 py-1.5 rounded-full border border-green-100">
          <div className="w-2 h-2 bg-green-500 rounded-full"></div>
          <span className="text-[10px] font-bold text-green-600 uppercase tracking-wider">Sesión Activa</span>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div className="space-y-4">
          <div>
            <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">Nombre de Usuario</label>
            <div className="p-3 bg-gray-50 border border-gray-100 rounded-xl text-sm font-semibold text-gray-900">
              {user.displayName || user.email?.split('@')[0]}
            </div>
          </div>
          <div>
            <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">Correo Electrónico</label>
            <div className="p-3 bg-gray-50 border border-gray-100 rounded-xl text-sm font-medium text-gray-600">
              {user.email}
            </div>
          </div>
        </div>
        
        <div className="space-y-4">
          <div>
            <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">Firebase UID</label>
            <div className="p-3 bg-gray-50 border border-gray-100 rounded-xl text-xs font-mono text-gray-500 break-all">
              {user.uid}
            </div>
          </div>
          <div>
             <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">Estado de Cuenta</label>
             <div className="p-3 bg-gray-50 border border-gray-100 rounded-xl text-sm font-bold text-green-600">
               Verificada y Activa
             </div>
          </div>
        </div>
      </div>

      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider ml-1">Token de Acceso (JWT)</span>
          <button 
            onClick={copyToken}
            className="flex items-center gap-1.5 text-black hover:text-gray-600 transition-colors text-xs font-bold"
          >
            <Copy size={14} />
            Copiar Token
          </button>
        </div>
        <div className="bg-gray-900 rounded-xl p-4 border border-gray-800 shadow-inner">
          <p className="text-gray-400 font-mono text-[10px] break-all leading-relaxed max-h-24 overflow-y-auto custom-scrollbar">
            {token}
          </p>
        </div>
      </div>

      <div className="pt-6 border-t border-gray-50 flex items-center justify-between">
        <p className="text-xs text-gray-400 italic">ProductTech v1.0 • Seguridad por Firebase Auth</p>
        <button
          onClick={handleLogout}
          className="flex items-center gap-2 bg-red-50 text-red-600 hover:bg-red-500 hover:text-white px-6 py-2.5 rounded-xl transition-all font-bold text-sm border border-red-100 shadow-sm"
        >
          <LogOut size={18} />
          Cerrar Sesión
        </button>
      </div>
    </div>
  );
};

export default SessionInfo;
