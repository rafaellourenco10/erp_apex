import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/auth_provider.dart';
import 'providers/cliente_provider.dart';
import 'providers/historico_pedidos_provider.dart';
import 'providers/pedido_provider.dart';
import 'providers/produto_provider.dart';
import 'services/api_service.dart';
import 'services/cliente_service.dart';
import 'services/pedido_service.dart';
import 'services/produto_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  final apiService = ApiService();
  final clienteService = ClienteService(apiService);
  final produtoService = ProdutoService(apiService);
  final pedidoService = PedidoService(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => pedidoService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider(clienteService)),
        ChangeNotifierProvider(create: (_) => ProdutoProvider(produtoService)),
        ChangeNotifierProvider(create: (_) => PedidoProvider(pedidoService)),
        ChangeNotifierProvider(
            create: (_) => HistoricoPedidosProvider(pedidoService)),
      ],
      child: const SalesProApp(),
    ),
  );
}
