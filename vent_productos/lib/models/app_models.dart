class User {
  final String id;
  final String firebaseUid;
  final String nombres;
  final String apellidos;
  final String email;
  final String rol;
  final bool estado;
  final String createdAt;

  User({
    required this.id,
    required this.firebaseUid,
    required this.nombres,
    required this.apellidos,
    required this.email,
    required this.rol,
    required this.estado,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      firebaseUid: json['firebase_uid'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'],
      estado: json['estado'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }

  String get nombreCompleto => '$nombres $apellidos';
}

class Product {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String categoria;
  final bool activo;
  final String imagenUrl;

  Product({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoria,
    required this.activo,
    required this.imagenUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      precio: double.parse(json['precio'].toString()),
      stock: json['stock'],
      categoria: json['categoria'] ?? 'General',
      activo: json['activo'] == true,
      imagenUrl: json['imagen_url'] ?? json['imagen'] ?? json['image_url'] ?? '',
    );
  }
}

class PurchaseDetail {
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;

  PurchaseDetail({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseDetail(
      productoId: (json['producto_id'] ?? '').toString(),
      productoNombre: json['producto']?['nombre'] ?? json['producto_nombre'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      precioUnitario: double.parse((json['precio_unitario'] ?? 0).toString()),
    );
  }
}

class Purchase {
  final String id;
  final String usuarioId;
  final String fechaCompra;
  final double subtotal;
  final double iva;
  final double total;
  final String estado;
  final List<PurchaseDetail> detalles;

  Purchase({
    required this.id,
    required this.usuarioId,
    required this.fechaCompra,
    required this.subtotal,
    required this.iva,
    required this.total,
    required this.estado,
    required this.detalles,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    var list = json['detalles'] as List? ?? json['details'] as List? ?? [];
    List<PurchaseDetail> detailsList = list.map((i) => PurchaseDetail.fromJson(i)).toList();

    return Purchase(
      id: json['id'].toString(),
      usuarioId: (json['usuario_id'] ?? '').toString(),
      fechaCompra: json['fecha_compra'] ?? '',
      subtotal: double.parse((json['subtotal'] ?? 0).toString()),
      iva: double.parse((json['iva'] ?? 0).toString()),
      total: double.parse(json['total'].toString()),
      estado: json['estado'],
      detalles: detailsList,
    );
  }
}
