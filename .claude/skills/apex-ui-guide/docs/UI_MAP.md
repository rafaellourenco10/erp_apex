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

## Pendências a confirmar (próxima vez que o usuário estiver na tela)

- Confirmar por print se a barra de ferramentas da Page Designer no 26.1.3 é idêntica à
  documentada pra 24.1 (posição exata do ícone Utilities).
- Confirmar visualmente onde fica "Application → Utilities" (o menu geral do app, fora da Page
  Designer) nessa versão.
- Confirmar se o wizard "Interactive Report" (Create a Page → Component) oferece, nalgum passo, a
  opção de já criar o Form de edição junto (substituindo o antigo "Report and Form").
