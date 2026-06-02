import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshPurchases();
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
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
            return const Center(child: CircularProgressIndicator(color: Colors.black));
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.filtered.isEmpty) {
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes compras registradas',
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DEBUG INFO (Filtro de Usuario):',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        const Text('• Tus IDs locales:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                        Text('  - Database ID (Local ID): "${auth.databaseId}"', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                        Text('  - Firebase UID: "${auth.firebaseUid}"', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                        Text('  - Correo: "${auth.email}"', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                        const SizedBox(height: 12),
                        Text('• Total compras encontradas: ${data.totalCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                        const SizedBox(height: 6),
                        const Text('• Compras en BD (FACTURA: "USUARIO_EMAIL"):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                        const SizedBox(height: 4),
                        if (data.userIdsInDb.isEmpty)
                          const Text('  - Ninguna compra registrada en la base de datos.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic))
                        else
                          ...data.userIdsInDb.map((item) => Text('  - $item', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87))),
                        const SizedBox(height: 12),
                        const Text('• Ejemplo de Compra Cruda (Raw Sample):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              data.rawSample,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }

          final purchases = snapshot.data!.filtered;

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: purchases.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              
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
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Factura #${purchase.id.substring(0, purchase.id.length >= 8 ? 8 : purchase.id.length).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${purchase.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPagada ? Colors.green[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                purchase.estado.toUpperCase(),
                                style: TextStyle(
                                  color: isPagada ? Colors.green[700] : Colors.orange[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      const Divider(color: Color(0xFFF3F4F6), height: 24),
                      
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
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context, Purchase purchase) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: Colors.black),
                  SizedBox(width: 8),
                  Text('Factura XML', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            height: MediaQuery.of(context).size.height * 0.55,
            child: FutureBuilder<String?>(
              future: _apiService.generateInvoiceFromPurchase(
                purchase, 
                auth.email ?? "test@test.com", 
                auth.nombreCompleto
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }
                
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text(
                      'Error al contactar con el servicio de facturación',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final xmlContent = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Factura generada exitosamente en Render.',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
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
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
