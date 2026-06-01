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

  Product({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoria,
    required this.activo,
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

  Purchase({
    required this.id,
    required this.usuarioId,
    required this.fechaCompra,
    required this.subtotal,
    required this.iva,
    required this.total,
    required this.estado,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'].toString(),
      usuarioId: (json['usuario_id'] ?? '').toString(),
      fechaCompra: json['fecha_compra'] ?? '',
      subtotal: double.parse((json['subtotal'] ?? 0).toString()),
      iva: double.parse((json['iva'] ?? 0).toString()),
      total: double.parse(json['total'].toString()),
      estado: json['estado'],
    );
  }
}
