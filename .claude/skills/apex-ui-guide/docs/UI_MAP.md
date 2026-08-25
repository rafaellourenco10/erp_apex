# Mapa de UI confirmado — Oracle APEX App Builder (erp_apex)

Cada entrada: **elemento** → onde fica / o que faz → **como foi confirmado** (fonte) → data.
Mantenha isso atualizado sempre que algo novo for verificado — é o que evita adivinhação.

## Create a Page — abas do assistente

**Confirmado por print do usuário em 2026-08-19.** Nessa versão (26.1.3) NÃO existe mais a opção
combinada "Report and Form" que existia em versões antigas do APEX. O assistente "Create a Page"
tem 3 abas:

- **Component**: Blank Page, Calendar, Cards, Chart, Classic Report, Comments, Content Row,
  Dashboard, Data Loading, Faceted Search, Form, Interactive Grid, Interactive Report, Map,
  Master Detail, Media List, Search Page, Smart Filters, Timeline, Tree, Unified Task List,
  Wizard, Workflow Console.
- **Feature**: Push Notifications, About Page, Access Control, Activity Reporting, Configuration
  Options, Email Reporting, Feedback, Login Page, Theme Style Selection.
- **Legacy**: Form on a Local Procedure, Summary Page, Legacy Data Loading.

Para listagem + cadastro/edição de uma tabela: não tem mais um tile único que já cria os dois.
Caminho: criar **Interactive Report** apontando pra tabela, depois criar **Form** separado
(também apontando pra tabela, ele detecta a Primary Key), e ligar os dois manualmente (link/botão
na linha do relatório levando pro form). **Ainda não confirmado por print** se o wizard do
Interactive Report oferece, em algum passo, uma opção pra já gerar o Form junto — verificar ao
vivo da próxima vez que o usuário estiver nesse wizard.

## Region (dentro do Page Designer) — propriedades de Source

**Confirmado por print do usuário em 2026-08-19.** Ao clicar na região de um Interactive Report
(não no nó da página, no nó da região dentro de "Body" na árvore), o painel direito mostra abas
**Region / Attributes / Printing**, e dentro de "Region" tem as seções **Identification**
(Name, Title, Type) e **Source** (Location, Type, Table Owner, Table Name, Include ROWID Column,
Where Clause, Order By Clause, Page Items to Submit, Optimizer Hint). Pra confirmar que um
Interactive Report está puxando a tabela certa: `Source > Type = Table/View` e
`Source > Table Name = <NOME_DA_TABELA>`.

## Page Designer — barra de ferramentas superior

**Confirmado via documentação oficial (APEX 24.1) em 2026-08-19 — ainda não confirmado por print
no ambiente 26.1.3 do usuário**, tratar como muito provável mas não 100% garantido até confirmar.

Ordem da esquerda pra direita: Page Selector → Show Messages (sino) → Page Locked/Unlocked
(cadeado) → Undo → Redo → Create (ícone "+") → **Utilities (ícone de chave inglesa 🔧)** →
Shared Components → Save → Save and Run Page.

Fontes:
- https://docs.oracle.com/en/database/oracle/apex/24.1/htmdb/page-designer-toolbar.html
- https://docs.oracle.com/en/database/oracle/apex/24.1/htmdb/deleting-pages-in-page-designer.html

## Deletar uma página

**Confirmado via documentação oficial (APEX 24.1) em 2026-08-19.**

1. Abrir a página no Page Designer.
2. Clicar no ícone **Utilities** (chave inglesa 🔧, na barra superior da Page Designer).
3. Clicar em **Delete Page**.
4. Na tela "Confirm Page Delete", clicar em **Permanently Delete Page**.

Alternativa pra apagar várias páginas de uma vez (a partir da Application Home, sem entrar em
cada página): **Application → Utilities → Cross Page Utilities → Delete Multiple Pages** (ou
"Delete Pages by Range").

⚠️ **Não confundir** com o ícone **☰▾** que fica do lado do nome da página dentro da árvore de
componentes, no painel esquerdo (ex.: ao lado de "Page 18: pag_caminhoes"). Esse é um menu
diferente, de navegação da árvore, e contém apenas: **Expand All Below**, **Collapse All Below**,
**Comment Out**. Confirmado por print do usuário em 2026-08-19 (foi o erro cometido antes de
corrigir).

## Application Home (lista de páginas do app, "View Report")

**Confirmado por print do usuário + documentação oficial em 2026-08-19.**

Colunas visíveis: número da página, nome, alias, "atualizado há", autor, tipo de página
(Interactive Report, Form, DML Form, Interactive Grid, Chart, Home, Login, etc.), grupo
("Unassigned" quando não agrupada), e dois ícones no fim de cada linha: **cadeado** (lock/unlock
da página) e **play ▶** (Run — abre a página renderizada).

- Clicar com o **botão direito** numa linha abre o menu de contexto do **navegador** (Chrome),
  não um menu do APEX — não serve pra ações do APEX.
- Segundo a documentação oficial, **não existe exclusão direta de página por essa lista** — só
  via Page Designer (ver acima) ou via Cross Page Utilities.

## Campo "Alias" (Page Designer, seção Identification) — força maiúsculo

**Confirmado por observação direta do usuário em 2026-08-19** (mais confiável que a busca que fiz
antes, que trouxe resultado contraditório/desatualizado sobre isso). Nesse ambiente (26.1.3), o
campo **Alias** de uma página **força automaticamente maiúsculo** conforme se digita — não dá pra
deixar em minúsculo manualmente. Isso é diferente do que aparece na lista de páginas da
Application Home, onde os aliases das páginas antigas do projeto (`clientes`, `produtos`,
`form-clientes` etc.) mostram em minúsculo — provável explicação: ou foram criadas numa condição
diferente, ou a lista só exibe estilizado em minúsculo independente do valor real armazenado. **Não
é um problema a corrigir** — o roteamento por alias no APEX não é case-sensitive, então a
inconsistência visual não afeta funcionamento. Não perder tempo tentando forçar minúsculo nesse
campo.

## Inventário de páginas — Application 166105 (Application Home, "View Report")

**Confirmado por print do usuário em 2026-08-24.** Lista completa das páginas do app, na ordem em
que aparecem na Application Home:

| # | Nome | Alias | Tipo |
|---|---|---|---|
| 0 | Global Page | — | Global Page |
| 1 | Home | `home` | Static HTML |
| 2 | Clientes | `clientes` | Interactive Report |
| 3 | Form_Clientes | `form-clientes` | DML Form |
| 4 | Produtos | `produtos` | Interactive Report |
| 5 | Form_Produtos | `form-produtos` | DML Form |
| 6 | Pedidos | `pedidos` | Interactive Report |
| 7 | Form_Pedidos | `form-pedidos` | DML Form |
| 8 | Itens_Pedido | `itens-pedido` | Interactive Report |
| 9 | Form_Itens_Pedido | `form-itens-pedido` | DML Form |
| 10 | Pedidos n2 | `pedido` | Interactive Grid |
| 11 | Dashboard | `dashboard` | Home |
| 12 | Top Clientes - Gráfico | `top-clientes-gráfico` | Chart |
| 13 | Pedidos n3 | `pedidos-drilldown` | Interactive Report |
| 14 | Itens do Pedido | `itens-do-pedido` | DML Form |
| 15 | Fornecedores | `fornecedores` | Interactive Report |
| 16 | Form_Fornecedores | `form-fornecedores` | DML Form |
| 17 | Relatório de Vendas | `relatório-de-vendas` | Interactive Report |
| 20 | Caminhoes | `caminhoes` | Interactive Report |
| 22 | Form_Caminhoes | `form-caminhoes` | DML Form |
| 9999 | Login Page | `login` | Login |

Padrão de nomenclatura observado: cada tabela tem uma **Interactive Report** de listagem + um
**Form_<Tabela>** (DML Form) de cadastro/edição — mesmo padrão descrito acima em "Create a Page".
As páginas fora desse padrão (10, 13, 14, 17) parecem ter sido criadas por fora do fluxo
IR+Form padrão, provavelmente pra necessidades específicas (dashboard, drilldown, relatório).

> [!bug] Nomes enganosos nas páginas 13 e 14 — confirmado por print em 2026-08-24
> **Página 13 "Pedidos n3"** (título renderizado "Pedidos_DrillDown", alias `pedidos-drilldown`,
> Interactive Report): apesar do nome, é só **mais uma listagem geral de PEDIDOS**, idêntica em
> forma à página 6 "Pedidos" (colunas Id Cliente, Data Pedido, Status, Valor Total + botão
> Create + lápis de editar por linha) — sem filtro por pedido específico, sem mostrar itens,
> sem nenhum drilldown de verdade implementado ainda.
>
> **Página 14 "Itens do Pedido"** (breadcrumb "Pedidos_DrillDown \ Itens do Pedido", alias
> `itens-do-pedido`, DML Form): apesar do nome sugerir uma lista de itens, é na verdade o
> **"Form on PEDIDOS"** — formulário de criar/editar o **cabeçalho** do pedido (Id Cliente, Data
> Pedido, Status, Valor Total). É pra onde o lápis de editar da página 13 leva. **Não mostra
> ITENS_PEDIDO nenhum.**
>
> **Correção da conclusão acima (o print inicial só mostrava a metade de cima da página 14):**
> rolando a página 14 pra baixo, ela **tem sim** uma segunda região (Interactive Grid) com os
> itens do pedido — colunas Id Produto, Quantidade, Preço Unitário — abaixo do formulário de
> cabeçalho. É um **Master-Detail Form** de verdade (PEDIDOS = master, ITENS_PEDIDO = detail),
> só que o nome da página ("Itens do Pedido") descreve só a parte de baixo, o que confundiu.
>
> **Confirmado no Page Designer da página 14 (print do usuário, 2026-08-24):** dentro da região
> "Form on PEDIDOS" existe o item oculto **`P14_ID_PEDIDO`** — `Type: Hidden`, `Primary Key: ON`,
> `Query Only: ON`, ligado à coluna `ID_PEDIDO`. É o item padrão de formulário-por-registro do
> APEX: setar esse item (via URL/`Set Items` de um Link) faz a página abrir **direto no pedido
> certo** (cabeçalho + itens), sem precisar navegar pelo "5 of 8" (`Previous`/`Next`/`X of Y` são
> só navegação manual entre registros quando `P14_ID_PEDIDO` não é setado por fora).
>
> **Conclusão corrigida: a página 14 já serve como destino do link do Relatório de Vendas — não
> precisa criar página nova.** Falta só (a) confirmar que `ID_PEDIDO` está disponível na query da
> página 17 pra usar no link, e (b) resolver a impressão (página 14 não parece ter um botão de
> imprimir ainda) e opcionalmente tornar a página só-leitura pra esse fluxo (ela hoje tem
> Add Row/Delete/Apply Changes, arriscado num link de "consulta").
>
> **✅ Implementado e testado em 2026-08-24**: coluna `CLIENTE` da página 17 virou `Type: Link`
> (Identification) → Link Builder → `Page in this Application` = 14, `Set Items`:
> `P14_ID_PEDIDO = ID_PEDIDO` (valor escolhido no dropdown de colunas do relatório, não digitado à
> mão). Confirmado pelo usuário: clicar no nome do cliente no Relatório de Vendas agora abre a
> página 14 já no pedido certo. **Falta só a Fase C (botão de imprimir na página 14).**

## Criar um Page Item novo ligado a uma coluna de tabela (dentro de um Form region)

**Confirmado por print do usuário + documentação oficial em 2026-08-25**, ao adicionar campos
novos (CPF/CNPJ, endereço) no `Form_Clientes` (página 3) depois de um `ALTER TABLE`.

Diferente do que a primeira suposição indicava: **criar o item via "Create Page Item" não liga
ele à tabela sozinho.** Depois de criado, o item vem com a seção **Source** assim:
`Form Region: - Select -`, `Type: Null` — precisa configurar manualmente, **nessa ordem**:

1. **Source → Form Region**: escolher a região do formulário (ex.: `Form_Clientes`, ou
   `Form on PEDIDOS` em outras páginas — o nome varia por página, conferir na árvore).
2. **Source → Type**: mudar de `Null` para **`Database Column`**.
3. Só depois desse passo aparece o campo **Column**, populado com as colunas da tabela por trás
   da região — aí sim escolhe a coluna certa (ex.: `CPF_CNPJ`).

Pular o passo 2 (deixar `Type: Null`) é o motivo mais provável de "não encontrar a coluna no
dropdown" — o campo `Column` nem existe ainda nesse estado, não é falta da coluna na tabela.

## Pendências a confirmar (próxima vez que o usuário estiver na tela)

- Confirmar por print se a barra de ferramentas da Page Designer no 26.1.3 é idêntica à
  documentada pra 24.1 (posição exata do ícone Utilities).
- Confirmar visualmente onde fica "Application → Utilities" (o menu geral do app, fora da Page
  Designer) nessa versão.
- ~~Confirmar se o wizard "Interactive Report" oferece, nalgum passo, a opção de já criar o Form
  de edição junto~~ — **respondido via doc oficial (24.1) em 2026-08-24**: sim, existe um flag
  **"Include Form Page"** dentro do próprio wizard de Interactive Report (passo de definição da
  página, junto com Page Number/Name/Page Mode) — não é mais um tile separado "Report and Form",
  mas o resultado final é parecido: marcar essa opção cria um form (sempre como Modal Dialog) além
  do relatório. Ainda não confirmado por print no 26.1.3 do usuário se o nome/posição do campo é
  idêntico.

## Create Page wizard — Interactive Report, passo a passo

**Confirmado via documentação oficial (APEX 24.1) em 2026-08-24** — fonte:
https://docs.oracle.com/en/database/oracle/apex/24.1/htmdb/creating-an-interactive-report-using-the-create-page-wizard.html
Ainda não confirmado por print no 26.1.3.

1. Application Home → botão **Create Page** (canto superior direito).
2. Aba **Component** → tile **Interactive Report**.
3. Tela de definição: **Page Number** (a próxima página livre já vem sugerida), **Name** (nome/
   título da página — dá pra mudar depois no Page Designer), **Page Mode**, e um flag **Include
   Form Page** (cria também um form de edição, como Modal Dialog — não usar quando só se quer um
   relatório de leitura).
4. **Data Source**: Local Database (é o caso deste projeto, banco Oracle direto) vs REST Enabled
   SQL Service vs REST Data Source.
5. **Source Type**: `Table` (escolher Table/View Owner + Table/View Name) ou `SQL Query` (escrever
   um `SELECT` manual — necessário quando o relatório precisa de `WHERE`/JOIN definidos já na
   criação, embora dê pra editar isso depois no Page Designer também).
6. **Navigation** (região expansível): **Use Breadcrumb** e **Use Navigation** (cria entrada no
   menu lateral) — ambos usam o nome da página por padrão.
7. Botão **Create Page** finaliza.
