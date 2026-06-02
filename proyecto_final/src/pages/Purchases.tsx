import React, { useEffect, useState } from 'react';
import { getPurchases } from '../services/api';
import { Purchase } from '../types';
import { ShoppingCart, Calendar, CreditCard, CheckCircle, Clock } from 'lucide-react';

const Purchases: React.FC = () => {
  const [purchases, setPurchases] = useState<Purchase[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getPurchases()
      .then(data => setPurchases(data))
      .catch(err => console.error(err))
      .finally(() => setLoading(false));
  }, []);

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
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm text-green-600">
          <div className="flex justify-between items-start mb-4">
            <span className="text-sm font-medium text-gray-400">Pagadas</span>
            <div className="bg-green-50 p-2 rounded-lg">
              <CheckCircle size={18} />
            </div>
          </div>
          <div className="text-2xl font-bold">
            {purchases.filter(p => p.estado === 'PAGADA').length}
          </div>
          <div className="text-xs text-green-500 mt-1">Éxito en cobros</div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50/50 text-gray-400 text-[10px] font-bold uppercase tracking-wider border-b border-gray-50">
                <th className="px-6 py-3">ID Compra</th>
                <th className="px-6 py-3">Usuario ID</th>
                <th className="px-6 py-3">Fecha</th>
                <th className="px-6 py-3">Total</th>
                <th className="px-6 py-3">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 text-sm text-gray-600">
              {loading ? (
                <tr>
                   <td colSpan={5} className="px-6 py-12 text-center text-gray-400 italic">Cargando historial de compras...</td>
                </tr>
              ) : purchases.map(purchase => (
                <tr key={purchase.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="px-6 py-4 font-mono text-xs">#INV-{purchase.id.substring(0, 8)}</td>
                  <td className="px-6 py-4 font-medium text-gray-900">{purchase.usuario_id}</td>
                  <td className="px-6 py-4 flex items-center gap-2">
                    <Calendar size={14} className="text-gray-300" />
                    {new Date(purchase.fecha_compra).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 font-bold text-gray-900">${purchase.total}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase flex items-center gap-1 w-fit ${
                      purchase.estado === 'PAGADA' ? 'bg-green-50 text-green-600 border border-green-100' : 'bg-yellow-50 text-yellow-600 border border-yellow-100'
                    }`}>
                      {purchase.estado === 'PAGADA' ? <CheckCircle size={10} /> : <Clock size={10} />}
                      {purchase.estado}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Purchases;
