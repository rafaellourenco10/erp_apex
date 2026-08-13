import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:erp_apex/app/app.dart';
import 'package:erp_apex/providers/auth_provider.dart';
import 'package:erp_apex/providers/cliente_provider.dart';
import 'package:erp_apex/providers/pedido_provider.dart';
import 'package:erp_apex/providers/produto_provider.dart';
import 'package:erp_apex/services/api_service.dart';
import 'package:erp_apex/services/cliente_service.dart';
import 'package:erp_apex/services/pedido_service.dart';
import 'package:erp_apex/services/produto_service.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    final apiService = ApiService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ClienteProvider(ClienteService(apiService))),
          ChangeNotifierProvider(create: (_) => ProdutoProvider(ProdutoService(apiService))),
          ChangeNotifierProvider(create: (_) => PedidoProvider(PedidoService(apiService))),
        ],
        child: const SalesProApp(),
      ),
    );

    expect(find.text('ERP Simples'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
