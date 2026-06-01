import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Layout, Mail, Lock, User, Phone, Shield, Eye, EyeOff } from 'lucide-react';
import { createUserWithEmailAndPassword, updateProfile } from 'firebase/auth';
import { auth } from '../services/firebase';
import { api } from '../services/api';
import toast from 'react-hot-toast';

const Register: React.FC = () => {
  const [formData, setFormData] = useState({
    nombres: '',
    apellidos: '',
    email: '',
    password: '',
    telefono: '',
    rol: 'CLIENTE' as 'ADMIN' | 'CLIENTE'
  });
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // 1. Crear usuario en Firebase
      const userCredential = await createUserWithEmailAndPassword(auth, formData.email, formData.password);
      const fbUser = userCredential.user;

      // Actualizar perfil de Firebase con el nombre
      await updateProfile(fbUser, {
        displayName: `${formData.nombres} ${formData.apellidos}`
      });

      // 2. Registrar en la base de datos PostgreSQL a través de la API de Render
      await api.post('/api/usuarios/', {
        firebase_uid: fbUser.uid,
        nombres: formData.nombres,
        apellidos: formData.apellidos,
        email: formData.email,
        rol: formData.rol,
        telefono: formData.telefono
      });

      toast.success('¡Registro exitoso! Iniciando sesión...');
      navigate('/dashboard');
    } catch (err: any) {
      console.error(err);
      toast.error('Error al registrar: ' + (err.response?.data?.message || err.message));
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  return (
    <div className="min-h-screen flex bg-gray-50 font-sans">
      <div className="hidden md:flex md:w-1/2 flex-col justify-between p-12 bg-gray-100 border-r border-gray-200">
        <div>
          <div className="flex items-center gap-2 mb-8">
            <div className="bg-black text-white p-1 rounded">
              <span className="font-bold text-lg">P</span>
            </div>
            <span className="font-bold text-xl">ProductTech</span>
          </div>
          <div className="mt-20 max-w-md">
            <h1 className="text-5xl font-extrabold mt-6 leading-tight text-gray-900">
              Únete a la mejor <span className="text-gray-400">experiencia.</span>
            </h1>
            <p className="text-gray-500 mt-6 text-lg">
              Regístrate para gestionar tus compras, ver productos y administrar tu perfil de forma sencilla.
            </p>
          </div>
        </div>
      </div>

      <div className="flex-1 flex flex-col justify-center items-center p-8 overflow-y-auto">
        <div className="w-full max-w-md bg-white p-10 rounded-2xl shadow-sm border border-gray-100 my-8">
          <h2 className="text-2xl font-bold mb-2">Crear cuenta</h2>
          <p className="text-gray-400 mb-8">Completa tus datos para empezar</p>

          <form onSubmit={handleRegister} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Nombres</label>
                <input
                  name="nombres"
                  type="text"
                  className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5"
                  onChange={handleChange}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Apellidos</label>
                <input
                  name="apellidos"
                  type="text"
                  className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5"
                  onChange={handleChange}
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Correo electrónico</label>
              <input
                name="email"
                type="email"
                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5"
                onChange={handleChange}
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Teléfono</label>
              <input
                name="telefono"
                type="text"
                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5"
                onChange={handleChange}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Rol</label>
              <select
                name="rol"
                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5 bg-white"
                onChange={handleChange}
                value={formData.rol}
              >
                <option value="CLIENTE">Cliente</option>
                <option value="ADMIN">Administrador</option>
              </select>
            </div>

            <div className="relative">
              <label className="block text-sm font-medium text-gray-700 mb-2">Contraseña</label>
              <input
                name="password"
                type={showPassword ? "text" : "password"}
                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-black/5"
                onChange={handleChange}
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-9 text-gray-400"
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-[#111] text-white py-3 rounded-lg font-bold hover:bg-black transition-colors disabled:opacity-50"
            >
              {loading ? 'Registrando...' : 'Registrarse'}
            </button>
          </form>

          <p className="mt-8 text-center text-sm text-gray-500">
            ¿Ya tienes una cuenta?{' '}
            <Link to="/login" className="text-black font-bold hover:underline">
              Inicia sesión
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Register;
