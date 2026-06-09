import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  double _cartX = -1;
  double _cartY = -1;

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
    final size = MediaQuery.of(context).size;

    // Initialize cart button coordinates at bottom right if not set yet
    if (_cartX == -1 && _cartY == -1) {
      _cartX = size.width - 76;
      _cartY = size.height - 160;
    }

    return Scaffold(
      body: Stack(
        children: [
          _getBody(),
          if (_selectedIndex == 0 && cart.items.isNotEmpty)
            Positioned(
              left: _cartX,
              top: _cartY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _cartX = (_cartX + details.delta.dx).clamp(16.0, size.width - 76.0);
                    _cartY = (_cartY + details.delta.dy).clamp(16.0, size.height - 130.0);
                  });
                },
                child: Badge(
                  label: Text('${cart.items.fold(0, (sum, item) => sum + item.quantity)}'),
                  child: FloatingActionButton(
                    onPressed: () => _showCartModal(context),
                    backgroundColor: const Color(0xFFFF0050),
                    child: const Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
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
              activeColor: const Color(0xFFFF0050),
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: const Color(0x0DFF0050),
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

  bool _isValidEcuadorianCedula(String cedula) {
    if (cedula.length != 10) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(cedula)) return false;

    int provincia = int.parse(cedula.substring(0, 2));
    if ((provincia < 1 || provincia > 24) && provincia != 30) {
      return false;
    }

    int tercerDigito = int.parse(cedula[2]);
    if (tercerDigito >= 6) {
      return false;
    }

    int suma = 0;
    List<int> coeficientes = [2, 1, 2, 1, 2, 1, 2, 1, 2];
    for (int i = 0; i < 9; i++) {
      int valor = int.parse(cedula[i]) * coeficientes[i];
      if (valor >= 10) {
        valor -= 9;
      }
      suma += valor;
    }

    int digitoVerificador = int.parse(cedula[9]);
    int residuo = suma % 10;
    int resultado = residuo == 0 ? 0 : 10 - residuo;

    return resultado == digitoVerificador;
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
          content: Text('⚠️ Nombres y apellidos son requeridos'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (nombres.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ El nombre no puede exceder los 30 caracteres'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(nombres)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Los nombres solo deben contener letras'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (apellidos.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ El apellido no puede exceder los 30 caracteres'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(apellidos)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Los apellidos solo deben contener letras'),
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
            content: Text('⚠️ El teléfono debe comenzar con 09'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (telefono.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ El teléfono debe tener exactamente 10 dígitos'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(telefono)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ El teléfono solo debe contener números'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    if (cedula.isNotEmpty) {
      if (!_isValidEcuadorianCedula(cedula)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Cédula ecuatoriana inválida (debe tener 10 dígitos válidos)'),
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
                        Color(0xFFFF0050),
                        Color(0xFFE60048),
                        Color(0xFFCC0040),
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
                      backgroundColor: const Color(0xFFFF0050),
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
                          icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFFFF0050)),
                          label: const Text(
                            'Editar',
                            style: TextStyle(
                              color: Color(0xFFFF0050),
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
                      maxLength: 30,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      label: 'Apellidos',
                      controller: _apellidosController,
                      icon: Icons.person_outline_rounded,
                      maxLength: 30,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      label: 'Teléfono',
                      controller: _telefonoController,
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      label: 'Cédula / RUC',
                      controller: _cedulaController,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
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
                            backgroundColor: const Color(0xFFFF0050),
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
                      iconColor: const Color(0xFFFF0050),
                      title: 'Nombres Completos',
                      value: auth.nombreCompleto,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.alternate_email_rounded,
                      iconColor: const Color(0xFFFF0050),
                      title: 'Correo Electrónico',
                      value: auth.email ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFFFF0050),
                      title: 'Teléfono',
                      value: (auth.telefono != null && auth.telefono!.isNotEmpty) 
                          ? auth.telefono! 
                          : 'Sin teléfono registrado',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xFFFF0050),
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
                        backgroundColor: const Color(0xFFFF0050),
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
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
                  inputFormatters: inputFormatters,
                  maxLength: maxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    counterText: '',
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
  bool _isLoading = false;

  static const Color brandRed = Color(0xFFFF0050);
  String _metodoEntrega = 'DELIVERY'; // DELIVERY, PICKUP
  String? _tiempoEstimado;

  @override
  void initState() {
    super.initState();
    _direccionOrigenController = TextEditingController(text: 'TechStore 360 - Matriz Ambato');
    _direccionDestinoController = TextEditingController();
  }

  @override
  void dispose() {
    _direccionOrigenController.dispose();
    _direccionDestinoController.dispose();
    super.dispose();
  }

  Widget _buildDeliveryMethodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _metodoEntrega = 'DELIVERY';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _metodoEntrega == 'DELIVERY' ? brandRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _metodoEntrega == 'DELIVERY'
                      ? [BoxShadow(color: brandRed.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delivery_dining_outlined,
                        color: _metodoEntrega == 'DELIVERY' ? Colors.white : Colors.black54,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Delivery / Envío',
                        style: TextStyle(
                          color: _metodoEntrega == 'DELIVERY' ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _metodoEntrega = 'PICKUP';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _metodoEntrega == 'PICKUP' ? brandRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _metodoEntrega == 'PICKUP'
                      ? [BoxShadow(color: brandRed.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        color: _metodoEntrega == 'PICKUP' ? Colors.white : Colors.black54,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Retiro en Local',
                        style: TextStyle(
                          color: _metodoEntrega == 'PICKUP' ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            color: isSelected ? brandRed : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? brandRed : const Color(0xFFE5E7EB)),
            boxShadow: isSelected
                ? [BoxShadow(color: brandRed.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
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
        child: Stack(
          children: [
            Form(
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
                                      _buildDeliveryMethodToggle(),
                                      const SizedBox(height: 16),
                                      // Dirección de Origen
                                      TextFormField(
                                        controller: _direccionOrigenController,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          labelText: 'Dirección de Origen (Despacho)',
                                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                          prefixIcon: const Icon(Icons.store_mall_directory_outlined, color: brandRed),
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
                                            borderSide: const BorderSide(color: brandRed, width: 1.2),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'La dirección de origen es requerida';
                                          }
                                          return null;
                                        },
                                      ),
                                      if (_metodoEntrega == 'DELIVERY') ...[
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
                                                  prefixIcon: const Icon(Icons.location_on_outlined, color: brandRed),
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
                                                    borderSide: const BorderSide(color: brandRed, width: 1.2),
                                                  ),
                                                ),
                                                validator: (value) {
                                                  if (_metodoEntrega == 'DELIVERY' && (value == null || value.trim().isEmpty)) {
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
                                                    onAddressSelected: (address, estTime) {
                                                      setState(() {
                                                        _direccionDestinoController.text = address;
                                                        _tiempoEstimado = estTime;
                                                      });
                                                    },
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.map_outlined),
                                              style: IconButton.styleFrom(
                                                backgroundColor: brandRed,
                                                foregroundColor: Colors.white,
                                                fixedSize: const Size(48, 48),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_tiempoEstimado != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: brandRed.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: brandRed.withOpacity(0.15)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.timer_outlined, color: brandRed, size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Tiempo estimado de entrega: $_tiempoEstimado',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandRed),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                      const SizedBox(height: 20),
                                      const Divider(color: Color(0xFFF3F4F6), height: 1),
                                      const SizedBox(height: 16),
                                      // Switch Consumidor Final Premium
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _isConsumidorFinal ? const Color(0xFFF1F5F9) : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _isConsumidorFinal ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _isConsumidorFinal ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.person_pin_rounded,
                                                color: _isConsumidorFinal ? Colors.white : const Color(0xFF64748B),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Consumidor Final',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _isConsumidorFinal
                                                        ? 'Facturación genérica sin datos'
                                                        : 'Facturación con mis datos de perfil',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF64748B),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch(
                                              value: _isConsumidorFinal,
                                              activeThumbColor: brandRed,
                                              activeTrackColor: brandRed.withOpacity(0.4),
                                              inactiveThumbColor: Colors.white,
                                              inactiveTrackColor: const Color(0xFFE2E8F0),
                                              onChanged: (val) {
                                                setState(() {
                                                  _isConsumidorFinal = val;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
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
                                          _buildPaymentMethodCard('PAYPAL', Icons.paypal_rounded, 'PayPal'),
                                        ],
                                      ),
                                      if (_metodoPago == 'EFECTIVO') ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFBEB), // Soft yellow/amber background
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _metodoEntrega == 'PICKUP'
                                                      ? 'Deberá realizar el pago al local al retirar su pedido.'
                                                      : 'Deberá realizar el pago al delivery al recibir su pedido.',
                                                  style: const TextStyle(
                                                    color: Color(0xFF92400E),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                              backgroundColor: brandRed,
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
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: brandRed),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _processPaymentCheckout(BuildContext context, CartProvider cart) {
    if (_metodoPago == 'PAYPAL') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PaypalCheckoutDialog(
          total: cart.total,
          onCreatePurchase: () async {
            return await _processPurchaseAsync(context, cart);
          },
          onSuccess: () {
            if (mounted) {
              Navigator.pop(context); // Cerrar CartModal
            }
            widget.onPurchaseSuccess(); // Redirigir a Mis Compras
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

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Mapear items del carrito al formato que espera el backend
      final detalles = cart.items.map((item) => {
        'producto_id': item.product.id,
        'cantidad': item.quantity,
        'precio_unitario': item.product.precio
      }).toList();

      // Crear la compra a través de la API
      final String? compraId = await apiService.createPurchase(
        detalles,
        dirOrigen + (_isConsumidorFinal ? " | CF" : " | DATA") + " | $_metodoPago",
        _metodoEntrega == 'PICKUP' ? 'Retiro en local' : dirDestino,
        _metodoEntrega,
        auth.headers,
        estado: _metodoPago == 'PAYPAL' ? 'PAGADA' : 'PENDIENTE',
        metodoPago: _metodoPago,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (compraId != null) {
        // Guardar copia de los items antes de vaciar el carrito
        final itemsToInvoice = List<CartItem>.from(cart.items);

        // 1. Cerrar el modal del carrito inmediatamente
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Compra realizada con éxito! 🎉',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // 2. Ejecutar vaciado de carrito
        cart.clearCart();

        // 3. Generar factura de forma totalmente asíncrona sin bloquear la interfaz de usuario
        apiService.generateInvoice(
          compraId, 
          _isConsumidorFinal ? "consumidorfinal@techstore.com" : (auth.email ?? "test@test.com"), 
          _isConsumidorFinal ? "Consumidor Final" : auth.nombreCompleto,
          _isConsumidorFinal ? "9999999999" : (auth.telefono ?? "0999999999"),
          _isConsumidorFinal ? "9999999999" : (auth.cedula ?? "1899999999"),
          itemsToInvoice // Pasamos la copia de CartItem
        ).catchError((err) {
          print("Error al generar factura en background: $err");
          return null;
        });

        // 4. Redirigir a "Mis Compras"
        widget.onPurchaseSuccess();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Error al procesar la compra. Intente nuevamente.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (context.mounted) {
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ $errorMsg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _processPurchaseAsync(BuildContext context, CartProvider cart) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();
    final dirOrigen = _direccionOrigenController.text.trim();
    final dirDestino = _direccionDestinoController.text.trim();

    try {
      final detalles = cart.items.map((item) => {
        'producto_id': item.product.id,
        'cantidad': item.quantity,
        'precio_unitario': item.product.precio
      }).toList();

      final String? compraId = await apiService.createPurchase(
        detalles,
        dirOrigen + (_isConsumidorFinal ? " | CF" : " | DATA") + " | $_metodoPago",
        _metodoEntrega == 'PICKUP' ? 'Retiro en local' : dirDestino,
        _metodoEntrega,
        auth.headers,
        estado: 'PAGADA',
        metodoPago: _metodoPago,
      );

      if (compraId != null) {
        final itemsToInvoice = List<CartItem>.from(cart.items);
        cart.clearCart();

        // Generar factura de forma totalmente asíncrona sin bloquear la interfaz
        apiService.generateInvoice(
          compraId, 
          _isConsumidorFinal ? "consumidorfinal@techstore.com" : (auth.email ?? "test@test.com"), 
          _isConsumidorFinal ? "Consumidor Final" : auth.nombreCompleto,
          _isConsumidorFinal ? "9999999999" : (auth.telefono ?? "0999999999"),
          _isConsumidorFinal ? "9999999999" : (auth.cedula ?? "1899999999"),
          itemsToInvoice
        ).catchError((err) {
          print("Error al generar factura en background: $err");
          return null;
        });

        // Mostrar snackbar de éxito para PayPal también
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Pago con PayPal procesado con éxito! 🎉',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Error en _processPurchaseAsync: $e');
      if (context.mounted) {
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ $errorMsg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }
}

class InteractiveMapWidget extends StatefulWidget {
  final String initialAddress;
  final Function(String address, String estimatedTime) onAddressSelected;

  const InteractiveMapWidget({
    super.key,
    required this.initialAddress,
    required this.onAddressSelected,
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  static const Color brandRed = Color(0xFFFF0050);
  LatLng _markerPosition = const LatLng(-1.249080, -78.616750); // Parque Juan Montalvo, Ambato
  String _selectedAddress = "Calle Bolívar y Castillo, Parque Juan Montalvo, Ambato";
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress.contains('Ficoa')) {
      _markerPosition = const LatLng(-1.238420, -78.632140);
      _selectedAddress = widget.initialAddress;
    } else if (widget.initialAddress.contains('Mall') || widget.initialAddress.contains('Atahualpa')) {
      _markerPosition = const LatLng(-1.261230, -78.624560);
      _selectedAddress = widget.initialAddress;
    } else if (widget.initialAddress.contains('Ingahurco')) {
      _markerPosition = const LatLng(-1.235670, -78.611230);
      _selectedAddress = widget.initialAddress;
    } else if (widget.initialAddress.contains('Miraflores')) {
      _markerPosition = const LatLng(-1.254320, -78.631210);
      _selectedAddress = widget.initialAddress;
    } else if (widget.initialAddress.contains('UTA') || widget.initialAddress.contains('Einstein')) {
      _markerPosition = const LatLng(-1.278900, -78.634560);
      _selectedAddress = widget.initialAddress;
    } else if (widget.initialAddress.contains('Atocha') || widget.initialAddress.contains('Pachano')) {
      _markerPosition = const LatLng(-1.231230, -78.625430);
      _selectedAddress = widget.initialAddress;
    } else if (widget.initialAddress.trim().isNotEmpty) {
      _selectedAddress = widget.initialAddress;
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const p = 0.017453292519943295;
    final c = math.cos;
    final a = 0.5 - c((p2.latitude - p1.latitude) * p)/2 + 
          c(p1.latitude * p) * c(p2.latitude * p) * 
          (1 - c((p2.longitude - p1.longitude) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); // Distance in km
  }

  String _getEstimatedTime(LatLng point) {
    final storeLocation = const LatLng(-1.249080, -78.616750); // Parque Juan Montalvo
    final distance = _calculateDistance(storeLocation, point);
    int minutes = (distance * 5 + 12).round(); // 5 min per km + 12 min base
    if (minutes < 15) minutes = 15;
    if (minutes > 50) minutes = 50;
    
    final lower = (minutes - 3).clamp(15, 45);
    final upper = (minutes + 5).clamp(20, 50);
    return "$lower-$upper min";
  }

  String _getAddressFromLatLng(LatLng point) {
    final double lat = point.latitude;
    final double lng = point.longitude;

    final targets = [
      {'name': 'Calle Bolívar y Castillo, Parque Juan Montalvo, Ambato', 'lat': -1.249080, 'lng': -78.616750},
      {'name': 'Av. Atahualpa y Víctor Hugo, Sector Mall de los Andes, Ambato', 'lat': -1.261230, 'lng': -78.624560},
      {'name': 'Av. Los Guaytambos y Delicias, Sector Ficoa, Ambato', 'lat': -1.238420, 'lng': -78.632140},
      {'name': 'Av. de las Américas, Sector Terminal Terrestre Ingahurco, Ambato', 'lat': -1.235670, 'lng': -78.611230},
      {'name': 'Av. Miraflores y Las Lilas, Sector Miraflores, Ambato', 'lat': -1.254320, 'lng': -78.631210},
      {'name': 'Av. Albert Einstein, Sector Universidad Técnica de Ambato (UTA), Ambato', 'lat': -1.278900, 'lng': -78.634560},
      {'name': 'Av. Rodrigo Pachano, Sector Parque de Atocha, Ambato', 'lat': -1.231230, 'lng': -78.625430},
    ];

    double minDistance = double.infinity;
    String closestName = 'Ambato, Ecuador';

    for (var target in targets) {
      final double targetLat = target['lat'] as double;
      final double targetLng = target['lng'] as double;
      final double dist = (lat - targetLat) * (lat - targetLat) + (lng - targetLng) * (lng - targetLng);
      if (dist < minDistance) {
        minDistance = dist;
        closestName = target['name'] as String;
      }
    }

    if (minDistance > 0.0003) {
      return 'Ambato, Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    }
    return closestName;
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _markerPosition = point;
      _selectedAddress = _getAddressFromLatLng(point);
    });
  }

  @override
  Widget build(BuildContext context) {
    final estTime = _getEstimatedTime(_markerPosition);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 540,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map_outlined, color: brandRed),
                    SizedBox(width: 8),
                    Text(
                      'Selector de Dirección (Ambato)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Toca en el mapa real de Ambato para marcar el punto de entrega de tu pedido.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  color: const Color(0xFFF3F4F6),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _markerPosition,
                      initialZoom: 14.5,
                      onTap: (tapPosition, point) => _onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.techstore360.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _markerPosition,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_on,
                              color: brandRed,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: brandRed, size: 20),
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
                  const Divider(height: 14, color: Color(0xFFE5E7EB)),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: brandRed, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Tiempo estimado de entrega: $estTime',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandRed),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  widget.onAddressSelected(_selectedAddress, estTime);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandRed,
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

class PaypalCheckoutDialog extends StatefulWidget {
  final double total;
  final Future<bool> Function() onCreatePurchase;
  final VoidCallback onSuccess;

  const PaypalCheckoutDialog({
    super.key,
    required this.total,
    required this.onCreatePurchase,
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
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        setState(() {
          _step = 3;
        });

        // Llamar a la API para crear la compra
        final success = await widget.onCreatePurchase();

        if (success) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pop(context); // Cerrar PayPal Dialog
              widget.onSuccess();    // Ejecutar éxito
            }
          });
        } else {
          // Mostrar error en el diálogo (removido SnackBar redundante)
          if (mounted) {
            Navigator.pop(context); // Cerrar PayPal Dialog
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo de PayPal (Estilo Dual Logo Oficial)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.paypal_rounded,
                    color: Color(0xFF003087),
                    size: 32,
                  ),
                  const SizedBox(width: 4),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                      children: [
                        TextSpan(text: 'Pay', style: TextStyle(color: Color(0xFF003087))),
                        TextSpan(text: 'Pal', style: TextStyle(color: Color(0xFF0079C1))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Caja de detalles del cobro
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comercio:',
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ProductTech 360',
                          style: TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total a Pagar:',
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Correo electrónico',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'ejemplo@paypal.com',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF64748B), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5)),
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
              const SizedBox(height: 16),

              const Text(
                'Contraseña de PayPal',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF003087), width: 1.5)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Botón de Pagar (Amarillo PayPal oficial)
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _startPaymentProcess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC439),
                    foregroundColor: const Color(0xFF003087),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Iniciar sesión para pagar',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                child: const Text('Cancelar y volver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: Color(0xFF003087), strokeWidth: 3.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Procesando pago seguro...',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'No cierres la aplicación',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        );
      case 3:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            // Círculo verde de éxito premium animado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 54,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Pago Autorizado!',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Transacción: PAY-8K218304NF',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Completando el pedido...',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
