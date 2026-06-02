import React, { useEffect, useState } from 'react';
import { useAuth } from '../services/AuthContext';
import { signOut, updateProfile } from 'firebase/auth';
import { auth } from '../services/firebase';
import { getUsers, updateUser } from '../services/api';
import { User } from '../types';
import { LogOut, UserCheck, Edit2, Save, X, Phone, Mail, Shield, Calendar } from 'lucide-react';
import toast from 'react-hot-toast';

const SessionInfo: React.FC = () => {
  const { user: firebaseUser } = useAuth();
  const [dbUser, setDbUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [isEditing, setIsEditing] = useState(false);

  // Form states
  const [nombres, setNombres] = useState('');
  const [apellidos, setApellidos] = useState('');
  const [telefono, setTelefono] = useState('');

  const fetchProfile = async () => {
    if (!firebaseUser) return;
    try {
      setLoading(true);
      const allUsers = await getUsers();
      const found = allUsers.find(u => 
        u.firebase_uid === firebaseUser.uid || 
        u.email.toLowerCase() === firebaseUser.email?.toLowerCase()
      );
      if (found) {
        setDbUser(found);
        setNombres(found.nombres);
        setApellidos(found.apellidos);
        setTelefono(found.telefono || '');
      }
    } catch (err) {
      console.error(err);
      toast.error('Error al cargar perfil');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfile();
  }, [firebaseUser]);

  const handleLogout = () => {
    signOut(auth);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmedNombres = nombres.trim();
    const trimmedApellidos = apellidos.trim();

    if (!trimmedNombres || !trimmedApellidos) {
      toast.error('Nombres y apellidos son requeridos');
      return;
    }

    if (trimmedNombres.length > 15) {
      toast.error('El nombre no puede tener más de 15 caracteres');
      return;
    }

    if (trimmedApellidos.length > 15) {
      toast.error('El apellido no puede tener más de 15 caracteres');
      return;
    }

    const phone = telefono ? telefono.trim() : '';
    if (phone) {
      if (!phone.startsWith('09')) {
        toast.error('El teléfono debe comenzar con 09');
        return;
      }
      if (phone.length !== 10) {
        toast.error('El teléfono debe tener exactamente 10 dígitos');
        return;
      }
      const numberRegex = /^[0-9]+$/;
      if (!numberRegex.test(phone)) {
        toast.error('El teléfono solo debe contener números');
        return;
      }
    }

    try {
      setSaving(true);
      
      // 1. Actualizar en Firebase Auth
      if (auth.currentUser) {
        await updateProfile(auth.currentUser, {
          displayName: `${nombres.trim()} ${apellidos.trim()}`
        });
      }

      // 2. Actualizar en el Backend
      if (dbUser) {
        const updated = await updateUser(dbUser.id, {
          nombres: nombres.trim(),
          apellidos: apellidos.trim(),
          rol: dbUser.rol,
          telefono: phone || null,
          estado: dbUser.estado
        });
        setDbUser(updated);
      }

      toast.success('Perfil actualizado correctamente');
      setIsEditing(false);
      
      // Recargar el usuario de Firebase para reflejar cambios
      if (auth.currentUser) {
        await auth.currentUser.reload();
      }
    } catch (err: any) {
      console.error("Error al guardar perfil:", err);
      const errMsg = err.response?.data?.message || err.response?.data?.error || err.message || '';
      toast.error(`Error al guardar cambios: ${errMsg}`);
    } finally {
      setSaving(false);
    }
  };

  if (!firebaseUser) return null;

  if (loading) {
    return (
      <div className="w-full max-w-4xl bg-white p-12 rounded-2xl border border-gray-100 shadow-sm text-center text-gray-400 italic">
        Cargando perfil...
      </div>
    );
  }

  const userInitial = (nombres.charAt(0) || firebaseUser.email?.charAt(0) || 'U').toUpperCase();

  return (
    <div className="w-full max-w-4xl bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden transition-all duration-300">
      {/* Banner Superior Monocromo */}
      <div className="h-32 bg-gradient-to-r from-gray-900 via-gray-800 to-gray-950 relative">
        <div className="absolute -bottom-12 left-8">
          <div className="w-24 h-24 rounded-2xl bg-white p-1 shadow-md flex items-center justify-center border border-gray-100">
            <div className="w-full h-full rounded-xl bg-gray-50 flex items-center justify-center text-2xl font-black text-gray-900">
              {userInitial}
            </div>
          </div>
        </div>
      </div>

      <div className="pt-16 p-8">
        {/* Fila superior nombre y badge */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8 pb-6 border-b border-gray-50">
          <div>
            <h2 className="text-2xl font-extrabold text-gray-900">
              {nombres ? `${nombres} ${apellidos}` : (firebaseUser.displayName || 'Usuario')}
            </h2>
            <p className="text-sm text-gray-400 font-medium flex items-center gap-1 mt-1">
              <Mail size={14} />
              {firebaseUser.email}
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <span className="flex items-center gap-1.5 px-3 py-1 bg-black text-white text-[10px] font-bold rounded-full border border-black/10 tracking-wide uppercase">
              <Shield size={12} />
              {dbUser?.rol || 'CLIENTE'}
            </span>
            <span className="flex items-center gap-1.5 px-3 py-1 bg-gray-50 text-gray-500 text-[10px] font-bold rounded-full border border-gray-200 tracking-wide uppercase">
              <UserCheck size={12} />
              Sesión Activa
            </span>
          </div>
        </div>

        {/* Sección de Datos Formulario/Detalle */}
        <form onSubmit={handleSave} noValidate className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Columna Izquierda: Información de Registro / Estado */}
            <div className="md:col-span-1 space-y-4 bg-gray-50/50 p-5 rounded-2xl border border-gray-50">
              <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Resumen</h3>
              <div className="space-y-4">
                <div className="flex items-center gap-3 text-sm text-gray-600">
                  <Calendar className="text-gray-400 flex-shrink-0" size={16} />
                  <div>
                    <span className="block text-[9px] text-gray-400 font-bold uppercase tracking-wider">Miembro desde</span>
                    <span className="font-semibold text-gray-800">
                      {dbUser?.created_at 
                        ? new Date(dbUser.created_at).toLocaleDateString('es-ES', { day: 'numeric', month: 'long', year: 'numeric' })
                        : 'N/A'}
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-3 text-sm text-gray-600">
                  <Shield className="text-gray-400 flex-shrink-0" size={16} />
                  <div>
                    <span className="block text-[9px] text-gray-400 font-bold uppercase tracking-wider">Seguridad</span>
                    <span className="font-semibold text-gray-850">Verificado por Firebase</span>
                  </div>
                </div>
                <div className="flex items-center gap-3 text-sm text-gray-600">
                  <UserCheck className="text-gray-400 flex-shrink-0" size={16} />
                  <div>
                    <span className="block text-[9px] text-gray-400 font-bold uppercase tracking-wider">Estado</span>
                    <span className="font-semibold text-gray-900 flex items-center gap-1 mt-0.5">
                      <div className="w-1.5 h-1.5 rounded-full bg-black animate-pulse"></div>
                      Activo
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Columnas Derecha: Inputs y Datos */}
            <div className="md:col-span-2 space-y-6">
              <div className="flex justify-between items-center">
                <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Datos Personales</h3>
                {!isEditing && (
                  <button
                    type="button"
                    onClick={() => setIsEditing(true)}
                    className="flex items-center gap-1.5 px-3 py-1 bg-white hover:bg-gray-50 border border-gray-200 rounded-lg text-xs font-bold text-gray-600 transition-all shadow-sm hover:text-black"
                  >
                    <Edit2 size={12} />
                    Editar Datos
                  </button>
                )}
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Nombres</label>
                  {isEditing ? (
                    <input
                      type="text"
                      maxLength={15}
                      className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-black/5 text-sm font-semibold text-gray-900"
                      value={nombres}
                      onChange={(e) => setNombres(e.target.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]/g, ''))}
                      required
                    />
                  ) : (
                    <div className="p-3 bg-gray-50/50 border border-gray-100 rounded-xl text-sm font-semibold text-gray-900">
                      {nombres || 'No especificado'}
                    </div>
                  )}
                </div>

                <div>
                  <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Apellidos</label>
                  {isEditing ? (
                    <input
                      type="text"
                      maxLength={15}
                      className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-black/5 text-sm font-semibold text-gray-900"
                      value={apellidos}
                      onChange={(e) => setApellidos(e.target.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]/g, ''))}
                      required
                    />
                  ) : (
                    <div className="p-3 bg-gray-50/50 border border-gray-100 rounded-xl text-sm font-semibold text-gray-900">
                      {apellidos || 'No especificado'}
                    </div>
                  )}
                </div>

                <div className="sm:col-span-2">
                  <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Teléfono</label>
                  {isEditing ? (
                    <div className="relative">
                      <Phone className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                      <input
                        type="text"
                        maxLength={10}
                        className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-black/5 text-sm font-medium text-gray-900"
                        placeholder="Ej. 0999999999"
                        value={telefono}
                        onChange={(e) => setTelefono(e.target.value.replace(/[^0-9]/g, ''))}
                      />
                    </div>
                  ) : (
                    <div className="p-3 bg-gray-50/50 border border-gray-100 rounded-xl text-sm font-medium text-gray-600 flex items-center gap-2">
                      <Phone size={14} className="text-gray-400" />
                      {telefono || 'Sin teléfono registrado'}
                    </div>
                  )}
                </div>
              </div>

              {isEditing && (
                <div className="flex justify-end gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => {
                      setIsEditing(false);
                      if (dbUser) {
                        setNombres(dbUser.nombres);
                        setApellidos(dbUser.apellidos);
                        setTelefono(dbUser.telefono || '');
                      }
                    }}
                    className="flex items-center gap-1.5 px-4 py-2 border border-gray-200 rounded-xl text-xs font-bold hover:bg-gray-50 transition-all text-gray-600"
                  >
                    <X size={14} />
                    Cancelar
                  </button>
                  <button
                    type="submit"
                    disabled={saving}
                    className="flex items-center gap-1.5 px-5 py-2 bg-black text-white hover:bg-black/90 disabled:opacity-50 rounded-xl text-xs font-bold transition-all shadow-sm"
                  >
                    <Save size={14} />
                    {saving ? 'Guardando...' : 'Guardar Cambios'}
                  </button>
                </div>
              )}
            </div>
          </div>
        </form>

        {/* Pie de página */}
        <div className="pt-8 mt-8 border-t border-gray-50 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-xs text-gray-400 italic">
            ProductTech v1.0 • Seguridad y autenticación encriptada
          </p>
          <button
            onClick={handleLogout}
            className="flex items-center gap-2 bg-black text-white hover:bg-black/90 px-6 py-2.5 rounded-xl transition-all font-bold text-sm border border-black/10 shadow-sm"
          >
            <LogOut size={18} />
            Cerrar Sesión
          </button>
        </div>
      </div>
    </div>
  );
};

export default SessionInfo;
