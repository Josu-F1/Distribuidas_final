import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'products_page.dart';
import 'purchases_page.dart';
import 'login_page.dart';
import '../services/auth_provider.dart';
import '../services/cart_provider.dart';
import '../services/api_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return const ProductsPage();
      case 1:
        return const PurchasesPage();
      case 2:
        return const ProfilePage();
      default:
        return const ProductsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      body: _getBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.black,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.grey[100]!,
              color: Colors.black,
              tabs: [
                const GButton(
                  icon: Icons.grid_view_rounded,
                  text: 'Productos',
                ),
                const GButton(
                  icon: Icons.shopping_bag_outlined,
                  text: 'Mis Compras',
                ),
                const GButton(
                  icon: Icons.person_outline,
                  text: 'Mi Perfil',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0 && cart.items.isNotEmpty
          ? Badge(
              label: Text('${cart.items.fold(0, (sum, item) => sum + item.quantity)}'),
              child: FloatingActionButton(
                onPressed: () => _showCartModal(context),
                backgroundColor: Colors.black,
                child: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
            )
          : null,
    );
  }

  void _showCartModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CartModal(
        onPurchaseSuccess: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              auth.nombreCompleto,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(auth.email ?? 'test@test.com', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Mis Datos',
              subtitle: 'Nombre: ${auth.nombreCompleto}\nID: ${auth.uid ?? "N/A"}',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Historial',
              subtitle: 'Toca la pestaña de compras para ver detalles',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  auth.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.red.shade100),
                ),
                child: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartModal extends StatelessWidget {
  final VoidCallback onPurchaseSuccess;
  const CartModal({super.key, required this.onPurchaseSuccess});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Tu Carrito', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('El carrito está vacío'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        title: Text(item.product.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.quantity} x \$${item.product.precio.toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => cart.removeFromCart(item.product.id),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total (inc. IVA):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('\$${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty ? null : () => _processPurchase(context, cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirmar Compra', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _processPurchase(BuildContext context, CartProvider cart) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      // Mapear items del carrito al formato que espera el backend
      final detalles = cart.items.map((item) => {
        'producto_id': item.product.id,
        'cantidad': item.quantity,
        'precio_unitario': item.product.precio
      }).toList();

      String? compraId = await apiService.createPurchase(detalles, auth.headers);

      if (context.mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        
        if (compraId != null) {
          // Intentar generar factura en el servicio de facturación pública (Render)
          await apiService.generateInvoice(
            compraId, 
            auth.email ?? "test@test.com", 
            auth.nombreCompleto,
            cart.items
          );

          cart.clearCart();
          Navigator.pop(context); // Cerrar el modal del carrito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Compra realizada con éxito!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Opcional: Cambiar a la pestaña de compras
          onPurchaseSuccess();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al procesar la compra. Intente nuevamente.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
