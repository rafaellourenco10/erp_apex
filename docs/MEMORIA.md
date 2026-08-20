# Memória do Projeto — erp_apex (multi-máquina)

> Este arquivo existe porque o projeto é trabalhado a partir de **dois computadores diferentes**.
> A pasta de memória padrão do Claude Code (`~/.claude/projects/.../memory/`) é local por máquina
> e não sincroniza via git — então, a partir de 2026-08-19, tudo que for relevante para o projeto
> em si (não só para "esta instalação do Claude") passa a ser anotado aqui, versionado com o resto
> do repositório.

## Como isso deve funcionar (instruções para o Claude)

1. **No início de uma sessão neste projeto, leia este arquivo primeiro**, junto com os docs que
   ele referencia, antes de reexplorar o código do zero com Read/Grep/Glob. Isso é o mecanismo de
   economia de tokens que o usuário pediu: preferir memória já sintetizada a releitura do código.
2. Quando aprender algo novo e durável sobre o projeto (decisão de arquitetura, bug conhecido,
   convenção de trabalho, preferência do usuário), **adicione aqui** (ou atualize o doc específico
   relevante) em vez de só guardar na memória local — porque a memória local não vai para o outro
   computador.
3. Isso não substitui a pasta de memória local do Claude Code — ela continua útil para coisas
   ligadas à conta/máquina. Mas qualquer coisa relevante para o *projeto* deve estar aqui também
   (ou só aqui).
4. Não duplique o que já está detalhado em `docs/FLUTTER.md`, `backend/oracle/SCHEMA.md` e
   `backend/oracle/README.md` — esses já são estudos profundos e versionados. Este arquivo é para
   o que for novo, para decisões, para o "estado atual" e para como o usuário gosta de trabalhar.
5. Mantenha entradas datadas (`AAAA-MM-DD`) para dar para saber o que ainda é válido depois de um
   tempo.

## Perfil do usuário / como trabalhar

- Usuário: Rafael (autor dos commits do projeto; e-mail `ikutschenko@gmail.com`).
- Comunicação preferida: **português (pt-BR)**.
- Trabalha em pelo menos dois computadores diferentes neste projeto — daí a necessidade deste
  arquivo.
- **Pediu explicitamente (2026-08-19) para usar subagentes** (`Agent` tool, tipo `Explore` ou
  `general-purpose`) para levantamentos amplos de código, em vez de o Claude principal ler todos
  os arquivos diretamente — os agentes leem o código e devolvem relatórios já sintetizados
  (com citações arquivo:linha), o que evita carregar o código-fonte inteiro no contexto principal.
  Essa abordagem foi usada com sucesso para estudar a arquitetura Flutter + backend Oracle em
  paralelo (2 agentes simultâneos, ~50k tokens cada, isolados do contexto principal).
- Ambiente: Windows 11, PowerShell como shell principal, Bash (Git Bash) também disponível.

## Estado do projeto (snapshot 2026-08-19)

App Flutter (`erp_apex`, distribuidora) consumindo API real via Oracle APEX/ORDS (não é mock,
exceto o login). Documentação de arquitetura já existe e é a fonte primária:

- [`docs/FLUTTER.md`](FLUTTER.md) — arquitetura do app Flutter (camadas, telas, providers, models
  × banco, pendências conhecidas).
- [`backend/oracle/SCHEMA.md`](../backend/oracle/SCHEMA.md) — modelo de dados Oracle.
- [`backend/oracle/README.md`](../backend/oracle/README.md) — histórico dos scripts SQL numerados
  e decisões/descobertas do backend (ex.: bugs de HTTP 200 em erro, particularidades do ambiente
  ORDS).

Resumo rápido (não repetir detalhes, já estão nos docs acima):
- Frontend: Provider (`ChangeNotifier`), camadas `models → services → providers → screens`, sem
  Riverpod/Bloc/Clean Architecture.
- Backend: Oracle Database + ORDS, módulo `erp.api`, workspace `erp_rafaellourenco`.
- Módulos: Clientes, Produtos, Pedidos (novo + histórico), Caminhões/Frota, Dashboard, Relatórios
  (novo em 2026-08-20). Sem CRUD de clientes/produtos ainda, sem tela de Fornecedores (existe no
  banco, não no app), login 100% mock.

## Funcionalidade: Relatórios (PDF + compartilhar), 2026-08-20

Card na Home → `RelatoriosScreen` (`lib/screens/relatorios/relatorios_screen.dart`). Filtro por
período (`showDateRangePicker`) e status sobre o que `HistoricoPedidosProvider` já carregou
(client-side, sem endpoint novo — mesma limitação de paginação já conhecida). Gera PDF via
`lib/services/pdf_report_service.dart` (pacote `pdf`) de um pedido específico ou do período
consolidado, e compartilha via `Printing.sharePdf` (pacote `printing`), que abre o share sheet
nativo do Android — o WhatsApp aparece como uma das opções, não é uma integração dedicada com o
WhatsApp. **100% client-side, nenhuma mudança no backend/APEX.**

Foi necessário adicionar `flutter_localizations` (o app não tinha nenhum delegate de localização
configurado) pro `showDateRangePicker` funcionar em pt_BR — isso também subiu a constraint do
`intl` para `0.20.2`.

### Armadilha encontrada: `ElevatedButton` com o tema global dentro de um `Row`

O tema (`AppTheme.light`, `lib/core/theme/app_theme.dart`) define
`elevatedButtonTheme: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(56))` — pensado pros
botões de largura total que são filho único de uma `Column` (ex.: "Próximo Passo", "Confirmar
Pedido"). `Size.fromHeight(56)` na prática define **largura mínima infinita**. Um `ElevatedButton`
sem esse tema sobrescrito, colocado como filho não-flexível de um `Row` (ex.: ao lado de um
`Expanded`), recebe largura máxima infinita do `Row` pra medir seu tamanho intrínseco — e a
combinação quebra `BoxConstraints.debugAssertIsValid`. O sintoma não fica isolado no botão: a
falha de layout corrompe o hit-test da tela **inteira**, e nada mais responde a toque (foi
exatamente o que o usuário reportou: "não consigo clicar em nada na tela relatório").
**Qualquer `ElevatedButton` novo que não seja filho único de largura total de uma `Column` precisa
de `style: ElevatedButton.styleFrom(minimumSize: Size(0, ALTURA))` explícito**, senão herda essa
armadilha do tema global.

### Técnica de debugging validada: rodar no celular real + monitorar o log do `flutter run`

Pra investigar "não consigo clicar em nada", rodei o app de verdade no celular Android físico do
usuário (`flutter devices` já mostra o aparelho conectado por USB, ver dispositivo `SM M625F`) via
`flutter run -d <device-id>`, sem tentar adivinhar pelo código. Como simular toques via `adb shell
input tap/text` é impreciso (precisa printar tela, calcular coordenadas, e um toque errado pode
sair do app sem pilha de navegação pra voltar — aconteceu nessa sessão), a abordagem que funcionou
de verdade foi: deixar o **usuário** interagir manualmente no celular, e eu só monitorar o log do
processo `flutter run` (grep por `exception|error|RenderFlex|Cannot hit test`) em tempo real — o
stack trace apareceu no console assim que o usuário tocou na tela, apontando a linha exata
(`relatorios_screen.dart:271`). **Repetir esse padrão** em bugs futuros de "não responde a
toque"/comportamento visual estranho: rodar no dispositivo real + monitorar o log, em vez de tentar
automatizar toques via `adb` (que só serve bem pra fluxos determinísticos tipo login, não pra
diagnóstico exploratório).

## Bug conhecido pendente (prioridade alta)

- **`POST /pedidos_completo`** (`backend/oracle/02_ords_endpoint_pedidos_completo.sql`) não seta
  `:status_code := 400` no bloco `EXCEPTION` — mesmo bug que foi corrigido no cancelamento de
  pedido pelo script `08_corrige_erro_handling_cancelar_pedido.sql`. Hoje, um erro de negócio
  nesse endpoint (ex.: `ORA-20001`, estoque insuficiente) pode devolver **HTTP 200**, e o app
  Flutter (`ApiService._mapError`) trata como sucesso mesmo o pedido não tendo sido criado
  corretamente.
- Correção: script `backend/oracle/10_corrige_erro_handling_pedidos_completo.sql`, criado em
  2026-08-20, replica o padrão `:status_code := 400` + `{"error": SQLERRM}` do script `08`.
  Confirmado que **não precisa de nenhuma mudança no Flutter** — `ApiService._extractMessage`
  (`lib/services/api_service.dart:86`) já lê a chave `error`, e `_mapError` já trata
  especificamente `ORA-20001` extraindo a mensagem de estoque insuficiente.
- Status em 2026-08-20: **script criado, mas ainda não aplicado nem testado**. Precisa que o
  usuário rode o script manualmente no SQL Workshop do workspace `erp_rafaellourenco` (Claude não
  tem acesso direto ao banco Oracle), depois testar o cenário de estoque insuficiente **pelo app**
  (não só Postman) — esse caminho nunca foi exercitado de verdade.

## Ambiente Oracle APEX (App Builder) — versão 26.1.3

Ferramenta hospedada em oracleapex.com, workspace `erp_rafaellourenco`, app `Application 166105`.
Diferente da API ORDS (documentada em `backend/oracle/`), aqui é o editor visual de páginas (o
"App Builder"/"Page Designer"). Estado das telas criadas ali **não fica neste repositório** — só
o que for schema/API (tabelas, triggers, procedures, handlers ORDS) é versionado em
`backend/oracle/`.

**2026-08-19: criada a skill de projeto
[`apex-ui-guide`](../.claude/skills/apex-ui-guide/SKILL.md)** especificamente pra isso — depois de
eu (Claude) dar instruções erradas de navegação do App Builder por suposição/memória várias vezes
seguidas nessa sessão, o usuário pediu pra parar de adivinhar e criar algo que force verificação
via documentação oficial ou print confirmado. A partir de agora, qualquer dúvida de navegação do
App Builder/Page Designer deve passar por essa skill (que mantém um mapa de UI confirmado, com
fonte e data, em `docs/UI_MAP.md` dentro dela) em vez de responder de memória aqui.

## Convenção de nomenclatura de páginas no APEX App Builder

**Confirmado por print da lista real de páginas do app (Application 166105) em 2026-08-19.** Para
cada tabela com CRUD, existem duas páginas adjacentes:

| Page N (listagem) | Alias | Tipo | Page N+1 (form) | Alias | Tipo |
|---|---|---|---|---|---|
| `Clientes` | `clientes` | Interactive Report | `Form_Clientes` | `form-clientes` | DML Form |
| `Produtos` | `produtos` | Interactive Report | `Form_Produtos` | `form-produtos` | DML Form |
| `Pedidos` | `pedidos` | Interactive Report | `Form_Pedidos` | `form-pedidos` | DML Form |
| `Itens_Pedido` | `itens-pedido` | Interactive Report | `Form_Itens_Pedido` | `form-itens-pedido` | DML Form |
| `Fornecedores` | `fornecedores` | Interactive Report | `Form_Fornecedores` | `form-fornecedores` | DML Form |

Regra deduzida: **Page Name** = nome da tabela em Title Case, underscore mantido se a tabela tiver
underscore (ex.: `ITENS_PEDIDO` → `Itens_Pedido`), sem acentos. **Alias** = mesma coisa em
lowercase-kebab-case (underscore vira hífen). Página de formulário sempre prefixada com `Form_` /
`form-`. O **tipo "DML Form"** é o que aparece na coluna Type depois de criar via o componente
"Form" do wizard (ver [`apex-ui-guide`](../.claude/skills/apex-ui-guide/SKILL.md)) — não é um tipo
escolhido manualmente. Os pares ficam em **números de página adjacentes** (2/3, 4/5, 6/7, 8/9,
15/16).

Para a tabela `CAMINHOES` (sem acento no nome real, ver `backend/oracle/SCHEMA.md`), seguindo a
convenção: página de listagem = `Caminhoes` / alias `caminhoes` (Interactive Report), página de
formulário = `Form_Caminhoes` / alias `form-caminhoes` (Form/DML Form). A tentativa anterior
(`pag_caminhoes`, página 18) não seguia essa convenção e foi apagada pelo usuário em 2026-08-19.

Páginas que **não** seguem esse par (relatórios/dashboards sem CRUD direto): `Pedidos n2` (10,
Interactive Grid), `Dashboard` (11, Home), `Top Clientes - Gráfico` (12, Chart), `Pedidos n3` (13,
Interactive Report, alias `pedidos-drilldown`), `Relatório de Vendas` (17, Interactive Report).
Essas não precisam de Form par.

## Convenções combinadas com o usuário

- **2026-08-19**: a partir de agora, memórias/anotações persistentes sobre este projeto vão em
  `docs/` (versionadas no git), não só na pasta local `~/.claude/.../memory/`, justamente porque o
  projeto é acessado de duas máquinas diferentes e a pasta local não sincroniza.
- **2026-08-19**: usuário confirmou que a abordagem de usar 2 agentes `Explore` em paralelo para
  estudar Flutter + backend Oracle funcionou bem para economizar tokens — repetir esse padrão em
  levantamentos futuros de mesmo porte (evitar ler o projeto inteiro no contexto principal quando
  um subagente resolve).
