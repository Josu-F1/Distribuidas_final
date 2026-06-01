import React, { useEffect, useState } from 'react';
import { getUsers, deleteUser, updateUser } from '../services/api';
import { User } from '../types';
import toast from 'react-hot-toast';
import { 
  Plus, 
  Users as UsersIcon, 
  UserCheck, 
  UserX, 
  Shield, 
  MoreHorizontal,
  Edit2,
  Trash2,
  ChevronLeft,
  ChevronRight
} from 'lucide-react';

const Users: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('Todos');
  const [statusFilter, setStatusFilter] = useState('Todos');
  
  // Estados para el modal de edición
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [userToDelete, setUserToDelete] = useState<{ id: string; name: string; estado: boolean } | null>(null);
  const [editFormData, setEditFormData] = useState<{
    nombres: string;
    apellidos: string;
    rol: 'CLIENTE' | 'ADMIN';
    telefono: string;
    estado: boolean;
  }>({
    nombres: '',
    apellidos: '',
    rol: 'CLIENTE',
    telefono: '',
    estado: true
  });

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const data = await getUsers();
      setUsers(data);
    } catch (err) {
      console.error(err);
      toast.error('Error al cargar usuarios');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleEditClick = (user: User) => {
    setEditingUser(user);
    setEditFormData({
      nombres: user.nombres,
      apellidos: user.apellidos,
      rol: user.rol,
      telefono: user.telefono || '',
      estado: user.estado
    });
  };

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser) return;
    try {
      await updateUser(editingUser.id, editFormData);
      toast.success('Usuario actualizado');
      setEditingUser(null);
      fetchUsers();
    } catch (err) {
      toast.error('Error al actualizar usuario');
    }
  };

  const confirmDelete = (user: User) => {
    setUserToDelete({ 
      id: user.id, 
      name: `${user.nombres} ${user.apellidos}`, 
      estado: user.estado 
    });
    setIsDeleteModalOpen(true);
  };

  const handleDelete = async () => {
    if (!userToDelete) return;
    try {
      // Usamos updateUser para cambiar el estado si queremos reactivar, 
      // o deleteUser si queremos desactivar (que ya hace update a false)
      if (userToDelete.estado) {
        await deleteUser(userToDelete.id);
        toast.success('Usuario desactivado');
      } else {
        await updateUser(userToDelete.id, { estado: true });
        toast.success('Usuario activado');
      }
      setIsDeleteModalOpen(false);
      setUserToDelete(null);
      fetchUsers();
    } catch (err) {
      toast.error('Error al procesar solicitud');
    }
  };

  const toggleStatus = async (user: User) => {
    try {
      await updateUser(user.id, { estado: !user.estado });
      toast.success(`Usuario ${!user.estado ? 'activado' : 'desactivado'}`);
      fetchUsers();
    } catch (err) {
      toast.error('Error al actualizar estado');
    }
  };

  const filteredUsers = users.filter(user => {
    const fullName = `${user.nombres} ${user.apellidos}`.toLowerCase();
    const email = user.email.toLowerCase();
    const search = searchTerm.toLowerCase();
    
    const matchesSearch = fullName.includes(search) || email.includes(search);
    const matchesRole = roleFilter === 'Todos' || user.rol === roleFilter;
    const matchesStatus = statusFilter === 'Todos' || 
                         (statusFilter === 'Activo' ? user.estado : !user.estado);
    
    return matchesSearch && matchesRole && matchesStatus;
  });

  const stats = [
    { label: 'Total usuarios', value: users.length, icon: <UsersIcon size={18} />, trend: 'Registrados' },
    { label: 'Activos', value: users.filter(u => u.estado).length, icon: <UserCheck size={18} />, trend: 'Vigentes' },
    { label: 'Inactivos', value: users.filter(u => !u.estado).length, icon: <UserX size={18} />, trend: 'Deshabilitados' },
    { label: 'Administradores', value: users.filter(u => u.rol === 'ADMIN').length, icon: <Shield size={18} />, trend: 'Acceso completo' },
  ];

  return (
    <div>
      <div className="flex justify-between items-start mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Usuarios</h1>
          <p className="text-gray-500 mt-1">Administra los miembros y sus permisos de acceso.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {stats.map((stat, i) => (
          <div key={i} className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
            <div className="flex justify-between items-start mb-4">
              <span className="text-sm font-medium text-gray-500">{stat.label}</span>
              <div className="bg-gray-50 p-2 rounded-lg text-gray-600">
                {stat.icon}
              </div>
            </div>
            <div className="text-2xl font-bold text-gray-900">{stat.value}</div>
            <div className="text-xs text-gray-400 mt-1">{stat.trend}</div>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-gray-50 flex items-center gap-4">
           <div className="flex-1 max-w-sm">
              <input 
                type="text" 
                placeholder="Buscar usuario..." 
                className="w-full px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-1 focus:ring-black/5" 
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
           </div>
           <select 
             className="px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm text-gray-600 outline-none"
             value={roleFilter}
             onChange={(e) => setRoleFilter(e.target.value)}
           >
             <option value="Todos">Todos los roles</option>
             <option value="ADMIN">Administrador</option>
             <option value="CLIENTE">Cliente</option>
           </select>
           <select 
             className="px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm text-gray-600 outline-none"
             value={statusFilter}
             onChange={(e) => setStatusFilter(e.target.value)}
           >
             <option value="Todos">Todos los estados</option>
             <option value="Activo">Activo</option>
             <option value="Inactivo">Inactivo</option>
           </select>
           <div className="ml-auto text-xs text-gray-400 font-medium">{filteredUsers.length} usuarios</div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-white text-gray-400 text-[11px] font-bold uppercase tracking-wider border-b border-gray-100">
                <th className="px-6 py-4">Usuario</th>
                <th className="px-6 py-4">Correo</th>
                <th className="px-6 py-4">Rol</th>
                <th className="px-6 py-4">Estado</th>
                <th className="px-6 py-4">Registro</th>
                <th className="px-6 py-4 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-400 italic">Cargando usuarios...</td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-400 italic">No se encontraron usuarios</td>
                </tr>
              ) : filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50/50 transition-colors group text-sm text-gray-600">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center font-bold text-gray-600 text-xs uppercase">
                        {user.nombres.charAt(0)}
                      </div>
                      <span className="font-semibold text-gray-900">{user.nombres} {user.apellidos}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">{user.email}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2.5 py-0.5 rounded text-[11px] font-bold uppercase tracking-tight ${
                      user.rol === 'ADMIN' ? 'bg-black text-white' : 
                      'bg-gray-100 text-gray-600'
                    }`}>
                      {user.rol}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <button 
                      onClick={() => toggleStatus(user)}
                      className={`flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-bold transition-all ${
                        user.estado 
                          ? 'bg-green-50 text-green-600 hover:bg-green-100' 
                          : 'bg-red-50 text-red-600 hover:bg-red-100'
                      }`}
                    >
                      <div className={`w-1.5 h-1.5 rounded-full ${user.estado ? 'bg-green-500' : 'bg-red-500'}`}></div>
                      {user.estado ? 'ACTIVO' : 'DESACTIVADO'}
                    </button>
                  </td>
                  <td className="px-6 py-4 text-gray-400 text-xs">
                    {new Date(user.created_at).toLocaleDateString('es-ES', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex justify-end gap-2">
                       <button 
                         className="p-1.5 text-gray-300 hover:text-black hover:bg-white hover:shadow-sm rounded-lg transition-all"
                         onClick={() => handleEditClick(user)}
                       >
                         <Edit2 size={16} />
                       </button>
                       <button 
                         className="p-1.5 text-gray-300 hover:text-red-500 hover:bg-white hover:shadow-sm rounded-lg transition-all"
                         onClick={() => confirmDelete(user)}
                       >
                         <Trash2 size={16} />
                       </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="p-4 border-t border-gray-50 flex items-center justify-between text-xs font-medium text-gray-400">
          <div>Mostrando 1-{users.length} de {users.length} usuarios</div>
          <div className="flex items-center gap-2">
            <button className="p-1 border border-gray-200 rounded-md hover:bg-gray-50 disabled:opacity-30" disabled>
              <ChevronLeft size={16} />
            </button>
            <div className="flex items-center gap-1">
              <button className="w-6 h-6 rounded-md bg-black text-white flex items-center justify-center">1</button>
            </div>
            <button className="p-1 border border-gray-200 rounded-md hover:bg-gray-50 disabled:opacity-30" disabled>
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      </div>

      {/* Modal de Edición */}
      {editingUser && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-gray-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-gray-900">Editar Usuario</h2>
              <button onClick={() => setEditingUser(null)} className="text-gray-400 hover:text-black">
                <Trash2 size={20} className="rotate-45" />
              </button>
            </div>
            <form onSubmit={handleUpdate} className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Nombres</label>
                  <input
                    type="text"
                    className="w-full px-4 py-2 bg-gray-50 border border-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 text-sm"
                    value={editFormData.nombres}
                    onChange={(e) => setEditFormData({ ...editFormData, nombres: e.target.value })}
                    required
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Apellidos</label>
                  <input
                    type="text"
                    className="w-full px-4 py-2 bg-gray-50 border border-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 text-sm"
                    value={editFormData.apellidos}
                    onChange={(e) => setEditFormData({ ...editFormData, apellidos: e.target.value })}
                    required
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Teléfono</label>
                <input
                  type="text"
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 text-sm"
                  value={editFormData.telefono}
                  onChange={(e) => setEditFormData({ ...editFormData, telefono: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Rol</label>
                <select
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 text-sm"
                  value={editFormData.rol}
                  onChange={(e) => setEditFormData({ ...editFormData, rol: e.target.value as 'ADMIN' | 'CLIENTE' })}
                >
                  <option value="CLIENTE">Cliente</option>
                  <option value="ADMIN">Administrador</option>
                </select>
              </div>
              <div className="flex items-center gap-2 py-2">
                <input
                  type="checkbox"
                  id="edit-estado"
                  checked={editFormData.estado}
                  onChange={(e) => setEditFormData({ ...editFormData, estado: e.target.checked })}
                  className="w-4 h-4 rounded border-gray-300 text-black focus:ring-black"
                />
                <label htmlFor="edit-estado" className="text-sm font-medium text-gray-700">Usuario Activo</label>
              </div>
              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setEditingUser(null)}
                  className="flex-1 px-4 py-2 border border-gray-100 rounded-lg text-sm font-bold hover:bg-gray-50 transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-black text-white rounded-lg text-sm font-bold hover:bg-gray-900 transition-colors"
                >
                  Guardar Cambios
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal de Confirmación de Eliminación */}
      {isDeleteModalOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-60 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden border border-gray-100 p-6 text-center">
            <div className={`w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 ${
              userToDelete?.estado ? 'bg-red-50 text-red-500' : 'bg-green-50 text-green-500'
            }`}>
              {userToDelete?.estado ? <Trash2 size={32} /> : <UserCheck size={32} />}
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">
              {userToDelete?.estado ? '¿Desactivar usuario?' : '¿Activar usuario?'}
            </h2>
            <p className="text-gray-500 text-sm mb-6">
              Estás a punto de {userToDelete?.estado ? 'desactivar' : 'activar'} a <span className="font-bold text-gray-900">{userToDelete?.name}</span>. 
              {userToDelete?.estado ? ' El usuario ya no podrá acceder al sistema.' : ' El usuario recuperará su acceso al sistema.'}
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setIsDeleteModalOpen(false)}
                className="flex-1 px-4 py-2.5 border border-gray-100 rounded-xl text-sm font-bold hover:bg-gray-50 transition-all"
              >
                Cancelar
              </button>
              <button
                onClick={handleDelete}
                className={`flex-1 px-4 py-2.5 text-white rounded-xl text-sm font-bold transition-all shadow-sm ${
                  userToDelete?.estado ? 'bg-red-500 hover:bg-red-600' : 'bg-green-500 hover:bg-green-600'
                }`}
              >
                {userToDelete?.estado ? 'Desactivar' : 'Activar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Users;
