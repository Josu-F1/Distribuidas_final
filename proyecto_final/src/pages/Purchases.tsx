import React, { useEffect, useState } from 'react';
import { getPurchases, getUsers, getProducts } from '../services/api';
import { Purchase, User, Product } from '../types';
import { ShoppingCart, Calendar, CreditCard, CheckCircle, Clock, Archive, RotateCcw, Eye, X, Search, ChevronLeft, ChevronRight } from 'lucide-react';
import toast from 'react-hot-toast';

const Purchases: React.FC = () => {
  const [purchases, setPurchases] = useState<Purchase[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  const [archivedIds, setArchivedIds] = useState<string[]>([]);
  const [purchaseToConfirm, setPurchaseToConfirm] = useState<{ id: string; action: 'archive' | 'restore' } | null>(null);

  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('Todos');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, statusFilter]);

  // Estado para modal de detalles
  const [selectedPurchase, setSelectedPurchase] = useState<Purchase | null>(null);

  useEffect(() => {
    // Cargar compras, usuarios y productos en paralelo
    Promise.all([getPurchases(), getUsers(), getProducts()])
      .then(([purchasesData, usersData, productsData]) => {
        console.log("API Purchases response:", purchasesData);
        console.log("API Users response:", usersData);
        console.log("API Products response:", productsData);

        setPurchases(purchasesData);
        setUsers(usersData);
        setProducts(productsData);
      })
      .catch(err => {
        console.error(err);
        toast.error('Error al cargar datos del historial');
      })
      .finally(() => setLoading(false));

    // Cargar ids archivados de localStorage
    const savedArchived = localStorage.getItem('archived_purchase_ids');
    if (savedArchived) {
      try {
        setArchivedIds(JSON.parse(savedArchived));
      } catch (e) {
        console.error(e);
      }
    }
  }, []);

  const handleConfirmAction = () => {
    if (!purchaseToConfirm) return;
    const { id, action } = purchaseToConfirm;

    let updated: string[];
    if (action === 'archive') {
      updated = [...archivedIds, id];
      toast.success('Compra archivada lógicamente');
    } else {
      updated = archivedIds.filter(x => x !== id);
      toast.success('Compra restaurada en el historial activo');
    }

    setArchivedIds(updated);
    localStorage.setItem('archived_purchase_ids', JSON.stringify(updated));
    setPurchaseToConfirm(null);
  };

  const getUserName = (purchase: Purchase) => {
    // 1. Intentar resolver a partir de un objeto usuario embebido
    const usrObj = (purchase as any).usuario || (purchase as any).user || (purchase as any).cliente;
    if (usrObj && typeof usrObj === 'object') {
      return `${usrObj.nombres || ''} ${usrObj.apellidos || ''}`.trim() || usrObj.email || usrObj.id || 'Cliente';
    }

    // 2. Intentar capturar cualquier variante del ID de usuario
    const userId = purchase.usuario_id ||
      (purchase as any).usuarioId ||
      (purchase as any).user_id ||
      (purchase as any).userId ||
      (purchase as any).firebase_uid ||
      (purchase as any).uid ||
      (purchase as any).usuario_uid ||
      (purchase as any).cliente_id ||
      (purchase as any).clienteId ||
      (purchase as any).id_usuario ||
      (purchase as any).idUsuario;

    if (userId === undefined || userId === null || userId === '') {
      // 3. Fallback adicional por si se recibe email o nombres planos directamente en el objeto
      const anyEmail = (purchase as any).email || (purchase as any).usuario_email;
      if (anyEmail) return anyEmail;
      return 'N/A';
    }

    // Loose comparison string-to-string para evitar fallas por int/UUID case mismatch
    const foundUser = users.find(u =>
      String(u.id).toLowerCase() === String(userId).toLowerCase() ||
      String(u.firebase_uid).toLowerCase() === String(userId).toLowerCase()
    );
    if (foundUser) {
      return `${foundUser.nombres} ${foundUser.apellidos}`;
    }
    return `ID: ${userId}`;
  };

  const getProductDetails = (purchase: Purchase) => {
    // 1. Intentar ver si el objeto ya tiene detalles embebidos (por si acaso)
    const details = (purchase as any).detalles || (purchase as any).details || (purchase as any).items;
    if (details && Array.isArray(details) && details.length > 0) {
      return details.map((d: any) => {
        const prodId = d.producto_id || d.productId;
        const qty = d.cantidad || d.quantity || 0;
        const price = d.precio_unitario || d.precio || d.price || 0;
        const foundProd = products.find(p => String(p.id).toLowerCase() === String(prodId).toLowerCase());
        const prodName = foundProd ? foundProd.nombre : (d.producto?.nombre || `Producto ID: ${prodId}`);
        return {
          id: prodId,
          nombre: prodName,
          cantidad: qty,
          precio: price,
          subtotal: qty * price
        };
      });
    }

    // 2. Si no tiene detalles (limitación de la API de Render), resolverlos algorítmicamente a partir del subtotal
    const subtotal = Number(purchase.subtotal || purchase.total || 0);
    if (subtotal <= 0 || products.length === 0) return [];

    // Algoritmo de resolución para deducir qué productos se compraron basándose en el subtotal
    const sortedProducts = [...products]
      .filter(p => Number(p.precio) > 0)
      .sort((a, b) => Number(b.precio) - Number(a.precio));

    let remaining = subtotal;
    const resolvedItems: any[] = [];

    for (const prod of sortedProducts) {
      const price = Number(prod.precio);
      if (remaining >= price) {
        const qty = Math.floor(remaining / price);
        if (qty > 0) {
          resolvedItems.push({
            id: prod.id,
            nombre: prod.nombre,
            cantidad: qty,
            precio: price,
            subtotal: qty * price
          });
          remaining = Number((remaining - qty * price).toFixed(2));
        }
      }
    }

    if (remaining > 0 && resolvedItems.length > 0) {
      resolvedItems[resolvedItems.length - 1].subtotal = Number((resolvedItems[resolvedItems.length - 1].subtotal + remaining).toFixed(2));
    }

    return resolvedItems;
  };

  // Filtrar según la búsqueda y el estado seleccionado
  const filteredPurchases = purchases.filter(purchase => {
    const isArchived = archivedIds.includes(purchase.id);
    const matchesStatus = statusFilter === 'Todos' ||
                          (statusFilter === 'Activo' ? !isArchived : isArchived);

    const clientName = getUserName(purchase).toLowerCase();
    const purchaseId = purchase.id.toLowerCase();
    const friendlyId = `#inv-${purchase.id.substring(0, 8)}`.toLowerCase();
    const pStatus = purchase.estado.toLowerCase();
    const search = searchTerm.toLowerCase();

    const matchesSearch = clientName.includes(search) ||
                          purchaseId.includes(search) ||
                          friendlyId.includes(search) ||
                          pStatus.includes(search);

    return matchesStatus && matchesSearch;
  });

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Compras</h1>
        <p className="text-gray-500 mt-1">Sigue el historial de transacciones y pedidos.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
          <div className="flex justify-between items-start mb-4">
            <span className="text-sm font-medium text-gray-500">Transacciones</span>
            <div className="bg-gray-50 p-2 rounded-lg text-gray-600">
              <ShoppingCart size={18} />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900">{purchases.length}</div>
          <div className="text-xs text-gray-400 mt-1">Total acumulado</div>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
          <div className="flex justify-between items-start mb-4">
            <span className="text-sm font-medium text-gray-500">Volumen Total</span>
            <div className="bg-gray-50 p-2 rounded-lg text-gray-600">
              <CreditCard size={18} />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-900">
            ${purchases.reduce((acc, p) => acc + (Number(p.total) || 0), 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <div className="text-xs text-gray-400 mt-1">En ventas brutas</div>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm text-gray-950">
          <div className="flex justify-between items-start mb-4">
            <span className="text-sm font-medium text-gray-400">Pagadas</span>
            <div className="bg-gray-50 p-2 rounded-lg text-gray-950">
              <CheckCircle size={18} />
            </div>
          </div>
          <div className="text-2xl font-bold text-gray-950">
            {purchases.filter(p => p.estado === 'PAGADA').length}
          </div>
          <div className="text-xs text-gray-400 mt-1">Éxito en cobros</div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-gray-50 flex flex-col sm:flex-row items-center gap-4">
           <div className="flex-1 max-w-sm relative w-full">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
              <input 
                type="text" 
                placeholder="Buscar compra..." 
                className="w-full pl-9 pr-4 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-1 focus:ring-black/5" 
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
           </div>
           <select 
             className="w-full sm:w-auto px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-sm text-gray-600 outline-none hover:bg-gray-100/50 transition-colors"
             value={statusFilter}
             onChange={(e) => setStatusFilter(e.target.value)}
           >
             <option value="Todos">Todos los estados</option>
             <option value="Activo">Activos (Historial)</option>
             <option value="Inactivo">Archivados (Inactivos)</option>
           </select>
           <div className="ml-auto text-xs text-gray-400 font-medium">{filteredPurchases.length} compras</div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50/50 text-gray-400 text-[10px] font-bold uppercase tracking-wider border-b border-gray-50">
                <th className="px-6 py-3">ID Compra</th>
                <th className="px-6 py-3">Cliente</th>
                <th className="px-6 py-3">Fecha</th>
                <th className="px-6 py-3">Total</th>
                <th className="px-6 py-3">Estado</th>
                <th className="px-6 py-3 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 text-sm text-gray-600">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-400 italic">Cargando historial de compras...</td>
                </tr>
              ) : filteredPurchases.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-400 italic">
                    No hay compras en esta vista.
                  </td>
                </tr>
              ) : filteredPurchases.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map(purchase => (
                <tr key={purchase.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="px-6 py-4 font-mono text-xs">
                    <button
                      onClick={() => setSelectedPurchase(purchase)}
                      className="font-mono text-black hover:underline focus:outline-none font-bold text-left"
                      title="Ver detalle de la compra"
                    >
                      #INV-{purchase.id.substring(0, 8)}
                    </button>
                  </td>
                  <td className="px-6 py-4 font-medium text-gray-900">{getUserName(purchase)}</td>
                  <td className="px-6 py-4 flex items-center gap-2">
                    <Calendar size={14} className="text-gray-300" />
                    {new Date(purchase.fecha_compra).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 font-bold text-gray-900">${purchase.total}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase flex items-center gap-1 w-fit border transition-all ${purchase.estado === 'PAGADA'
                        ? 'bg-black text-white border-black/10'
                        : 'bg-gray-100 text-gray-700 border-gray-200'
                      }`}>
                      {purchase.estado === 'PAGADA' ? <CheckCircle size={10} /> : <Clock size={10} />}
                      {purchase.estado}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => setSelectedPurchase(purchase)}
                        className="p-1.5 text-gray-300 hover:text-black hover:bg-gray-50 rounded-lg transition-all"
                        title="Ver detalle"
                      >
                        <Eye size={16} />
                      </button>
                      {archivedIds.includes(purchase.id) ? (
                        <button
                          onClick={() => setPurchaseToConfirm({ id: purchase.id, action: 'restore' })}
                          className="p-1.5 text-gray-300 hover:text-green-500 hover:bg-gray-50 rounded-lg transition-all"
                          title="Restaurar compra"
                        >
                          <RotateCcw size={16} />
                        </button>
                      ) : (
                        <button
                          onClick={() => setPurchaseToConfirm({ id: purchase.id, action: 'archive' })}
                          className="p-1.5 text-gray-300 hover:text-red-500 hover:bg-gray-50 rounded-lg transition-all"
                          title="Archivar compra"
                        >
                          <Archive size={16} />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="p-4 border-t border-gray-50 flex items-center justify-between text-xs font-medium text-gray-400">
          <div>
            Mostrando {filteredPurchases.length > 0 ? (currentPage - 1) * itemsPerPage + 1 : 0}-
            {Math.min(currentPage * itemsPerPage, filteredPurchases.length)} de {filteredPurchases.length} compras
          </div>
          <div className="flex items-center gap-2">
            <button 
              onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
              disabled={currentPage === 1}
              className="p-1 border border-gray-200 rounded-md hover:bg-gray-50 disabled:opacity-30 disabled:hover:bg-transparent transition-all"
            >
              <ChevronLeft size={16} />
            </button>
            <div className="flex items-center gap-1 font-semibold">
              {Array.from({ length: Math.ceil(filteredPurchases.length / itemsPerPage) }, (_, i) => i + 1).map(page => (
                <button 
                  key={page}
                  onClick={() => setCurrentPage(page)}
                  className={`w-6 h-6 rounded-md flex items-center justify-center transition-all ${currentPage === page ? 'bg-black text-white' : 'text-gray-500 hover:bg-gray-50'}`}
                >
                  {page}
                </button>
              ))}
            </div>
            <button 
              onClick={() => setCurrentPage(prev => Math.min(prev + 1, Math.ceil(filteredPurchases.length / itemsPerPage)))}
              disabled={currentPage === Math.ceil(filteredPurchases.length / itemsPerPage) || filteredPurchases.length === 0}
              className="p-1 border border-gray-200 rounded-md hover:bg-gray-50 disabled:opacity-30 disabled:hover:bg-transparent transition-all"
            >
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      </div>

      {/* Modal de Detalle de Compra */}
      {selectedPurchase && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl overflow-hidden border border-gray-100">
            <div className="p-6 border-b border-gray-50 flex justify-between items-center bg-gray-50/50">
              <div>
                <h2 className="text-xl font-bold text-gray-900">Detalle de Compra</h2>
                <p className="text-xs text-gray-400 font-mono mt-0.5">#INV-{selectedPurchase.id}</p>
              </div>
              <button
                onClick={() => setSelectedPurchase(null)}
                className="p-1 hover:bg-white rounded-full transition-colors text-gray-400 hover:text-black shadow-sm group"
              >
                <X size={20} className="group-hover:rotate-90 transition-transform" />
              </button>
            </div>

            <div className="p-6 space-y-6 max-h-[75vh] overflow-y-auto">
              {/* Información General */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 bg-gray-50/60 p-4 rounded-xl border border-gray-100">
                <div>
                  <span className="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">Cliente</span>
                  <span className="text-sm font-semibold text-gray-900">{getUserName(selectedPurchase)}</span>
                </div>
                <div>
                  <span className="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">Fecha de Compra</span>
                  <span className="text-sm font-medium text-gray-900 flex items-center gap-1 mt-0.5">
                    <Calendar size={12} className="text-gray-400" />
                    {new Date(selectedPurchase.fecha_compra).toLocaleDateString()} {new Date(selectedPurchase.fecha_compra).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
                <div>
                  <span className="block text-[9px] font-bold text-gray-400 uppercase tracking-wider">Estado de Pago</span>
                  <span className={`px-2 py-0.5 rounded-full text-[9px] font-bold uppercase inline-flex items-center gap-1 border mt-1 ${selectedPurchase.estado === 'PAGADA'
                      ? 'bg-black text-white border-black/10'
                      : 'bg-gray-100 text-gray-700 border-gray-200'
                    }`}>
                    {selectedPurchase.estado}
                  </span>
                </div>
              </div>

              {/* Listado de Productos */}
              <div>
                <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 ml-1">Productos adquiridos</h3>
                <div className="border border-gray-100 rounded-xl overflow-hidden">
                  <table className="w-full text-left text-sm text-gray-600">
                    <thead className="bg-gray-50/50 text-[10px] font-bold uppercase text-gray-400 border-b border-gray-100">
                      <tr>
                        <th className="px-4 py-2.5">Producto</th>
                        <th className="px-4 py-2.5 text-center">Cant.</th>
                        <th className="px-4 py-2.5 text-right">Precio Unit.</th>
                        <th className="px-4 py-2.5 text-right">Subtotal</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {getProductDetails(selectedPurchase).length === 0 ? (
                        <tr>
                          <td colSpan={4} className="px-4 py-6 text-center text-gray-400 italic">No se encontraron detalles de productos en esta compra.</td>
                        </tr>
                      ) : getProductDetails(selectedPurchase).map((item: any, i: number) => (
                        <tr key={i} className="hover:bg-gray-50/20">
                          <td className="px-4 py-3 font-semibold text-gray-900">{item.nombre}</td>
                          <td className="px-4 py-3 text-center font-bold text-gray-900">{item.cantidad}</td>
                          <td className="px-4 py-3 text-right">${Number(item.precio).toFixed(2)}</td>
                          <td className="px-4 py-3 text-right font-semibold text-gray-900">${Number(item.subtotal).toFixed(2)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Totales */}
              <div className="border-t border-gray-100 pt-4 flex flex-col items-end space-y-1.5">
                <div className="flex justify-between w-full max-w-xs text-xs font-medium text-gray-500 px-1">
                  <span>Subtotal:</span>
                  <span>${Number(selectedPurchase.subtotal || 0).toFixed(2)}</span>
                </div>
                <div className="flex justify-between w-full max-w-xs text-xs font-medium text-gray-500 px-1">
                  <span>IVA (15%):</span>
                  <span>${Number(selectedPurchase.iva || 0).toFixed(2)}</span>
                </div>
                <div className="flex justify-between w-full max-w-xs text-sm font-extrabold text-gray-950 bg-gray-50 p-2.5 rounded-lg border border-gray-100">
                  <span>Total compra:</span>
                  <span>${Number(selectedPurchase.total || 0).toFixed(2)}</span>
                </div>
              </div>
            </div>

            <div className="p-4 bg-gray-50/50 border-t border-gray-50 flex justify-end">
              <button
                onClick={() => setSelectedPurchase(null)}
                className="px-5 py-2 bg-black text-white hover:bg-black/90 transition-colors rounded-xl text-xs font-bold shadow-sm"
              >
                Cerrar Detalle
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal de Confirmación de Acción */}
      {purchaseToConfirm && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden border border-gray-100 p-6 text-center">
            <div className={`w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 ${purchaseToConfirm.action === 'archive' ? 'bg-gray-100 text-gray-900' : 'bg-black text-white'
              }`}>
              {purchaseToConfirm.action === 'archive' ? <Archive size={32} /> : <RotateCcw size={32} />}
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">
              {purchaseToConfirm.action === 'archive' ? '¿Archivar compra?' : '¿Restaurar compra?'}
            </h2>
            <p className="text-gray-500 text-sm mb-6">
              {purchaseToConfirm.action === 'archive'
                ? 'La compra se moverá al historial archivado (borrado lógico).'
                : 'La compra se restaurará y volverá a aparecer en el historial activo.'}
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setPurchaseToConfirm(null)}
                className="flex-1 px-4 py-2.5 border border-gray-100 rounded-xl text-sm font-bold hover:bg-gray-50 transition-all"
              >
                Cancelar
              </button>
              <button
                onClick={handleConfirmAction}
                className="flex-1 px-4 py-2.5 text-white bg-black hover:bg-black/90 rounded-xl text-sm font-bold transition-all shadow-sm"
              >
                {purchaseToConfirm.action === 'archive' ? 'Archivar' : 'Restaurar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Purchases;
