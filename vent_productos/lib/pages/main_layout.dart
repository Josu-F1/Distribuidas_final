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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _telefonoController;
  late TextEditingController _cedulaController;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nombresController = TextEditingController(text: auth.nombres ?? '');
    _apellidosController = TextEditingController(text: auth.apellidos ?? '');
    _telefonoController = TextEditingController(text: auth.telefono ?? '');
    _cedulaController = TextEditingController(text: auth.cedula ?? '');
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  String _getInitials(String? nombres, String? apellidos) {
    String initials = '';
    if (nombres != null && nombres.trim().isNotEmpty) {
      initials += nombres.trim()[0].toUpperCase();
    }
    if (apellidos != null && apellidos.trim().isNotEmpty) {
      initials += apellidos.trim()[0].toUpperCase();
    }
    return initials.isNotEmpty ? initials : 'U';
  }

  void _saveProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nombres = _nombresController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final telefono = _telefonoController.text.trim();
    final cedula = _cedulaController.text.trim();

    if (nombres.isEmpty || apellidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombres y apellidos son requeridos'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (nombres.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no puede tener más de 15 caracteres'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (apellidos.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El apellido no puede tener más de 15 caracteres'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (telefono.isNotEmpty) {
      if (!telefono.startsWith('09')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El teléfono debe comenzar con 09'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (telefono.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El teléfono debe tener exactamente 10 dígitos'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(telefono)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El teléfono solo debe contener números'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    if (cedula.isNotEmpty) {
      if (cedula.length != 10 && cedula.length != 13) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cédula debe tener 10 dígitos (o 13 para RUC)'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(cedula)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cédula solo debe contener números'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final apiService = ApiService();
      await apiService.updateUser(
        auth.databaseId ?? '',
        {
          'nombres': nombres,
          'apellidos': apellidos,
          'rol': 'CLIENTE',
          'telefono': telefono.isEmpty ? null : telefono,
          'cedula': cedula.isEmpty ? null : cedula,
          'cedula_ruc': cedula.isEmpty ? null : cedula,
          'estado': true,
        },
        auth.headers,
      );

      auth.updateUserInfo(
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono.isEmpty ? '' : telefono,
        cedula: cedula.isEmpty ? '' : cedula,
      );

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cambios: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final initials = _getInitials(auth.nombres, auth.apellidos);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabecera superior con degradado de diseño premium monocromo
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        Color(0xFF1F2937),
                        Color(0xFF374151),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mi Perfil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Cliente',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Avatar flotante
                Positioned(
                  bottom: -50,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.black,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 64),
            
            // Nombre y correo principal
            Text(
              auth.nombreCompleto,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              auth.email ?? 'correo@empresa.com',
              style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // Tarjetas de información y acciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('INFORMACIÓN DE LA CUENTA'),
                      if (!_isEditing)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _nombresController.text = auth.nombres ?? '';
                              _apellidosController.text = auth.apellidos ?? '';
                              _telefonoController.text = auth.telefono ?? '';
                              _cedulaController.text = auth.cedula ?? '';
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.black),
                          label: const Text(
                            'Editar',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isEditing) ...[
                    // Campos de edición
                    _buildEditableCard(
                      label: 'Nombres',
                      controller: _nombresController,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      label: 'Apellidos',
                      controller: _apellidosController,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      label: 'Teléfono',
                      controller: _telefonoController,
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      label: 'Cédula / RUC',
                      controller: _cedulaController,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    // Botones de acción de edición
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Guardar'),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Vista normal
                    _buildInfoCard(
                      icon: Icons.person_outline_rounded,
                      iconColor: Colors.black87,
                      title: 'Nombres Completos',
                      value: auth.nombreCompleto,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.alternate_email_rounded,
                      iconColor: Colors.black87,
                      title: 'Correo Electrónico',
                      value: auth.email ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.phone_android_rounded,
                      iconColor: Colors.black87,
                      title: 'Teléfono',
                      value: (auth.telefono != null && auth.telefono!.isNotEmpty) 
                          ? auth.telefono! 
                          : 'Sin teléfono registrado',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.badge_outlined,
                      iconColor: Colors.black87,
                      title: 'Cédula / RUC',
                      value: (auth.cedula != null && auth.cedula!.isNotEmpty) 
                          ? auth.cedula! 
                          : 'Sin documento registrado',
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('SESIÓN'),
                  const SizedBox(height: 12),
                  
                  // Botón de cerrar sesión premium
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        auth.logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isCode = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    fontFamily: isCode ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCard({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black87, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartModal extends StatefulWidget {
  final VoidCallback onPurchaseSuccess;
  const CartModal({super.key, required this.onPurchaseSuccess});

  @override
  State<CartModal> createState() => _CartModalState();
}

class _CartModalState extends State<CartModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _direccionOrigenController;
  late TextEditingController _direccionDestinoController;
  bool _isConsumidorFinal = false;
  String _metodoPago = 'EFECTIVO'; // EFECTIVO, TARJETA, PAYPAL

  @override
  void initState() {
    super.initState();
    _direccionOrigenController = TextEditingController(text: 'TechStore 360 - Matriz Quito');
    _direccionDestinoController = TextEditingController();
  }

  @override
  void dispose() {
    _direccionOrigenController.dispose();
    _direccionDestinoController.dispose();
    super.dispose();
  }

  Widget _buildPaymentMethodCard(String type, IconData icon, String label) {
    final isSelected = _metodoPago == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _metodoPago = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.black : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black87, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Form(
          key: _formKey,
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
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cart.items.length,
                              itemBuilder: (context, index) {
                                final item = cart.items[index];
                                final maxStock = item.product.stock;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFF3F4F6)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.nombre,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${item.product.precio.toStringAsFixed(2)} c/u',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Selector de cantidad
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.black54, size: 22),
                                            onPressed: () => cart.decrementQuantity(item.product.id),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add_circle_outline,
                                              color: item.quantity >= maxStock ? Colors.grey : Colors.black54,
                                              size: 22,
                                            ),
                                            onPressed: item.quantity >= maxStock
                                                ? null
                                                : () => cart.incrementQuantity(item.product.id),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      // Precio Total Item
                                      Text(
                                        '\$${(item.product.precio * item.quantity).toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Divider(color: Color(0xFFF3F4F6), height: 32),
                            // Formulario de Direcciones
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DATOS DE DESPACHO / ENVÍO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Dirección de Origen
                                  TextFormField(
                                    controller: _direccionOrigenController,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      labelText: 'Dirección de Origen (Despacho)',
                                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                      prefixIcon: const Icon(Icons.store_mall_directory_outlined, color: Colors.black54),
                                      filled: true,
                                      fillColor: const Color(0xFFF9FAFB),
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
                                        borderSide: const BorderSide(color: Colors.black, width: 1.2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'La dirección de origen es requerida';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Dirección de Destino con Botón de Mapa
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _direccionDestinoController,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            labelText: 'Dirección de Destino (Entrega)',
                                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                            prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black54),
                                            filled: true,
                                            fillColor: const Color(0xFFF9FAFB),
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
                                              borderSide: const BorderSide(color: Colors.black, width: 1.2),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Por favor ingresa la dirección de entrega';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => InteractiveMapWidget(
                                              initialAddress: _direccionDestinoController.text,
                                              onAddressSelected: (address) {
                                                setState(() {
                                                  _direccionDestinoController.text = address;
                                                });
                                              },
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.map_outlined),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          fixedSize: const Size(48, 48),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                                  const SizedBox(height: 16),
                                  // Switch Consumidor Final
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.person_pin_outlined, color: Colors.black54),
                                          SizedBox(width: 8),
                                          Text(
                                            'Facturar como Consumidor Final',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                      Switch(
                                        value: _isConsumidorFinal,
                                        activeColor: Colors.black,
                                        onChanged: (val) {
                                          setState(() {
                                            _isConsumidorFinal = val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                                  const SizedBox(height: 16),
                                  // Método de Pago
                                  const Text(
                                    'MÉTODO DE PAGO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildPaymentMethodCard('EFECTIVO', Icons.money_rounded, 'Efectivo'),
                                      const SizedBox(width: 8),
                                      _buildPaymentMethodCard('TARJETA', Icons.credit_card_rounded, 'Tarjeta'),
                                      const SizedBox(width: 8),
                                      _buildPaymentMethodCard('PAYPAL', Icons.paypal_rounded, 'PayPal'),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                        const Text('Subtotal:', style: TextStyle(fontSize: 14, color: Colors.black54)),
                        Text('\$${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('IVA (15%):', style: TextStyle(fontSize: 14, color: Colors.black54)),
                        Text('\$${cart.iva.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFE5E7EB), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total (inc. IVA):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('\$${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cart.items.isEmpty
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _processPaymentCheckout(context, cart);
                                }
                              },
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
        ),
      ),
    );
  }

  void _processPaymentCheckout(BuildContext context, CartProvider cart) {
    if (_metodoPago == 'PAYPAL') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PaypalCheckoutDialog(
          total: cart.total,
          onSuccess: () {
            _processPurchase(context, cart);
          },
        ),
      );
    } else {
      _processPurchase(context, cart);
    }
  }

  void _processPurchase(BuildContext context, CartProvider cart) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();
    final dirOrigen = _direccionOrigenController.text.trim();
    final dirDestino = _direccionDestinoController.text.trim();

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

      String? compraId = await apiService.createPurchase(
        detalles,
        dirOrigen,
        dirDestino,
        auth.headers,
      );

      if (context.mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        
        if (compraId != null) {
          // Intentar generar factura en el servicio de facturación pública (Render)
          await apiService.generateInvoice(
            compraId, 
            _isConsumidorFinal ? "consumidorfinal@techstore.com" : (auth.email ?? "test@test.com"), 
            _isConsumidorFinal ? "Consumidor Final" : auth.nombreCompleto,
            _isConsumidorFinal ? "9999999999" : (auth.telefono ?? "0999999999"),
            _isConsumidorFinal ? "9999999999" : (auth.cedula ?? "1899999999"),
            cart.items
          );

          if (!context.mounted) return;

          cart.clearCart();
          Navigator.pop(context); // Cerrar el modal del carrito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Compra realizada con éxito!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onPurchaseSuccess();
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

class InteractiveMapWidget extends StatefulWidget {
  final String initialAddress;
  final ValueChanged<String> onAddressSelected;

  const InteractiveMapWidget({
    super.key,
    required this.initialAddress,
    required this.onAddressSelected,
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  Offset _pinPosition = const Offset(150, 150);
  String _selectedAddress = "Av. de los Shyris y Av. Naciones Unidas, Parque La Carolina";

  final List<Map<String, dynamic>> _mockRegions = [
    {
      'rect': const Rect.fromLTWH(0, 0, 150, 120),
      'address': 'Av. 10 de Agosto y Cuero y Caicedo, Sector La Mariscal',
    },
    {
      'rect': const Rect.fromLTWH(0, 120, 150, 130),
      'address': 'Av. Amazonas y Av. Patria, Parque El Ejido',
    },
    {
      'rect': const Rect.fromLTWH(0, 250, 150, 150),
      'address': 'Av. Maldonado y Quimil, Villa Flora (Sur de Quito)',
    },
    {
      'rect': const Rect.fromLTWH(150, 0, 150, 120),
      'address': 'Av. de los Shyris y Av. Naciones Unidas, Parque La Carolina',
    },
    {
      'rect': const Rect.fromLTWH(150, 120, 150, 130),
      'address': 'Av. Eloy Alfaro y Av. 6 de Diciembre, Sector Bella Vista',
    },
    {
      'rect': const Rect.fromLTWH(150, 250, 150, 150),
      'address': 'Av. Simón Bolívar y Av. de los Granados, Sector El Cíclope',
    },
    {
      'rect': const Rect.fromLTWH(80, 80, 140, 140), // Centro
      'address': 'Av. Colón y Av. 12 de Octubre, Sector La Floresta',
    },
  ];

  void _updatePosition(Offset localPosition, Size size) {
    setState(() {
      _pinPosition = localPosition;
      
      // Encontrar región correspondiente a la posición relativa
      String foundAddress = 'Av. de los Shyris y Av. Naciones Unidas, Parque La Carolina';
      double relativeX = (localPosition.dx / size.width) * 300;
      double relativeY = (localPosition.dy / size.height) * 400;
      Offset relOffset = Offset(relativeX, relativeY);

      for (var region in _mockRegions) {
        if ((region['rect'] as Rect).contains(relOffset)) {
          foundAddress = region['address'];
        }
      }
      _selectedAddress = foundAddress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map_outlined, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Selector de Dirección',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Toca en el mapa interactivo para marcar el punto de entrega de tu pedido.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            // El mapa interactivo
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  color: const Color(0xFFF3F4F6),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapDown: (details) => _updatePosition(details.localPosition, size),
                        onPanUpdate: (details) => _updatePosition(details.localPosition, size),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: MapPainter(pinPosition: _pinPosition),
                              ),
                            ),
                            Positioned(
                              left: _pinPosition.dx - 20,
                              top: _pinPosition.dy - 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Dirección Seleccionada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dirección Detectada:', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          _selectedAddress,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  widget.onAddressSelected(_selectedAddress);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Confirmar Dirección',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final Offset pinPosition;
  MapPainter({required this.pinPosition});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dibujar fondo (simulando un área de ciudad con zonas verdes y agua)
    final backgroundPaint = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // 2. Dibujar zonas verdes (Parques como La Carolina, El Ejido)
    final parkPaint = Paint()..color = const Color(0xFFD1FAE5);
    // Carolina Park (arriba a la derecha)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.55, size.height * 0.05, size.width * 0.35, size.height * 0.25), const Radius.circular(10)), parkPaint);
    // El Ejido Park (centro izquierda)
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.45), size.width * 0.15, parkPaint);
    // Parque Metropolitano (abajo a la derecha)
    canvas.drawOval(Rect.fromLTWH(size.width * 0.6, size.height * 0.6, size.width * 0.3, size.height * 0.35), parkPaint);

    // 3. Dibujar Río (Machángara o similar cruzando el mapa vectorialmente)
    final riverPaint = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final riverPath = Path();
    riverPath.moveTo(size.width * 0.05, size.height * 0.95);
    riverPath.quadraticBezierTo(size.width * 0.2, size.height * 0.7, size.width * 0.1, size.height * 0.5);
    riverPath.quadraticBezierTo(size.width * 0.0, size.height * 0.3, size.width * 0.3, size.height * 0.25);
    riverPath.quadraticBezierTo(size.width * 0.6, size.height * 0.2, size.width * 0.95, size.height * 0.05);
    canvas.drawPath(riverPath, riverPaint);

    // 4. Dibujar calles principales (Cuadrícula urbana simplificada)
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    // Calles Verticales (Avenidas principales)
    // Av. 10 de Agosto / Amazonas (Izquierda)
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.2, size.height), roadPaint);
    // Av. de los Shyris / 6 de Diciembre (Derecha)
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), roadPaint);
    // Av. Simón Bolívar (Extremo Derecho)
    canvas.drawLine(Offset(size.width * 0.9, 0), Offset(size.width * 0.9, size.height), roadPaint);

    // Calles Horizontales
    // Av. Naciones Unidas (Arriba)
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.2), roadPaint);
    // Av. Colón / Eloy Alfaro (Centro)
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), roadPaint);
    // Av. Patria / Orellana (Abajo)
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.8), roadPaint);

    // 5. Dibujar etiquetas de calles (Texto pequeño y premium)
    const textStyle = TextStyle(color: Colors.black38, fontSize: 8, fontWeight: FontWeight.bold);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(text: 'AV. AMAZONAS', style: textStyle);
    textPainter.layout();
    canvas.save();
    canvas.translate(size.width * 0.23, size.height * 0.1);
    canvas.rotate(1.57); // Rotar 90 grados
    textPainter.paint(canvas, const Offset(0, 0));
    canvas.restore();

    textPainter.text = const TextSpan(text: 'AV. NACIONES UNIDAS', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.35, size.height * 0.22));

    textPainter.text = const TextSpan(text: 'AV. COLÓN', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.35, size.height * 0.52));

    // 6. Efecto de círculo/ondas pulsante en el pin
    final pulsePaint = Paint()
      ..color = Colors.red.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinPosition, 25, pulsePaint);
    canvas.drawCircle(pinPosition, 12, Paint()..color = Colors.red.withOpacity(0.35));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PaypalCheckoutDialog extends StatefulWidget {
  final double total;
  final VoidCallback onSuccess;

  const PaypalCheckoutDialog({
    super.key,
    required this.total,
    required this.onSuccess,
  });

  @override
  State<PaypalCheckoutDialog> createState() => _PaypalCheckoutDialogState();
}

class _PaypalCheckoutDialogState extends State<PaypalCheckoutDialog> {
  int _step = 1; // 1: Login, 2: Loading, 3: Success
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startPaymentProcess() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _step = 2;
    });

    // Simular el procesamiento del pago en PayPal
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _step = 3;
        });
        
        // Simular éxito y proceder
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context); // Cerrar PayPal Dialog
            widget.onSuccess();    // Ejecutar compra
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF003087), // Azul Oficial PayPal
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 1:
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo de PayPal (Mock)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.paypal_rounded,
                      color: Color(0xFF003087),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PayPal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Pagar \$${widget.total.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Email
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu correo';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _startPaymentProcess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC439), // Amarillo PayPal
                    foregroundColor: const Color(0xFF003087),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Iniciar sesión para pagar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );
      case 2:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Procesando pago seguro en PayPal...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
          ],
        );
      case 3:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            Icon(Icons.check_circle_rounded, color: Color(0xFFFFC439), size: 60),
            SizedBox(height: 20),
            Text(
              '¡Pago Aprobado con Éxito!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Redirigiendo...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            SizedBox(height: 20),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
