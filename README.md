# ERP Apex — Distribuidora

ERP para uma distribuidora (produtos Nestlé) com dois lados que se completam:

- **App móvel (Flutter)** — usado pelo **vendedor em campo** para consultar catálogo/clientes e lançar pedidos de venda.
- **Painel administrativo (Oracle APEX)** — usado pelo **escritório** para gerenciar clientes, produtos, pedidos, fornecedores e frota, e é também o backend (API REST via ORDS) que o app consome.

Os dois falam com o **mesmo banco Oracle**, hospedado na nuvem (`oracleapex.com`) — não há servidor próprio nem banco local.

```
┌─────────────────┐        REST/JSON        ┌──────────────────────────────┐
│   App Flutter    │ ───────────────────────▶│  ORDS (módulo erp.api)       │
│  (vendedor, campo)│◀─────────────────────── │  https://oracleapex.com/ords │
└─────────────────┘                          │  /erp_rafaellourenco/erp     │
                                              └───────────────┬───────────────┘
                                                              │
                          ┌───────────────────────────────────┴──────────────┐
                          │         Oracle Database (workspace                │
                          │         erp_rafaellourenco)                      │
                          └───────────────┬───────────────────────────────────┘
                                              │
                                  ┌───────────┴────────────┐
                                  │  Oracle APEX App Builder │
                                  │  (Application 166105)    │
                                  │  usado pelo escritório    │
                                  └───────────────────────────┘
```

## Índice

- [App móvel (Flutter)](#app-móvel-flutter)
- [Painel administrativo (Oracle APEX)](#painel-administrativo-oracle-apex)
- [Modelo de dados](#modelo-de-dados)
- [API (ORDS)](#api-ords)
- [Limitações conhecidas](#limitações-conhecidas)
- [Documentação completa](#documentação-completa)

---

## App móvel (Flutter)

### Stack

- **Flutter/Dart** — Android e Web
- **`provider`** — gerenciamento de estado (`ChangeNotifier`), sem Riverpod/Bloc/Clean Architecture
- **`dio`** — cliente HTTP
- **`pdf` + `printing`** — geração e compartilhamento de PDF
- **`intl` + `flutter_localizations`** — formatação e componentes em pt_BR

### Arquitetura em camadas

```
lib/
├── main.dart              # monta o MultiProvider e injeta os services
├── app/                   # MaterialApp raiz + rotas nomeadas
├── core/                  # design system (cores, tipografia, tema), formatters, widgets compartilhados
├── models/                # Cliente, Produto, Pedido, ItemPedido, Caminhao — parsing manual de JSON
├── services/               # um service por entidade, wrapper fino sobre ApiService (Dio)
├── providers/              # um ChangeNotifier por área — carregar(), isLoading/error, submissão isolada
└── screens/                # uma pasta por fluxo/tela
```

Padrão repetido em todo provider de listagem: `carregar()` → `isLoading = true` → chama o service → captura `ApiException` (mensagem amigável) ou erro genérico → `isLoading = false` + `notifyListeners()`.

### Funcionalidades

| Módulo | O que faz |
|---|---|
| **Login** | Mock — só valida formato de e-mail, não chama API. Sem autenticação real ainda. |
| **Home** | Atalhos: Novo Pedido, Clientes, Produtos, Meus Pedidos, Dashboard, Relatórios. |
| **Clientes** | Lista com busca; **cadastro e edição** (CPF/CNPJ com máscara que alterna CPF↔CNPJ automaticamente, endereço estruturado, telefone com máscara `(44) 99999-0000`). Exclusão deliberadamente não implementada ainda. |
| **Produtos** | Catálogo com busca e badge de estoque baixo. Sem CRUD pelo app (só leitura). |
| **Novo Pedido** | Wizard de 3 passos: selecionar cliente → adicionar produtos (quantidade digitável com clamp no estoque) → confirmar. Envio atômico (`POST /pedidos_completo`) — tudo ou nada, sem pedido "pela metade". |
| **Meus Pedidos** | Histórico com filtro por status, detalhe do pedido, cancelamento real, e "repetir pedido" (pré-preenche o carrinho com preço/estoque atuais). |
| **Dashboard** | KPIs calculados no cliente (pedidos pendentes, valor em aberto) + status da frota de caminhões. |
| **Relatórios** | Filtro por período/status sobre o histórico já carregado; gera PDF de um pedido específico ou do período consolidado; compartilha via share sheet nativo do Android (WhatsApp aparece como uma das opções). 100% client-side. |

### Como rodar

```bash
flutter pub get
flutter run
```

A URL base da API está fixa em `lib/core/constants/api_constants.dart` (não usa `--dart-define` ainda).

---

## Painel administrativo (Oracle APEX)

Ferramenta hospedada em `oracleapex.com`, workspace `erp_rafaellourenco`, `Application 166105`, Oracle APEX **26.1.3**. É o **App Builder / Page Designer** — editor visual de páginas — diferente da API ORDS que o app consome (embora ambos vivam no mesmo workspace/banco).

> ⚠️ O estado das páginas criadas ali **não fica neste repositório** (o App Builder não é versionado por arquivo) — só o que for schema/API (tabelas, triggers, procedures, handlers ORDS) é versionado em [`backend/oracle/`](backend/oracle/). O mapa de páginas e as instruções de navegação confirmadas ficam em [`.claude/skills/apex-ui-guide/docs/UI_MAP.md`](.claude/skills/apex-ui-guide/docs/UI_MAP.md).

### Páginas

Convenção: cada tabela com CRUD tem duas páginas adjacentes — uma **Interactive Report** de listagem e um **`Form_<Tabela>`** (DML Form) de cadastro/edição.

| Página | Alias | Tipo | Papel |
|---|---|---|---|
| Clientes / Form_Clientes | `clientes` / `form-clientes` | IR / DML Form | CRUD de clientes (inclui CPF/CNPJ e endereço) |
| Produtos / Form_Produtos | `produtos` / `form-produtos` | IR / DML Form | CRUD de produtos |
| Pedidos / Form_Pedidos | `pedidos` / `form-pedidos` | IR / DML Form | CRUD de pedidos |
| Itens_Pedido / Form_Itens_Pedido | `itens-pedido` / `form-itens-pedido` | IR / DML Form | CRUD de itens de pedido |
| Fornecedores / Form_Fornecedores | `fornecedores` / `form-fornecedores` | IR / DML Form | CRUD de fornecedores (sem equivalente no app ainda) |
| Caminhoes / Form_Caminhoes | `caminhoes` / `form-caminhoes` | IR / DML Form | CRUD da frota |
| Dashboard | `dashboard` | Home | Página inicial do painel |
| Top Clientes - Gráfico | `top-clientes-gráfico` | Chart | Gráfico gerencial |
| Relatório de Vendas | `relatório-de-vendas` | IR | Filtro por período; clicar no cliente abre o pedido (com os itens) em `Itens do Pedido`, com botão de impressão via `window.print()` e uma região dedicada só pra impressão limpa (CSS `@media print`) |
| Itens do Pedido | `itens-do-pedido` | DML Form (Master-Detail) | Form de PEDIDOS com grade de ITENS_PEDIDO — apesar do nome, também edita o cabeçalho do pedido |

### Scripts SQL/ORDS versionados

Aplicados manualmente no SQL Workshop, na ordem numerada — ver [`backend/oracle/README.md`](backend/oracle/README.md) para o passo a passo completo, lições de depuração (ex.: `:body` chega como BLOB, não CLOB) e o padrão de erro (`:status_code := 400` + `{"error": SQLERRM}`).

| # | Script | O que faz |
|---|---|---|
| 01–02 | `criar_pedido_completo` + endpoint | Cria pedido + itens numa transação atômica |
| 03 | *(opcional)* | Melhora a mensagem de estoque insuficiente |
| 04–05 | `cancelar_pedido` + endpoint | Cancela pedido `PENDENTE`, devolve estoque |
| 06–07 | Frota | Cria `CAMINHOES` + endpoints `GET`/`POST status` |
| 08 | Correção | `cancelar_pedido` devolvia HTTP 200 em erro de negócio |
| 09 | Dados de exemplo | Popula caminhões de teste |
| 10 | Correção *(pendente de aplicar)* | Mesmo bug do item 8, em `/pedidos_completo` |
| 11 | `ALTER TABLE CLIENTES` | Adiciona CPF/CNPJ + endereço estruturado |
| 12 | Dados de exemplo | Popula CPF/CNPJ e endereço nos clientes de teste |

Alguns endpoints (`GET/POST /clientes`, `POST /clientes/:id`, `GET/POST /produtos`) foram criados **direto pela interface do RESTful Services**, não por script — ficam documentados em prosa no `backend/oracle/README.md`.

### Como aplicar um script novo

1. SQL Workshop → SQL Commands (pra `ALTER TABLE`/`CREATE`/procedures) ou RESTful Services (pra endpoints).
2. Rode na ordem numerada.
3. Teste POST/PATCH pelo **Postman**, não `curl`/PowerShell (trava sem erro nesse ambiente).

---

## Modelo de dados

```
CLIENTES ──< PEDIDOS ──< ITENS_PEDIDO >── PRODUTOS >── FORNECEDORES
 (1)          (N)            (N)            (1)           (1)

CAMINHOES  (frota, sem FK com as demais tabelas)
```

Detalhe completo (colunas, tipos, triggers) em [`backend/oracle/SCHEMA.md`](backend/oracle/SCHEMA.md). Dois triggers em `ITENS_PEDIDO`: um valida/baixa estoque (`ORA-20001` se insuficiente), outro recalcula `PEDIDOS.VALOR_TOTAL` automaticamente.

## API (ORDS)

Base: `https://oracleapex.com/ords/erp_rafaellourenco/erp`

| Método | Endpoint | Uso |
|---|---|---|
| GET/POST | `/clientes`, `/clientes/{id}` | Listar, criar, editar cliente |
| GET | `/produtos` | Catálogo |
| POST | `/pedidos_completo` | Criar pedido + itens (atômico) |
| GET | `/pedidos`, `/itens_pedido?id_pedido={id}` | Histórico e detalhe |
| POST | `/pedidos/{id}/cancelar` | Cancelar pedido pendente |
| GET/POST | `/caminhoes`, `/caminhoes/{id}/status` | Frota |

Respostas `GET` seguem o envelope padrão ORDS `{"items": [...], "hasMore": ..., "limit": ..., "offset": ...}`. Detalhe completo em [`docs/FLUTTER.md`](docs/FLUTTER.md).

## Limitações conhecidas

- **Sem autenticação real** — login do app é mock, chamadas ORDS são anônimas.
- **Sem paginação no app** — os services ignoram `hasMore`/`offset`; catálogos grandes ficariam truncados.
- **Sem persistência local** — carrinho e sessão só em memória.
- **Sem CRUD de Produtos nem tela de Fornecedores** no app (tabela existe, sem equivalente Flutter).
- Bug conhecido pendente: `/pedidos_completo` pode devolver HTTP 200 em erro de negócio (script 10 já existe, falta aplicar — ver `docs/MEMORIA.md`).

Lista priorizada de melhorias pensando no negócio de distribuidora (romaneio de entrega, fluxo de compra com fornecedor, ciclo de vida completo do pedido, vendedor/comissão) em [`docs/MEMORIA.md`](docs/MEMORIA.md).

## Documentação completa

| Arquivo | Conteúdo |
|---|---|
| [`docs/MEMORIA.md`](docs/MEMORIA.md) | Estado atual, decisões, bugs conhecidos, histórico — **leia primeiro** se for dar manutenção |
| [`docs/FLUTTER.md`](docs/FLUTTER.md) | Arquitetura detalhada do app (camadas, telas, providers, models × banco) |
| [`backend/oracle/SCHEMA.md`](backend/oracle/SCHEMA.md) | Modelo de dados completo |
| [`backend/oracle/README.md`](backend/oracle/README.md) | Scripts SQL/ORDS, lições de depuração, contratos de API |
| [`.claude/skills/apex-ui-guide/docs/UI_MAP.md`](.claude/skills/apex-ui-guide/docs/UI_MAP.md) | Navegação confirmada do App Builder (evita instrução por suposição) |

Projeto trabalhado a partir de duas máquinas diferentes — por isso a memória de projeto fica versionada em `docs/`, não só na pasta local do Claude Code.
