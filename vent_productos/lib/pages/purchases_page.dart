import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class PurchasesData {
  final List<Purchase> filtered;
  final int totalCount;
  final List<String> userIdsInDb;
  final String rawSample;
  PurchasesData({
    required this.filtered, 
    required this.totalCount, 
    required this.userIdsInDb,
    required this.rawSample,
  });
}

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  final ApiService _apiService = ApiService();
  late Future<PurchasesData> _purchasesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 4;
  static const Color brandRed = Color(0xFFFF0050);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
          _currentPage = 1;
        });
      }
    });
    _refreshPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshPurchases() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _purchasesFuture = Future.wait([
        _apiService.getPurchases(auth.headers),
        _apiService.getProducts(auth.headers),
      ]).then((results) {
        final purchases = results[0] as List<Purchase>;
        final products = results[1] as List<Product>;

        // 1. Filtrar compras para que solo aparezcan las de este usuario
        final userPurchases = purchases.where((p) {
          final pEmail = p.usuarioEmail.trim().toLowerCase();
          final authEmail = auth.email?.trim().toLowerCase() ?? '';
          return pEmail == authEmail && authEmail.isNotEmpty;
        }).toList();

        // 2. Resolver detalles y nombres de productos para cada compra
        for (var purchase in userPurchases) {
          if (purchase.detalles.isEmpty) {
            final resolvedDetails = _resolveDetails(purchase, products);
            purchase.detalles.addAll(resolvedDetails);
          } else {
            for (var i = 0; i < purchase.detalles.length; i++) {
              final detail = purchase.detalles[i];
              if (detail.productoNombre.trim().isEmpty) {
                final matchedProd = products.firstWhere(
                  (p) => p.id == detail.productoId,
                  orElse: () => Product(
                    id: detail.productoId,
                    nombre: 'Producto #${detail.productoId.substring(0, detail.productoId.length >= 5 ? 5 : detail.productoId.length)}',
                    descripcion: '',
                    precio: detail.precioUnitario,
                    stock: 0,
                    categoria: '',
                    activo: false,
                    eliminado: false,
                    imagenUrl: '',
                  ),
                );
                purchase.detalles[i] = PurchaseDetail(
                  productoId: detail.productoId,
                  productoNombre: matchedProd.nombre,
                  cantidad: detail.cantidad,
                  precioUnitario: detail.precioUnitario,
                );
              }
            }
          }
        }

        String rawSample = 'No hay compras en la base de datos.';
        if (purchases.isNotEmpty) {
          try {
            rawSample = const JsonEncoder.withIndent('  ').convert(purchases.first.rawJson);
          } catch (e) {
            rawSample = 'Error formateando JSON: $e\nDatos: ${purchases.first.rawJson}';
          }
        }

        return PurchasesData(
          filtered: userPurchases,
          totalCount: purchases.length,
          userIdsInDb: purchases.map((p) {
            final safeId = p.id.substring(0, p.id.length >= 8 ? 8 : p.id.length).toUpperCase();
            return '$safeId: "${p.usuarioEmail}"';
          }).toList(),
          rawSample: rawSample,
        );
      });
    });
  }

  List<PurchaseDetail> _resolveDetails(Purchase purchase, List<Product> products) {
    final subtotal = purchase.subtotal > 0 ? purchase.subtotal : purchase.total;
    if (subtotal <= 0 || products.isEmpty) return [];

    // Ordenar productos por precio desc para el algoritmo
    final sortedProducts = List<Product>.from(products)
        .where((p) => p.precio > 0)
        .toList();
    sortedProducts.sort((a, b) => b.precio.compareTo(a.precio));

    double remaining = subtotal;
    List<PurchaseDetail> resolved = [];

    for (final prod in sortedProducts) {
      final price = prod.precio;
      if (remaining >= price) {
        final qty = (remaining / price).floor();
        if (qty > 0) {
          resolved.add(PurchaseDetail(
            productoId: prod.id,
            productoNombre: prod.nombre,
            cantidad: qty,
            precioUnitario: price,
          ));
          remaining = double.parse((remaining - qty * price).toStringAsFixed(2));
        }
      }
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mis Compras',
          style: TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: brandRed),
            onPressed: _refreshPurchases,
            tooltip: 'Actualizar Historial',
          )
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
      ),
      body: FutureBuilder<PurchasesData>(
        future: _purchasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: brandRed));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshPurchases,
                      style: ElevatedButton.styleFrom(backgroundColor: brandRed),
                      child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: brandRed.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: brandRed,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aún no hay compras',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tus pedidos aparecerán aquí\nuna vez que los realices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _refreshPurchases,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: brandRed,
                      elevation: 0,
                      side: BorderSide(color: brandRed.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                ],
              ),
            );
          }

          final purchases = snapshot.data!.filtered;

          // 1. Filtrar las compras
          final filteredPurchases = purchases.where((purchase) {
            final query = _searchQuery.toLowerCase().trim();
            if (query.isEmpty) return true;

            final safeId = purchase.id.substring(0, purchase.id.length >= 8 ? 8 : purchase.id.length).toUpperCase();
            final matchInvoiceId = 'factura #$safeId'.toLowerCase().contains(query) ||
                purchase.id.toLowerCase().contains(query);
            final matchProduct = purchase.detalles.any((detail) =>
                detail.productoNombre.toLowerCase().contains(query));
            return matchInvoiceId || matchProduct;
          }).toList();

          // 2. Paginación
          final totalItems = filteredPurchases.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();
          int currentPage = _currentPage;
          if (currentPage > totalPages && totalPages > 0) {
            currentPage = totalPages;
          }
          final startIndex = (currentPage - 1) * _itemsPerPage;
          final endIndex = startIndex + _itemsPerPage;
          final paginatedPurchases = filteredPurchases.sublist(
            startIndex,
            endIndex > totalItems ? totalItems : endIndex,
          );

          return Column(
            children: [
              // Buscador de compras
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nº de factura o producto...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: brandRed, width: 1.2),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: filteredPurchases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: brandRed.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: brandRed,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Aún no hay compras',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tus pedidos aparecerán aquí\nuna vez que los realices.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        itemCount: paginatedPurchases.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final purchase = paginatedPurchases[index];
                          
                          // Formatear Fecha de Compra
                          String formattedDate;
                          final parsedDate = DateTime.tryParse(purchase.fechaCompra);
                          if (parsedDate != null) {
                            formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
                          } else {
                            formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
                          }

                          final isPagada = purchase.estado.toUpperCase() == 'PAGADA' ||
                                           purchase.estado.toUpperCase() == 'COMPLETADO' ||
                                           purchase.estado.toUpperCase() == 'FACTURADA';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    width: 4,
                                    color: isPagada ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: brandRed.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.receipt_outlined,
                                              color: brandRed,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Factura #${purchase.id.substring(0, purchase.id.length >= 8 ? 8 : purchase.id.length).toUpperCase()}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${purchase.total.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPagada ? Colors.green[50] : Colors.orange[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isPagada ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            purchase.estado.toUpperCase(),
                                            style: TextStyle(
                                              color: isPagada ? Colors.green[700] : Colors.orange[800],
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                children: [
                                  const Divider(color: Color(0xFFF3F4F6), height: 24),
                                  _buildTimeline(purchase.estado),
                                  // Encabezado de la lista de productos
                                  const Row(
                                    children: [
                                      Icon(Icons.list_alt_rounded, size: 16, color: Colors.black54),
                                      SizedBox(width: 8),
                                      Text(
                                        'Detalle del Pedido',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Lista de productos comprados
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: purchase.detalles.length,
                                    itemBuilder: (context, i) {
                                      final detail = purchase.detalles[i];
                                      final subtotalProducto = detail.cantidad * detail.precioUnitario;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    detail.productoNombre.isNotEmpty 
                                                        ? detail.productoNombre 
                                                        : 'Producto #${detail.productoId.substring(0, detail.productoId.length >= 5 ? 5 : detail.productoId.length)}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${detail.cantidad} x \$${detail.precioUnitario.toStringAsFixed(2)}',
                                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '\$${subtotalProducto.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 16),
                                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                                  const SizedBox(height: 16),

                                  // Sección de Direcciones (Origen y Destino)
                                  if (purchase.direccionOrigen != null || purchase.direccionDestino != null) ...[
                                    const Row(
                                      children: [
                                        Icon(Icons.local_shipping_outlined, size: 16, color: brandRed),
                                        SizedBox(width: 8),
                                        Text(
                                          'Información de Envío / Entrega',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFF3F4F6)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (purchase.metodoEntrega != null) ...[
                                            Row(
                                              children: [
                                                Icon(
                                                  purchase.metodoEntrega == 'PICKUP'
                                                      ? Icons.storefront_outlined
                                                      : Icons.delivery_dining_outlined,
                                                  size: 16,
                                                  color: brandRed,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Método de Entrega: ${purchase.metodoEntrega == 'PICKUP' ? 'Retiro en Local' : 'Envío / Delivery'}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: brandRed,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 16, color: Color(0xFFF3F4F6)),
                                          ],
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.store_mall_directory_outlined, size: 16, color: Colors.blueGrey),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('Origen / Despacho:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      purchase.direccionOrigen ?? 'No especificado',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.only(left: 7.0, top: 4.0, bottom: 4.0),
                                            child: SizedBox(
                                              height: 16,
                                              child: VerticalDivider(width: 2, color: Colors.grey, thickness: 1),
                                            ),
                                          ),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 16, color: brandRed),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('Destino / Entrega:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      purchase.direccionDestino ?? 'No especificado',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                                    const SizedBox(height: 16),
                                  ],

                                  // Cuadro de Resumen de Totales
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFF3F4F6)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Subtotal:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                            Text('\$${purchase.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('IVA (15%):', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                            Text('\$${purchase.iva.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Divider(color: Color(0xFFE5E7EB), height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Total Compra:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                            Text(
                                              '\$${purchase.total.toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showInvoiceDialog(context, purchase),
                                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                                      label: const Text('Generar/Ver Factura XML'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: brandRed,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ),
                          );
                        },
                      ),
              ),

              // Controles de Paginación
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                        icon: const Icon(Icons.chevron_left, size: 18),
                        label: const Text('Anterior'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Text(
                        'Pág. $currentPage de $totalPages',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      ),
                      ElevatedButton.icon(
                        onPressed: currentPage < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                        label: const Text('Siguiente'),
                        icon: const Icon(Icons.chevron_right, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context, Purchase purchase) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool forceConsumidorFinal = purchase.usuarioNombres == 'Consumidor Final';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final emailParam = forceConsumidorFinal ? "consumidorfinal@techstore.com" : (auth.email ?? "test@test.com");
            final nameParam = forceConsumidorFinal ? "Consumidor Final" : auth.nombreCompleto;
            final phoneParam = forceConsumidorFinal ? "9999999999" : (auth.telefono ?? "0999999999");
            final cedulaParam = forceConsumidorFinal ? "9999999999" : (auth.cedula ?? "1899999999");

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: Colors.blue.shade900),
                      const SizedBox(width: 8),
                      const Text('Factura Digital', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: forceConsumidorFinal,
                          activeColor: brandRed,
                          onChanged: (val) {
                            setDialogState(() {
                              forceConsumidorFinal = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Generar como Consumidor Final',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 10),
                    Expanded(
                      child: FutureBuilder<String?>(
                        future: _apiService.generateInvoiceFromPurchase(
                          purchase, 
                          emailParam, 
                          nameParam,
                          phoneParam,
                          cedulaParam,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: brandRed));
                          }
                          
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                            final errorMsg = snapshot.hasError ? snapshot.error.toString() : '';
                            final isFetchError = errorMsg.contains('Failed to fetch') || errorMsg.contains('ClientException');
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Error al contactar el servicio de facturación',
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isFetchError
                                          ? 'El servidor en Render se encuentra en reposo (Free Tier). Está despertando (toma hasta 50 segundos la primera vez). Por favor, intenta de nuevo.'
                                          : 'Detalle: ${snapshot.error ?? "Respuesta vacía o error de red"}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showInvoiceDialog(context, purchase);
                                      },
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Reintentar ahora'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: brandRed,
                                        foregroundColor: Colors.white,
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final xmlContent = snapshot.data!;

                          return DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                const TabBar(
                                  labelColor: brandRed,
                                  unselectedLabelColor: Colors.grey,
                                  indicatorColor: brandRed,
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                  tabs: [
                                    Tab(icon: Icon(Icons.picture_as_pdf_rounded, size: 20), text: 'Vista Previa'),
                                    Tab(icon: Icon(Icons.code_rounded, size: 20), text: 'XML Original'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      _buildVisualInvoice(context, purchase, emailParam, nameParam, phoneParam, cedulaParam),
                                      _buildXmlCodeView(context, xmlContent, purchase),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeline(String status) {
    final String normalized = status.toUpperCase().trim();
    int currentStep = 1; // Default: PENDIENTE/CREADO
    if (normalized == 'PAGADA' || normalized == 'COMPLETADO' || normalized == 'FACTURADA') {
      currentStep = 2;
    }
    if (normalized == 'FACTURADA' || normalized == 'COMPLETADO') {
      currentStep = 3;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADO DEL PEDIDO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimelineStep(1, 'Creado', currentStep >= 1),
              _buildTimelineConnector(currentStep >= 2),
              _buildTimelineStep(2, 'Pagado', currentStep >= 2),
              _buildTimelineConnector(currentStep >= 3),
              _buildTimelineStep(3, 'Facturado', currentStep >= 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(int stepNum, String title, bool isDone) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF0F172A) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
              width: 2,
            ),
            boxShadow: isDone
                ? const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '$stepNum',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool isDone) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 18, left: 8, right: 8),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildDottedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              color: index % 2 == 0 ? Colors.transparent : const Color(0xFFE2E8F0),
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualInvoice(BuildContext context, Purchase purchase, String email, String clientName, String phone, String cedula) {
    final cleanDate = purchase.fechaCompra.isNotEmpty 
        ? purchase.fechaCompra.split('T')[0] 
        : DateTime.now().toIso8601String().split('T')[0];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          )
        ]
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la factura
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'P',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TECHSTORE 360',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2, color: Color(0xFF0F172A)),
                  ),
                  const Text(
                    'FACTURACIÓN ELECTRÓNICA AUTORIZADA',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
            _buildDottedDivider(),
            
            // Datos del documento
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nº FACTURA', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      'F001-${purchase.id.substring(0, purchase.id.length >= 8 ? 8 : purchase.id.length).toUpperCase()}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('FECHA EMISIÓN', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      cleanDate, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ],
            ),
            _buildDottedDivider(),

            // Información del Cliente
            const Text('RECEPTOR / CLIENTE', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInvoiceField('Cliente:', clientName),
                  const SizedBox(height: 4),
                  _buildInvoiceField('Email:', email),
                  const SizedBox(height: 4),
                  _buildInvoiceField('Teléfono:', phone),
                  const SizedBox(height: 4),
                  _buildInvoiceField('RUC/Cédula:', cedula),
                  const SizedBox(height: 4),
                  _buildInvoiceField('Despacho:', purchase.direccionOrigen ?? 'TechStore Matriz'),
                  const SizedBox(height: 4),
                  _buildInvoiceField('Entrega:', purchase.direccionDestino ?? 'Ecuador'),
                  if (purchase.metodoEntrega != null) ...[
                    const SizedBox(height: 4),
                    _buildInvoiceField('Método Envío:', purchase.metodoEntrega == 'PICKUP' ? 'Retiro en Local' : 'Envío / Delivery'),
                  ],
                ],
              ),
            ),
            _buildDottedDivider(),

            // Detalles de la compra
            const Text('DETALLE DE ADQUISICIÓN', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: purchase.detalles.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0), height: 16),
              itemBuilder: (context, i) {
                final detail = purchase.detalles[i];
                final subtotal = detail.cantidad * detail.precioUnitario;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(detail.productoNombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('${detail.cantidad} x \$${detail.precioUnitario.toStringAsFixed(2)}', 
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('\$${subtotal.toStringAsFixed(2)}', 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                );
              },
            ),
            _buildDottedDivider(),

            // Totales de la Factura
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal Neto:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                Text('\$${purchase.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IVA Gravado (15%):', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                Text('\$${purchase.iva.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL PAGADO:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46))),
                  Text('\$${purchase.total.toStringAsFixed(2)}', 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF065F46))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '¡Gracias por preferir TechStore 360!',
                style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildXmlCodeView(BuildContext context, String xmlContent, Purchase purchase) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: SingleChildScrollView(
              child: Text(
                xmlContent,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: xmlContent));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('XML copiado al portapapeles'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copiar XML'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandRed,
                  side: const BorderSide(color: brandRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _downloadXmlFile(context, xmlContent, purchase),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Descargar XML'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _downloadXmlFile(BuildContext context, String xmlContent, Purchase purchase) {
    if (kIsWeb) {
      try {
        final escapedXml = xmlContent.replaceAll("'", "\\'").replaceAll("\n", "\\n").replaceAll("\r", "");
        final safeId = purchase.id.substring(0, purchase.id.length >= 8 ? 8 : purchase.id.length).toUpperCase();
        js.context.callMethod('eval', [
          '''
          var element = document.createElement('a');
          element.setAttribute('href', 'data:text/xml;charset=utf-8,' + encodeURIComponent('$escapedXml'));
          element.setAttribute('download', 'Factura-$safeId.xml');
          element.style.display = 'none';
          document.body.appendChild(element);
          element.click();
          document.body.removeChild(element);
          '''
        ]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('XML descargado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        print('Error al descargar en web: $e');
      }
    } else {
      // En móvil, copiamos al portapapeles y avisamos
      Clipboard.setData(ClipboardData(text: xmlContent));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('XML copiado al portapapeles (Opción de guardado local no disponible en móvil)'),
          backgroundColor: brandRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
