import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/cart_provider.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ApiService _apiService = ApiService();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Búsqueda y Filtrado
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todos';

  // Marca PedidosYa Red/Magenta
  static const Color brandRed = Color(0xFFFF0050);
  static const Color bgGray = Color(0xFFF7F7F7);

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _fetchProducts() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final products = await _apiService.getProducts(auth.headers);
      setState(() {
        _allProducts = products; // Mostrar todos los productos (activos e inactivos)
        _filteredProducts = _allProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  bool _isSameCategory(String cat1, String cat2) {
    final c1 = cat1.toLowerCase().trim();
    final c2 = cat2.toLowerCase().trim();
    if (c1 == 'todos' || c2 == 'todos') {
      return c1 == c2;
    }
    String norm(String s) {
      if (s.endsWith('es')) return s.substring(0, s.length - 2);
      if (s.endsWith('s')) return s.substring(0, s.length - 1);
      return s;
    }
    return c1 == c2 || norm(c1) == norm(c2) || c1.contains(c2) || c2.contains(c1);
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesQuery = product.nombre.toLowerCase().contains(query) ||
            product.descripcion.toLowerCase().contains(query) ||
            product.categoria.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'Todos' ||
            _isSameCategory(product.categoria, _selectedCategory);
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _handleAddToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ ¡Producto agotado! No se puede agregar al carrito.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.amber[800],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final cart = Provider.of<CartProvider>(context, listen: false);

    cart.addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¡${product.nombre} agregado con éxito! 🛒',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: brandRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<String> get _categories {
    final Set<String> cats = {'Todos'};
    for (var p in _allProducts) {
      if (p.categoria.isNotEmpty) {
        cats.add(_capitalize(p.categoria));
      }
    }
    final sorted = cats.skip(1).toList()..sort();
    return ['Todos', ...sorted];
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconBg,
    required bool isBig,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
          _filterProducts();
        });
      },
      child: Container(
        padding: EdgeInsets.all(isBig ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: isBig
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E1E1E), letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Equipos Pro',
                          style: TextStyle(color: brandRed, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E1E1E), letterSpacing: -0.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgGray,
        body: Center(child: CircularProgressIndicator(color: brandRed)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: bgGray,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: brandRed),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar catálogo:\n$_errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: brandRed, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = '';
                    });
                    _fetchProducts();
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgGray,
      body: SafeArea(
        child: Column(
          children: [
            // Header estilo PedidosYa (Fondo Rojo/Magenta)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: brandRed,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nombre de usuario dropdown
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Text(
                              auth.nombreCompleto.isNotEmpty ? auth.nombreCompleto : 'Hola, Invitado',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                      // Bell y Cart icons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Buscador blanco redondeado con botón rojo adentro
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E1E)),
                      decoration: InputDecoration(
                        hintText: 'Locales, equipos y repuestos...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF757575), size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF757575), size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : Container(
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: brandRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido Principal
            Expanded(
              child: _selectedCategory == 'Todos' && _searchController.text.isEmpty
                  ? _buildHomeLandingView()
                  : _buildCatalogGridView(),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Vista de Inicio / Hub (Estilo PedidosYa)
  Widget _buildHomeLandingView() {
    final featuredProducts = _allProducts.where((p) => p.activo).take(4).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Promocional Plus dynamic
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [brandRed, Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Opacity(
                      opacity: 0.15,
                      child: Icon(Icons.shopping_bag_rounded, size: 180, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'plus Week',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hasta 45% OFF',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Exclusivo en Laptops y Celulares',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grilla de Categorías principales (PedidosYa Hub Style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Fila Superior (2 grandes)
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'Laptops',
                        icon: Icons.laptop_chromebook_rounded,
                        color: const Color(0xFF3B82F6),
                        iconBg: const Color(0x1A3B82F6),
                        isBig: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'Celulares',
                        icon: Icons.phone_android_rounded,
                        color: const Color(0xFF10B981),
                        iconBg: const Color(0x1A10B981),
                        isBig: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Fila Inferior (3 pequeñas de repuesto)
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'Audio',
                        icon: Icons.headphones_rounded,
                        color: const Color(0xFF8B5CF6),
                        iconBg: const Color(0x1A8B5CF6),
                        isBig: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'Accesorios',
                        icon: Icons.keyboard_rounded,
                        color: const Color(0xFFF59E0B),
                        iconBg: const Color(0x1AF59E0B),
                        isBig: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'Todos',
                        icon: Icons.grid_view_rounded,
                        color: const Color(0xFFEC4899),
                        iconBg: const Color(0x1AEC4899),
                        isBig: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Sección de Combos / Productos Destacados
          if (featuredProducts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Ofertas irresistibles de tecnología',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E1E1E), letterSpacing: -0.5),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 2),
              child: Text(
                'Equipos seleccionados con envío gratis',
                style: TextStyle(fontSize: 12, color: Color(0xFF757575), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: featuredProducts.length,
                itemBuilder: (context, index) {
                  final p = featuredProducts[index];
                  return GestureDetector(
                    onTap: () => _showProductDetailsModal(context, p),
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEFEFEF)),
                      ),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagen con badge de descuento
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                              child: Container(
                                height: 110,
                                width: double.infinity,
                                color: const Color(0xFFF1F5F9),
                                child: p.imagenUrl.isNotEmpty
                                    ? Image.network(p.imagenUrl, fit: BoxFit.cover)
                                    : const Icon(Icons.image_outlined, color: Colors.grey),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE100),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '35% DSCTO',
                                  style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                            )
                          ],
                        ),
                        // Detalles
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1E1E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                                  const SizedBox(width: 2),
                                  const Text('4.8', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF757575))),
                                  const SizedBox(width: 4),
                                  Text(
                                    '• ${p.categoria}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${p.precio.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: brandRed),
                                      ),
                                      Text(
                                        '\$${(p.precio * 1.35).toStringAsFixed(2)}',
                                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  // Botón circular de añadir
                                  GestureDetector(
                                    onTap: p.stock > 0 ? () => _handleAddToCart(p) : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: p.stock > 0 ? brandRed : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(p.stock > 0 ? Icons.add : Icons.block_flipped, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 2. Vista de Catálogo Grid / Filtro (PedidosYa Restaurante List Style)
  Widget _buildCatalogGridView() {
    return Column(
      children: [
        // Chips horizontales de categorías
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            height: 38,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase() ||
                    _isSameCategory(_selectedCategory, cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? Colors.white : const Color(0xFF757575),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedCategory = cat;
                          _filterProducts();
                        });
                      }
                    },
                    selectedColor: brandRed,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? brandRed : const Color(0xFFEFEFEF),
                        width: 1.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Barra de estado de filtros (Filtrar, Ordenar, Descuentos)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          color: Colors.white,
          child: Row(
            children: [
              _buildFilterBadge('Filtrar', Icons.tune_rounded),
              const SizedBox(width: 8),
              _buildFilterBadge('Ordenar', Icons.keyboard_arrow_down_rounded),
              const SizedBox(width: 8),
              _buildFilterBadge('Descuentos', Icons.local_offer_outlined),
              const Spacer(),
              Text(
                '${_filteredProducts.length} productos',
                style: const TextStyle(fontSize: 11, color: Color(0xFF757575), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFEFEFEF)),

        // Listado de Productos
        Expanded(
          child: _filteredProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 16),
                      Text(
                        'No hay productos para esta búsqueda.',
                        style: TextStyle(color: Color(0xFF757575), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return GestureDetector(
                      onTap: () => _showProductDetailsModal(context, product),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEFEFEF)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x02000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                        children: [
                          // Imagen
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 85,
                              height: 85,
                              color: const Color(0xFFF1F5F9),
                              child: product.imagenUrl.isNotEmpty
                                  ? Image.network(product.imagenUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.image_outlined, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Detalles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.categoria.toUpperCase(),
                                  style: const TextStyle(color: brandRed, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.nombre,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E1E1E), letterSpacing: -0.2),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.descripcion,
                                  style: const TextStyle(color: Color(0xFF757575), fontSize: 11, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '\$${product.precio.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E1E1E)),
                                    ),
                                    const Spacer(),
                                    if (!product.activo) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.red[200]!, width: 0.5),
                                        ),
                                        child: const Text(
                                          'INACTIVO',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                    // Stock label
                                    Text(
                                      'Stock: ${product.stock}',
                                      style: TextStyle(
                                        color: product.stock > 0 ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botón redondo de agregar PedidosYa style
                          Consumer<CartProvider>(
                            builder: (context, cart, child) {
                              final alreadyInCart = cart.items.any((item) => item.product.id == product.id);
                              return IconButton(
                                onPressed: product.stock > 0 ? () => _handleAddToCart(product) : null,
                                icon: Icon(
                                  alreadyInCart ? Icons.check : Icons.add,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: alreadyInCart ? const Color(0xFF10B981) : brandRed,
                                  foregroundColor: Colors.white,
                                  fixedSize: const Size(40, 40),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1E1E1E), fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: const Color(0xFF757575)),
        ],
      ),
    );
  }

  void _showProductDetailsModal(BuildContext context, Product p) {
    int localQuantity = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Header Image Banner
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: const Color(0xFFF1F5F9),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: p.imagenUrl.isNotEmpty
                                  ? Image.network(p.imagenUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.image_outlined, color: Colors.grey, size: 60),
                            ),
                            // Gradient shadow overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                            // Close icon top right
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black26,
                                  shape: const CircleBorder(),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Details Body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: brandRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.categoria.toUpperCase(),
                                  style: const TextStyle(
                                    color: brandRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Title and Price
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.nombre,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E1E1E),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '\$${p.precio.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: brandRed,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Rating and Stock row
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                                  const SizedBox(width: 4),
                                  const Text('4.8', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
                                  const SizedBox(width: 4),
                                  const Text('(50+ valoraciones)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const Spacer(),
                                  // Stock
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: p.stock > 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: p.stock > 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
                                      ),
                                    ),
                                    child: Text(
                                      p.stock > 0 ? 'Stock: ${p.stock} unidades' : 'Agotado',
                                      style: TextStyle(
                                        color: p.stock > 0 ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32, color: Color(0xFFEFEFEF)),
                              // Delivery Info Card (PedidosYa Style)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bgGray,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFEFEFEF)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.delivery_dining_outlined, color: brandRed, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Envío a domicilio disponible',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1E1E)),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Entrega estimada en 15 - 35 minutos',
                                            style: TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Description
                              const Text(
                                'Descripción',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p.descripcion.isNotEmpty ? p.descripcion : 'No hay descripción disponible para este producto.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF555555),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 80), // Space for bottom sheet buttons
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bottom bar for adding to cart
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Color(0xFFEFEFEF))),
                      ),
                      child: Row(
                        children: [
                          // Quantity Selector
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18, color: Colors.black54),
                                  onPressed: localQuantity > 1
                                      ? () => setModalState(() => localQuantity--)
                                      : null,
                                ),
                                Text(
                                  '$localQuantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18, color: Colors.black54),
                                  onPressed: localQuantity < p.stock
                                      ? () => setModalState(() => localQuantity++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Add to Cart Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: p.stock > 0
                                  ? () {
                                      final cart = Provider.of<CartProvider>(context, listen: false);
                                      cart.addToCart(p, quantity: localQuantity);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '¡$localQuantity ${p.nombre} agregados al carrito! 🛒',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: brandRed,
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandRed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                p.stock > 0
                                    ? 'Agregar \$${(p.precio * localQuantity).toStringAsFixed(2)}'
                                    : 'Agotado',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
