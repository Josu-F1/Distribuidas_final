import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
import 'cart_provider.dart';

class ApiService {
  // URL de la API pública en Render
  static const String baseUrl = 'https://techstore-flask-api.onrender.com';

  Future<List<User>> getUsers(Map<String, String> headers) async {
    final response = await http.get(Uri.parse('$baseUrl/api/usuarios'), headers: headers);
    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      List<dynamic> body = decodedBody['data'] ?? [];
      return body.map((dynamic item) => User.fromJson(item)).toList();
    } else {
      throw Exception('Fallo al cargar usuarios. Código: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<User> updateUser(String userId, Map<String, dynamic> data, Map<String, String> headers) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/usuarios/$userId'),
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic>) {
        if (decodedBody['data'] != null) {
          final dataVal = decodedBody['data'];
          if (dataVal is Map<String, dynamic>) {
            return User.fromJson(dataVal);
          } else if (dataVal is List && dataVal.isNotEmpty && dataVal[0] is Map<String, dynamic>) {
            return User.fromJson(dataVal[0]);
          }
        }
        if (decodedBody['id'] != null || decodedBody['firebase_uid'] != null) {
          // If the user object is returned directly at the root of response
          return User.fromJson(decodedBody);
        }
        // If the backend returns a success indicator without the user object
        if (decodedBody['success'] == true || decodedBody['message'] != null) {
          return User(
            id: userId,
            firebaseUid: '',
            nombres: data['nombres'] ?? '',
            apellidos: data['apellidos'] ?? '',
            email: '',
            rol: data['rol'] ?? 'CLIENTE',
            telefono: data['telefono'],
            cedula: data['cedula'] ?? data['cedula_ruc'],
            estado: data['estado'] == true,
            eliminado: data['eliminado'] == true,
            createdAt: '',
          );
        }
      }
      throw Exception('Formato de respuesta de actualización desconocido. Body: ${response.body}');
    } else {
      throw Exception('Error al actualizar usuario (Código ${response.statusCode}): ${response.body}');
    }
  }

  Future<List<Product>> getProducts(Map<String, String> headers) async {
    final response = await http.get(Uri.parse('$baseUrl/api/productos'), headers: headers);
    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      List<dynamic> body = decodedBody['data'] ?? [];
      return body.map((dynamic item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Fallo al cargar productos');
    }
  }

  Future<List<Purchase>> getPurchases(Map<String, String> headers) async {
    final response = await http.get(Uri.parse('$baseUrl/api/compras?admin=true'), headers: headers);
    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      List<dynamic> body = decodedBody['data'] ?? [];
      return body.map((dynamic item) => Purchase.fromJson(item)).toList();
    } else {
      throw Exception('Fallo al cargar compras. Código: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<String?> createPurchase(
    List<Map<String, dynamic>> items,
    String? direccionOrigen,
    String? direccionDestino,
    Map<String, String> headers,
  ) async {
    print('Enviando compra a: $baseUrl/api/compras');
    try {
      final requestHeaders = {
        'Content-Type': 'application/json',
        ...headers,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/compras'),
        headers: requestHeaders,
        body: jsonEncode({
          'detalles': items,
          'direccion_origen': direccionOrigen,
          'direccion_destino': direccionDestino,
        }),
      );
      
      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['compra_id']?.toString();
      }
      return null;
    } catch (e) {
      print('Error en ApiService (createPurchase): $e');
      return null;
    }
  }

  Future<void> generateInvoice(String compraId, String userEmail, String clientName, String? userPhone, String? userCedula, List<CartItem> items) async {
    // URL de la API de facturación pública en Render
    const String billingUrl = 'https://invoicing-rest-api-c6wh.onrender.com/api/factura';
    
    final safeCompraId = compraId.substring(0, compraId.length >= 8 ? 8 : compraId.length).toUpperCase();
    final payload = {
      'numero': 'F001-$safeCompraId',
      'fecha': DateTime.now().toIso8601String().split('T')[0],
      'cliente': {
        'nombre': clientName.trim().isNotEmpty ? clientName : 'Cliente Móvil',
        'cedula_ruc': (userCedula != null && userCedula.trim().isNotEmpty) ? userCedula.trim() : '1899999999',
        'correo': userEmail,
        'telefono': (userPhone != null && userPhone.trim().isNotEmpty) ? userPhone.trim() : '0999999999',
        'direccion': 'Ecuador'
      },
      'productos': items.map((item) => {
        'nombre': item.product.nombre.trim().isNotEmpty ? item.product.nombre : 'Producto sin nombre',
        'cantidad': item.quantity,
        'precio_unitario': item.product.precio,
      }).toList()
    };

    try {
      final response = await http.post(
        Uri.parse(billingUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      print('Respuesta servicio facturación: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Error en la respuesta del servicio de facturación: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error al contactar servicio de facturación: $e');
    }
  }

  Future<String?> generateInvoiceFromPurchase(Purchase purchase, String userEmail, String clientName, String? userPhone, String? userCedula) async {
    const String billingUrl = 'https://invoicing-rest-api-c6wh.onrender.com/api/factura';
    
    final safePurchaseId = purchase.id.substring(0, purchase.id.length >= 8 ? 8 : purchase.id.length).toUpperCase();
    
    // Validar y parsear la fecha de forma robusta. Si es nula o inválida, usar la fecha actual.
    final parsedDate = DateTime.tryParse(purchase.fechaCompra);
    final finalFecha = parsedDate != null 
        ? purchase.fechaCompra.split('T')[0] 
        : DateTime.now().toIso8601String().split('T')[0];

    final payload = {
      'numero': 'F001-$safePurchaseId',
      'fecha': finalFecha,
      'cliente': {
        'nombre': clientName.trim().isNotEmpty ? clientName : 'Cliente Móvil',
        'cedula_ruc': (userCedula != null && userCedula.trim().isNotEmpty) ? userCedula.trim() : '1899999999',
        'correo': userEmail,
        'telefono': (userPhone != null && userPhone.trim().isNotEmpty) ? userPhone.trim() : '0999999999',
        'direccion': 'Ecuador'
      },
      'productos': purchase.detalles.map((detail) => {
        'nombre': detail.productoNombre.trim().isNotEmpty ? detail.productoNombre : 'Producto sin nombre',
        'cantidad': detail.cantidad,
        'precio_unitario': detail.precioUnitario,
      }).toList()
    };

    try {
      final response = await http.post(
        Uri.parse(billingUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        return response.body; // Retorna el XML
      } else {
        print('Error en la respuesta del servicio de facturación: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al contactar servicio de facturación: $e');
      return null;
    }
  }
}
