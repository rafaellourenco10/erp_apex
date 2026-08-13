# erp_apex

MVP em Flutter para vendedores de uma distribuidora de produtos Nestlé realizarem pedidos de venda em campo, conectando-se a um ERP Oracle APEX via API REST (ORDS).

## Stack

- Flutter (Dart) — Android e Web
- `provider` para gerenciamento de estado
- `dio` para chamadas HTTP
- Backend: Oracle APEX / ORDS (`https://oracleapex.com/ords/erp_rafaellourenco/erp`)

## Funcionalidades

- Login (mock, sem API de autenticação ainda)
- Home com atalhos para Novo Pedido, Clientes, Produtos e Meus Pedidos
- Cadastro de pedido em 3 etapas: seleção de cliente, seleção de produtos (com controle de quantidade e estoque) e confirmação
- Listagem de clientes e catálogo de produtos (com alerta de estoque baixo)
- Histórico de pedidos com filtro por status e tela de detalhe

## Como rodar

```bash
flutter pub get
flutter run
```
