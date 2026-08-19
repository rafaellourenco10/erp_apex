import 'package:flutter/material.dart';

import '../screens/clientes/clientes_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/meus_pedidos/meus_pedidos_screen.dart';
import '../screens/novo_pedido/adicionar_produtos_screen.dart';
import '../screens/novo_pedido/confirmacao_screen.dart';
import '../screens/novo_pedido/selecionar_cliente_screen.dart';
import '../screens/pedido_sucesso/pedido_sucesso_screen.dart';
import '../screens/produtos/produtos_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String home = '/home';
  static const String clientes = '/clientes';
  static const String produtos = '/produtos';
  static const String novoPedidoCliente = '/novo-pedido/cliente';
  static const String novoPedidoProdutos = '/novo-pedido/produtos';
  static const String novoPedidoConfirmacao = '/novo-pedido/confirmacao';
  static const String pedidoSucesso = '/pedido-sucesso';
  static const String meusPedidos = '/meus-pedidos';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        home: (_) => const HomeScreen(),
        clientes: (_) => const ClientesScreen(),
        produtos: (_) => const ProdutosScreen(),
        novoPedidoCliente: (_) => const SelecionarClienteScreen(),
        novoPedidoProdutos: (_) => const AdicionarProdutosScreen(),
        novoPedidoConfirmacao: (_) => const ConfirmacaoScreen(),
        pedidoSucesso: (_) => const PedidoSucessoScreen(),
        meusPedidos: (_) => const MeusPedidosScreen(),
        dashboard: (_) => const DashboardScreen(),
      };
}
