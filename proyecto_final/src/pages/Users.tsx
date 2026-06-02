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
  ChevronLeft,
  ChevronRight,
  X
} from 'lucide-react';

const Users: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('Todos');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, statusFilter]);
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
      // Filtrar para mostrar solo clientes
      const clientsOnly = data.filter(u => u.rol === 'CLIENTE');
      setUsers(clientsOnly);
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

    const trimmedNombres = editFormData.nombres.trim();
    const trimmedApellidos = editFormData.apellidos.trim();

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

    const nameRegex = /^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/;
    if (!nameRegex.test(trimmedNombres)) {
      toast.error('Los nombres solo deben contener letras');
      return;
    }

    if (!nameRegex.test(trimmedApellidos)) {
      toast.error('Los apellidos solo deben contener letras');
      return;
    }

    const phone = editFormData.telefono ? editFormData.telefono.trim() : '';
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
      await updateUser(editingUser.id, {
        nombres: trimmedNombres,
        apellidos: trimmedApellidos,
        rol: editFormData.rol,
        telefono: phone || '',
        estado: editFormData.estado
      });
      toast.success('Usuario actualizado');
      setEditingUser(null);
      fetchUsers();
    } catch (err: any) {
      console.error("Error al actualizar usuario:", err);
      const errMsg = err.response?.data?.message || err.response?.data?.error || err.message || '';
      toast.error(`Error al actualizar usuario: ${errMsg}`);
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
    const matchesStatus = statusFilter === 'Todos' ||
                         (statusFilter === 'Activo' ? user.estado : !user.estado);

    return matchesSearch && matchesStatus;
  });

  const stats = [
    { label: 'Total clientes', value: users.length, icon: <UsersIcon size={18} />, trend: 'Registrados' },
    { label: 'Activos', value: users.filter(u => u.estado).length, icon: <UserCheck size={18} />, trend: 'Vigentes' },
    { label: 'Inactivos', value: users.filter(u => !u.estado).length, icon: <UserX size={18} />, trend: 'Deshabilitados' },
  ];

  return (
    <div>
      <div className="flex justify-between items-start mb-8">
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Usuarios</h1>
          <p className="text-gray-500 mt-1">Administra los miembros y sus permisos de acceso.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {stats.map((stat, i) => (
          <div
            key={i}
            className="group bg-gradient-to-b from-white to-gray-50/30 p-6 rounded-2xl border border-gray-150 shadow-sm hover:shadow-md hover:border-gray-250 transition-all duration-300 hover:-translate-y-0.5 cursor-default"
          >
            <div className="flex justify-between items-center mb-4">
              <span className="text-xs font-bold text-gray-400 uppercase tracking-wider">{stat.label}</span>
              <div className="bg-gray-50 p-2 rounded-xl text-gray-600 group-hover:bg-black group-hover:text-white transition-all duration-300 border border-gray-100">
                {stat.icon}
              </div>
            </div>
            <div className="text-3xl font-black text-gray-950 tracking-tight">{stat.value}</div>
            <div className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mt-2 flex items-center gap-1">
              <div className="w-1.5 h-1.5 rounded-full bg-black"></div>
              {stat.trend}
            </div>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden transition-all duration-300">
        <div className="p-5 border-b border-gray-50 flex flex-col sm:flex-row items-center gap-4 bg-gray-50/20">
           <div className="flex-1 max-w-sm relative w-full">
              <input
                type="text"
                placeholder="Buscar usuario por nombre o correo..."
                className="w-full pl-4 pr-4 py-2 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-black/5 hover:border-gray-300 transition-colors"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
           </div>
           <select
             className="w-full sm:w-auto px-4 py-2 bg-white border border-gray-200 rounded-xl text-sm text-gray-600 outline-none hover:border-gray-300 transition-colors cursor-pointer"
             value={statusFilter}
             onChange={(e) => setStatusFilter(e.target.value)}
           >
             <option value="Todos">Todos los estados</option>
             <option value="Activo">Activo</option>
             <option value="Inactivo">Inactivo</option>
           </select>
           <div className="ml-auto text-xs font-bold text-gray-400 uppercase tracking-wider">{filteredUsers.length} clientes</div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/50 text-gray-450 text-[10px] font-bold uppercase tracking-wider border-b border-gray-100">
                <th className="px-6 py-4 w-[20%]">Usuario</th>
                <th className="px-6 py-4 w-[25%]">Correo</th>
                <th className="px-6 py-4 w-[18%]">Teléfono</th>
                <th className="px-6 py-4 w-[12%]">Estado</th>
                <th className="px-6 py-4 w-[13%]">Registro</th>
                <th className="px-6 py-4 w-[12%] text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {loading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-400 italic">Cargando usuarios...</td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-400 italic">No se encontraron usuarios</td>
                </tr>
              ) : filteredUsers.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map((user) => (
                <tr key={user.id} className="hover:bg-gray-50/40 transition-all duration-200 group text-sm text-gray-600 hover:-translate-y-[0.5px]">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-xl bg-gray-50 flex items-center justify-center font-bold text-gray-600 text-xs uppercase border border-gray-100 group-hover:border-black/10 group-hover:bg-white transition-all duration-300">
                        {user.nombres.charAt(0)}
                      </div>
                      <div className="flex flex-col">
                        <span className="font-bold text-gray-900 group-hover:text-black transition-colors">{user.nombres} {user.apellidos}</span>
                        <span className="text-[10px] text-gray-400 font-bold uppercase tracking-wider mt-0.5">Cliente</span>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 font-medium">{user.email}</td>
                  <td className="px-6 py-4 font-medium">{user.telefono || '-'}</td>
                  <td className="px-6 py-4">
                    <button
                      onClick={() => toggleStatus(user)}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[9px] font-bold tracking-wider border transition-all ${
                        user.estado
                          ? 'bg-black text-white border-black/10 hover:bg-black/90'
                          : 'bg-gray-100 text-gray-500 border-gray-200 hover:bg-gray-200/60'
                      }`}
                    >
                      <div className={`w-1.5 h-1.5 rounded-full ${user.estado ? 'bg-white animate-pulse' : 'bg-gray-400'}`}></div>
                      {user.estado ? 'ACTIVO' : 'DESACTIVADO'}
                    </button>
                  </td>
                  <td className="px-6 py-4 text-gray-450 text-xs font-semibold">
                    {new Date(user.created_at).toLocaleDateString('es-ES', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="inline-flex items-center gap-1.5">
                       <button
                         className="p-2 text-gray-400 hover:text-black hover:bg-white hover:shadow-sm border border-transparent hover:border-gray-150 rounded-xl transition-all"
                         onClick={() => handleEditClick(user)}
                       >
                         <Edit2 size={15} />
                       </button>
                       <button
                         className={`p-2 text-gray-400 hover:bg-white hover:shadow-sm border border-transparent hover:border-gray-150 rounded-xl transition-all ${
                           user.estado ? 'hover:text-red-500' : 'hover:text-green-500'
                         }`}
                         onClick={() => confirmDelete(user)}
                         title={user.estado ? "Desactivar" : "Activar"}
                       >
                         {user.estado ? <UserX size={15} /> : <UserCheck size={15} />}
                       </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="p-4 border-t border-gray-50 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs font-bold text-gray-400 uppercase tracking-wider bg-gray-50/20">
          <div>
            Mostrando {filteredUsers.length > 0 ? (currentPage - 1) * itemsPerPage + 1 : 0}-
            {Math.min(currentPage * itemsPerPage, filteredUsers.length)} de {filteredUsers.length} clientes
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
              disabled={currentPage === 1}
              className="p-1.5 border border-gray-200 rounded-lg hover:bg-white disabled:opacity-30 disabled:hover:bg-transparent transition-all shadow-sm"
            >
              <ChevronLeft size={16} />
            </button>
            <div className="flex items-center gap-1 font-semibold">
              {Array.from({ length: Math.ceil(filteredUsers.length / itemsPerPage) }, (_, i) => i + 1).map(page => (
                <button
                  key={page}
                  onClick={() => setCurrentPage(page)}
                  className={`w-7 h-7 rounded-lg flex items-center justify-center transition-all ${currentPage === page ? 'bg-black text-white shadow-sm' : 'text-gray-500 hover:bg-white hover:shadow-sm border border-transparent hover:border-gray-150'}`}
                >
                  {page}
                </button>
              ))}
            </div>
            <button
              onClick={() => setCurrentPage(prev => Math.min(prev + 1, Math.ceil(filteredUsers.length / itemsPerPage)))}
              disabled={currentPage === Math.ceil(filteredUsers.length / itemsPerPage) || filteredUsers.length === 0}
              className="p-1.5 border border-gray-200 rounded-lg hover:bg-white disabled:opacity-30 disabled:hover:bg-transparent transition-all shadow-sm"
            >
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
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleUpdate} noValidate className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Nombres</label>
                  <input
                    type="text"
                    maxLength={15}
                    className="w-full px-4 py-2 bg-gray-50 border border-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 text-sm"
                    value={editFormData.nombres}
                    onChange={(e) => setEditFormData({ ...editFormData, nombres: e.target.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]/g, '') })}
                    required
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Apellidos</label>
                  <input
                    type="text"
                    maxLength={15}
                    className="w-full px-4 py-2 bg-gray-50 border border-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 text-sm"
                    value={editFormData.apellidos}
                    onChange={(e) => setEditFormData({ ...editFormData, apellidos: e.target.value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]/g, '') })}
                    required
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase mb-1">Teléfono</label>
                <input
                  type="tel"
                  maxLength={10}
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 text-sm"
                  value={editFormData.telefono || ''}
                  onChange={(e) => setEditFormData({ ...editFormData, telefono: e.target.value.replace(/[^0-9]/g, '') })}
                  placeholder="Ej: 0999999999"
                />
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
              userToDelete?.estado ? 'bg-gray-100 text-gray-900' : 'bg-black text-white'
            }`}>
              {userToDelete?.estado ? <UserX size={32} /> : <UserCheck size={32} />}
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
                className="flex-1 px-4 py-2.5 text-white bg-black hover:bg-black/90 rounded-xl text-sm font-bold transition-all shadow-sm"
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
