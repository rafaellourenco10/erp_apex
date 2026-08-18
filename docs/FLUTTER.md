# App Flutter — ERP Simples

Estudo da arquitetura do app em `lib/`, que consome a API ORDS/Oracle APEX documentada em [`backend/oracle/SCHEMA.md`](../backend/oracle/SCHEMA.md). Levantado em 2026-08-18.

## Estrutura de pastas

```
lib/
├── main.dart                          # entry point, monta MultiProvider e injeta serviços
├── app/
│   ├── app.dart                       # widget raiz MaterialApp (SalesProApp)
│   └── routes.dart                    # tabela de rotas nomeadas (AppRoutes)
├── core/
│   ├── constants/                     # api_constants.dart (base URL ORDS), app_colors.dart
│   ├── theme/                         # app_theme.dart, app_text_styles.dart
│   ├── utils/                         # formatters.dart (moeda/data/telefone)
│   └── widgets/                       # app_bottom_nav_bar.dart, state_views.dart (Loading/Error/Empty)
├── models/                            # cliente.dart, produto.dart, pedido.dart, item_pedido.dart
├── providers/                         # um ChangeNotifier por área (ver tabela abaixo)
├── services/                          # api_service.dart (Dio) + um service por entidade
└── screens/                           # login/, home/, clientes/, produtos/, novo_pedido/, meus_pedidos/, pedido_sucesso/
```

~35 arquivos `.dart`. **Não existe nada de `Fornecedores`** (model/service/provider/tela) apesar de a tabela `FORNECEDORES` existir no banco — é a lacuna mais visível entre banco e app hoje.

## Gerenciamento de estado

**Provider** (`provider: ^6.1.0`), padrão `ChangeNotifier`. Sem Riverpod/Bloc. `setState` local só pra estado puramente de UI (ex.: campo de senha visível, filtro de chip selecionado).

| Provider | Gerencia |
|---|---|
| `AuthProvider` | Login/logout — **mock**, não chama API (ver Pendências) |
| `ClienteProvider` | Lista de clientes, busca, loading/error |
| `ProdutoProvider` | Lista de produtos, busca, loading/error |
| `PedidoProvider` | Fluxo "Novo Pedido": cliente selecionado, carrinho, submissão |
| `HistoricoPedidosProvider` | "Meus Pedidos": lista, cancelamento com atualização otimista |
| `Provider<PedidoService>` | Service exposto direto (sem ChangeNotifier), usado por telas que buscam dados sem passar por outro provider |

Padrão repetido em todos: `carregar()` → `_isLoading=true` → chama service → captura `ApiException` (mensagem amigável) ou erro genérico → `_isLoading=false` + `notifyListeners()`.

## Integração com a API (ORDS)

`ApiService` (`lib/services/api_service.dart`) é um wrapper fino sobre **Dio**, base URL em `lib/core/constants/api_constants.dart`:
```
https://oracleapex.com/ords/erp_rafaellourenco/erp
```

| Método | Endpoint | Uso |
|---|---|---|
| GET | `/clientes` | Lista clientes (`ClienteService`) |
| GET | `/produtos` | Lista produtos (`ProdutoService`) |
| POST | `/pedidos_completo` | Cria pedido + itens numa transação atômica (ver `backend/oracle/01_criar_pedido_completo.sql`) |
| GET | `/pedidos` | Histórico de pedidos |
| GET | `/itens_pedido?id_pedido={id}` | Itens de um pedido (tela de detalhe) |
| POST | `/pedidos/{id}/cancelar` | Cancela pedido pendente |

- Respostas GET seguem o envelope padrão ORDS `{"items": [...]}`; parsing manual (`Model.fromJson`), sem `json_serializable`/`freezed`.
- Tratamento de erro centralizado em `ApiService._mapError`: extrai mensagem do corpo, trata timeout/conexão, e tem um caso especial pra `ORA-20001` (estoque insuficiente) — extrai a mensagem de negócio do Oracle via regex e marca `ApiException(estoqueInsuficiente: true)`.
- Erros chegam à UI via `ErrorRetryView` (tela cheia) ou `SnackBar` (ações pontuais).

## Models × banco de dados

| Model Flutter | Tabela Oracle | Observação |
|---|---|---|
| `Cliente` | `CLIENTES` | Reduzido: só `id_cliente, nome, email, telefone` |
| `Produto` | `PRODUTOS` | `estoqueBaixo` é regra **hardcoded no client** (`estoque <= 20`), não vem do backend |
| `Pedido` | `PEDIDOS` (+ join `CLIENTES` p/ nome) | `PedidoStatus` enum: `pendente, aprovado, faturado, entregue, cancelado` |
| `PedidoItemResumo` | `ITENS_PEDIDO` (+ join `PRODUTOS` p/ nome) | — |
| `ItemPedido` | *(não persistido)* | Item do carrinho em memória durante o fluxo de novo pedido |
| — | `FORNECEDORES` | **Sem model correspondente** |

## Telas e navegação

Rotas nomeadas centralizadas em `AppRoutes`, com uma exceção (ver Pendências #7).

| Tela | Rota | Papel |
|---|---|---|
| `LoginScreen` | `/` | Login mock |
| `HomeScreen` | `/home` | Menu com 4 atalhos |
| `ClientesScreen` | `/clientes` | Lista + busca |
| `ProdutosScreen` | `/produtos` | Lista com badge de estoque baixo |
| `SelecionarClienteScreen` → `AdicionarProdutosScreen` → `ConfirmacaoScreen` | `/novo-pedido/*` | Wizard de 3 passos pra criar pedido |
| `PedidoSucessoScreen` | `/pedido-sucesso` | Confirmação pós-criação |
| `MeusPedidosScreen` | `/meus-pedidos` | Histórico com filtro por status |
| `DetalhePedidoScreen` | *(sem rota nomeada)* | Detalhe, cancelar, "repetir pedido" |

## Dependências principais (`pubspec.yaml`)

`dio` (HTTP), `provider` (estado), `intl` (formatação pt_BR), `google_fonts` (declarada mas sem uso encontrado — ver Pendências).

## Pendências / inconsistências conhecidas

1. **Login é 100% mock** — `AuthProvider.login()` não chama API real, só valida formato do e-mail. Sem logout na UI.
2. Comentário de classe desatualizado em `PedidoProvider` (ainda descreve o fluxo antigo de N chamadas, pré-`/pedidos_completo`).
3. Cadastro de cliente: botão existe, ação é só um `SnackBar` "em breve".
4. Aba "Perfil" da bottom nav: não implementada, só `SnackBar`.
5. Sem CRUD de Produtos nem qualquer tela de Fornecedores.
6. `Produto.estoqueBaixo` com limiar fixo no client (`<= 20`) — candidato a virar `ESTOQUE_MINIMO` (coluna que já existe em `PRODUTOS`, ver `SCHEMA.md`).
7. `DetalhePedidoScreen` foge do padrão de rotas nomeadas (aberta via `MaterialPageRoute` direto) — impede deep-link.
8. Sem testes automatizados além do template padrão do Flutter.
9. `google_fonts` possivelmente não usada; `fontFamily: 'Inter'` no tema sem fonte declarada em assets.
10. Nenhuma autenticação real chega à API — todas as chamadas ORDS são anônimas.
