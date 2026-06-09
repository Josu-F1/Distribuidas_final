import React, { useEffect, useState } from 'react';
import { getProducts, deleteProduct, updateProduct, createProduct } from '../services/api';
import { Product } from '../types';
import toast from 'react-hot-toast';
import { Plus, Package, DollarSign, Layout, Layers, Edit2, Power, Search, Filter, X, Image as ImageIcon, ChevronLeft, ChevronRight } from 'lucide-react';

const Products: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('Todos');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;
  const [imageErrors, setImageErrors] = useState<Record<string, boolean>>({});

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, statusFilter]);

  // Estados para el modal (edición o creación)
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [productToDelete, setProductToDelete] = useState<{ id: string; name: string; activo: boolean } | null>(null);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [formData, setFormData] = useState({
    nombre: '',
    descripcion: '',
    precio: 0,
    stock: 0,
    imagen_url: '',
    activo: true
  });

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const data = await getProducts();
      setProducts(data);
    } catch (err) {
      console.error(err);
      toast.error('Error al cargar productos');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, []);

  const handleOpenCreate = () => {
    setEditingProduct(null);
    setFormData({
      nombre: '',
      descripcion: '',
      precio: 0,
      stock: 0,
      imagen_url: '',
      activo: true
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (product: Product) => {
    setEditingProduct(product);
    setFormData({
      nombre: product.nombre,
      descripcion: product.descripcion,
      precio: product.precio,
      stock: product.stock,
      imagen_url: product.imagen_url || '',
      activo: product.activo
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const trimmedNombre = formData.nombre.trim();
    if (!trimmedNombre) {
      toast.error('El nombre del producto es requerido');
      return;
    }

    if (trimmedNombre.length > 30) {
      toast.error('El nombre del producto no puede tener más de 30 caracteres');
      return;
    }

    if (formData.descripcion.trim().length > 50) {
      toast.error('La descripción no puede tener más de 50 caracteres');
      return;
    }

    if (formData.precio <= 0) {
      toast.error('El precio del producto debe ser mayor a 0');
      return;
    }

    if (formData.stock < 0) {
      toast.error('El stock no puede ser negativo');
      return;
    }

    if (!Number.isInteger(Number(formData.stock))) {
      toast.error('El stock debe ser un número entero');
      return;
    }

    try {
      const payload = {
        ...formData,
        nombre: trimmedNombre,
        descripcion: formData.descripcion.trim(),
        precio: Number(formData.precio),
        stock: Number(formData.stock)
      };

      if (editingProduct) {
        await updateProduct(editingProduct.id, payload);
        toast.success('Producto actualizado');
      } else {
        await createProduct(payload);
        toast.success('Producto creado');
      }
      setIsModalOpen(false);
      fetchProducts();
    } catch (err) {
      toast.error('Error al guardar producto');
    }
  };

  const confirmDelete = (product: Product) => {
    setProductToDelete({ id: product.id, name: product.nombre, activo: product.activo });
    setIsDeleteModalOpen(true);
  };

  const handleDelete = async () => {
    if (!productToDelete) return;
    try {
      if (productToDelete.activo) {
        await updateProduct(productToDelete.id, { activo: false });
        toast.success('Producto archivado (borrado lógico)');
      } else {
        await updateProduct(productToDelete.id, { activo: true });
        toast.success('Producto activado');
      }
      setIsDeleteModalOpen(false);
      setProductToDelete(null);
      fetchProducts();
    } catch (err) {
      toast.error('Error al procesar solicitud');
    }
  };

  const filteredProducts = products.filter(product => {
    const matchesSearch = product.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      product.descripcion.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'Todos' ||
      (statusFilter === 'Activo' ? product.activo : !product.activo);
    return matchesSearch && matchesStatus;
  });

  return (
    <div>
      <div className="flex justify-between items-start mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Productos</h1>
          <p className="text-gray-500 mt-1">Gestiona el inventario y catálogo de la tienda.</p>
        </div>
        <button
          onClick={handleOpenCreate}
          className="flex items-center gap-2 bg-black text-white px-4 py-2 rounded-xl text-sm font-bold hover:bg-gray-900 transition-all shadow-sm hover:shadow-md"
        >
          <Plus size={18} />
          Nuevo Producto
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {[
          { label: 'Total productos', value: products.length, icon: <Package size={18} />, trend: 'En el catálogo' },
          { label: 'Productos Activos', value: products.filter(p => p.activo).length, icon: <Layout size={18} />, trend: 'Visibles en tienda' },
          { label: 'Fuera de Stock', value: products.filter(p => p.stock === 0).length, icon: <Layers size={18} />, trend: 'Requiere atención' },
          {
            label: 'Precio Promedio', value: products.length > 0
              ? `$${(products.reduce((acc, p) => acc + Number(p.precio || 0), 0) / products.length).toFixed(2)}`
              : '$0.00', icon: <DollarSign size={18} />, trend: 'Valor medio'
          }
        ].map((stat, i) => (
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
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
            <input
              type="text"
              placeholder="Buscar productos por nombre o descripción..."
              className="w-full pl-9 pr-4 py-2 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-black/5 hover:border-gray-300 transition-colors"
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
          <div className="ml-auto text-xs font-bold text-gray-400 uppercase tracking-wider">{filteredProducts.length} productos</div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/50 text-gray-450 text-[10px] font-bold uppercase tracking-wider border-b border-gray-100">
                <th className="px-6 py-4 w-[40%]">Producto</th>
                <th className="px-6 py-4 w-[15%]">Precio</th>
                <th className="px-6 py-4 w-[15%]">Stock</th>
                <th className="px-6 py-4 w-[15%]">Estado</th>
                <th className="px-6 py-4 w-[15%] text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 text-sm text-gray-600">
              {loading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-400 italic">Cargando productos...</td>
                </tr>
              ) : filteredProducts.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-400 italic">No se encontraron productos.</td>
                </tr>
              ) : filteredProducts.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map(product => (
                <tr
                  key={product.id}
                  className={`hover:bg-slate-50/45 transition-all duration-200 group text-sm text-slate-650 ${product.activo ? 'hover:-translate-y-[0.5px]' : 'opacity-60 bg-slate-50/10'
                    }`}
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      {(() => {
                        let imgUrl = product.imagen_url || (product as any).imagen || (product as any).image_url || (product as any).image;
                        if (imgUrl && typeof imgUrl === 'string' && imgUrl.startsWith('data:image')) {
                          imgUrl = imgUrl.replace(/\s/g, '');
                        }
                        const hasError = imageErrors[product.id];
                        if (imgUrl && !hasError) {
                          return (
                            <img
                              src={imgUrl}
                              alt={product.nombre}
                              className={`w-12 h-12 object-cover rounded-xl border flex-shrink-0 transition-all duration-300 shadow-sm ${product.activo ? 'border-slate-100 group-hover:scale-105' : 'border-slate-200 opacity-60'
                                }`}
                              onError={() => {
                                setImageErrors(prev => ({ ...prev, [product.id]: true }));
                              }}
                            />
                          );
                        }
                        return (
                          <div className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 border transition-all duration-300 ${product.activo
                            ? 'bg-slate-50 text-slate-400 border-slate-150 group-hover:bg-white group-hover:border-slate-200'
                            : 'bg-slate-100/50 text-slate-350 border-slate-200'
                            }`}>
                            <ImageIcon size={20} />
                          </div>
                        );
                      })()}
                      <div className="flex flex-col">
                        <span className={`font-bold transition-all duration-355 ${product.activo ? 'text-slate-900 group-hover:text-black' : 'text-slate-450 line-through'
                          }`}>
                          {product.nombre}
                        </span>
                        <span className={`text-xs transition-all duration-355 ${product.activo ? 'text-slate-400 line-clamp-1 mt-0.5' : 'text-slate-400/80 line-through line-clamp-1 mt-0.5'
                          }`}>
                          {product.descripcion || 'Sin descripción'}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td className={`px-6 py-4 font-bold transition-all duration-355 ${product.activo ? 'text-slate-950' : 'text-slate-400 line-through'}`}>
                    ${Number(product.precio).toFixed(2)}
                  </td>
                  <td className="px-6 py-4 font-medium">
                    <span className={`px-2.5 py-1 rounded-lg text-xs font-bold border transition-all ${!product.activo
                      ? 'bg-slate-100 text-slate-400 border-slate-150 line-through'
                      : product.stock < 5
                        ? 'bg-red-50 text-red-650 border-red-100 animate-pulse'
                        : 'bg-slate-50 text-slate-700 border-slate-150'
                      }`}>
                      {product.stock} uds.
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <button
                      onClick={async () => {
                        try {
                          await updateProduct(product.id, { activo: !product.activo });
                          toast.success(`Producto ${!product.activo ? 'activado' : 'desactivado'}`);
                          fetchProducts();
                        } catch (err) {
                          toast.error('Error al actualizar estado');
                        }
                      }}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[9px] font-black tracking-wider border transition-all ${product.activo
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-100 hover:bg-emerald-100'
                        : 'bg-rose-50 text-rose-700 border-rose-100 hover:bg-rose-100'
                        }`}
                    >
                      <div className={`w-1.5 h-1.5 rounded-full ${product.activo ? 'bg-emerald-500 animate-pulse' : 'bg-rose-400'}`}></div>
                      {product.activo ? 'ACTIVO' : 'BORRADO LÓGICO'}
                    </button>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="inline-flex items-center gap-1.5">
                      <button
                        className="p-2 text-slate-400 hover:text-black hover:bg-white hover:shadow-sm border border-transparent hover:border-slate-150 rounded-xl transition-all disabled:opacity-30 disabled:hover:bg-transparent disabled:hover:shadow-none disabled:hover:border-transparent"
                        onClick={() => handleOpenEdit(product)}
                        disabled={!product.activo}
                        title={product.activo ? "Editar" : "Reactive el producto para editar"}
                      >
                        <Edit2 size={15} />
                      </button>
                      <button
                        className={`p-2 border border-transparent rounded-xl transition-all ${product.activo
                          ? 'text-slate-400 hover:text-rose-600 hover:bg-rose-50 hover:border-rose-100 hover:shadow-sm'
                          : 'text-slate-400 hover:text-emerald-650 hover:bg-emerald-50 hover:border-emerald-100 hover:shadow-sm'
                          }`}
                        onClick={() => confirmDelete(product)}
                        title={product.activo ? "Desactivar (Borrado Lógico)" : "Reactivar"}
                      >
                        <Power size={15} />
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
            Mostrando {filteredProducts.length > 0 ? (currentPage - 1) * itemsPerPage + 1 : 0}-
            {Math.min(currentPage * itemsPerPage, filteredProducts.length)} de {filteredProducts.length} productos
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
              {Array.from({ length: Math.ceil(filteredProducts.length / itemsPerPage) }, (_, i) => i + 1).map(page => (
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
              onClick={() => setCurrentPage(prev => Math.min(prev + 1, Math.ceil(filteredProducts.length / itemsPerPage)))}
              disabled={currentPage === Math.ceil(filteredProducts.length / itemsPerPage) || filteredProducts.length === 0}
              className="p-1.5 border border-gray-200 rounded-lg hover:bg-white disabled:opacity-30 disabled:hover:bg-transparent transition-all shadow-sm"
            >
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      </div>

      {/* Modal de Creación/Edición */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden border border-gray-100">
            <div className="p-6 border-b border-gray-50 flex justify-between items-center bg-gray-50/50">
              <h2 className="text-xl font-bold text-gray-900">
                {editingProduct ? 'Editar Producto' : 'Nuevo Producto'}
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                className="p-1 hover:bg-white rounded-full transition-colors text-gray-400 hover:text-black shadow-sm group"
              >
                <X size={20} className="group-hover:rotate-90 transition-transform" />
              </button>
            </div>

            <form onSubmit={handleSubmit} noValidate className="p-6 space-y-4 max-h-[80vh] overflow-y-auto">
              <div>
                <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Nombre del producto</label>
                <input
                  type="text"
                  maxLength={30}
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-black/5 text-sm font-medium"
                  value={formData.nombre}
                  onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
                  required
                />
              </div>

              <div>
                <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Descripción</label>
                <textarea
                  maxLength={50}
                  className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-black/5 text-sm min-h-20"
                  value={formData.descripcion}
                  onChange={(e) => setFormData({ ...formData, descripcion: e.target.value })}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Precio ($)</label>
                  <input
                    type="number"
                    step="0.01"
                    min="0.01"
                    className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-black/5 text-sm font-bold animate-transition"
                    value={formData.precio || ''}
                    onChange={(e) => {
                      const val = e.target.value === '' ? 0 : parseFloat(e.target.value);
                      setFormData({ ...formData, precio: isNaN(val) ? 0 : val });
                    }}
                    required
                  />
                </div>
                <div>
                  <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">Stock disponible</label>
                  <input
                    type="number"
                    step="1"
                    min="0"
                    className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-black/5 text-sm font-bold animate-transition"
                    value={formData.stock === 0 ? '0' : formData.stock || ''}
                    onChange={(e) => {
                      const val = e.target.value === '' ? 0 : parseInt(e.target.value, 10);
                      setFormData({ ...formData, stock: isNaN(val) ? 0 : val });
                    }}
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1.5 ml-1">URL de Imagen</label>
                <div className="relative">
                  <ImageIcon className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                  <input
                    type="text"
                    className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-black/5 text-sm"
                    value={formData.imagen_url}
                    placeholder="https://..."
                    onChange={(e) => setFormData({ ...formData, imagen_url: e.target.value })}
                  />
                </div>
                {formData.imagen_url && (
                  <div className="mt-3 flex justify-center border border-gray-150 rounded-xl p-2 bg-gray-50/50">
                    <img
                      src={formData.imagen_url}
                      alt="Vista previa del producto"
                      className="max-h-32 object-contain rounded-lg shadow-sm"
                      onError={(e) => {
                        (e.target as HTMLElement).style.display = 'none';
                      }}
                    />
                  </div>
                )}
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="flex-1 px-4 py-2.5 border border-gray-100 rounded-xl text-sm font-bold hover:bg-gray-50 transition-all"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2.5 bg-black text-white rounded-xl text-sm font-bold hover:bg-gray-900 transition-all shadow-sm hover:shadow-md"
                >
                  {editingProduct ? 'Actualizar Producto' : 'Crear Producto'}
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
            <div className={`w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 ${productToDelete?.activo ? 'bg-gray-100 text-gray-900' : 'bg-black text-white'
              }`}>
              {productToDelete?.activo ? <Power size={32} /> : <Package size={32} />}
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">
              {productToDelete?.activo ? '¿Desactivar producto?' : '¿Activar producto?'}
            </h2>
            <p className="text-gray-500 text-sm mb-6">
              Estás a punto de {productToDelete?.activo ? 'desactivar' : 'reactivar'} <span className="font-bold text-gray-900">{productToDelete?.name}</span>.
              {productToDelete?.activo ? ' El producto ya no será visible para los clientes.' : ' El producto volverá a estar disponible en la tienda.'}
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
                {productToDelete?.activo ? 'Desactivar' : 'Activar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Products;
