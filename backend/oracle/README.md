# Scripts Oracle APEX / ORDS

Scripts para aplicar manualmente no workspace `erp_rafaellourenco` (SQL Workshop → SQL Commands, ou App Builder → SQL Workshop).

**Modelo de dados completo (tabelas, colunas, FKs, triggers):** ver [`SCHEMA.md`](SCHEMA.md), extraído do dicionário de dados via [`schema_queries.sql`](schema_queries.sql).

Eu (Claude) não tenho acesso ao seu banco Oracle — esses scripts foram escritos com base no contrato de API já observado no app (`GET/POST /pedidos`, `GET/POST /itens_pedido`) e em suposições razoáveis sobre o schema. **Revise os pontos marcados com `-- AJUSTE:` antes de rodar.**

> [!STATUS] `POST /pedidos_completo` confirmado funcionando em 2026-08-14 (`id_pedido_gerado: 241`).

## ⚠️ Lições da depuração (leia antes de criar o próximo endpoint POST/PATCH)

Levamos um bom tempo pra fazer esse endpoint funcionar. Duas pegadinhas que **vão se repetir** nos próximos endpoints de escrita (autenticação, cancelamento de pedido):

1. **`curl` no Windows pode travar indefinidamente sem erro nenhum**, mesmo quando o ORDS está respondendo normalmente — parece ser um problema de renegociação TLS (`schannel: remote party requests renegotiation`) específico do `curl.exe`/`libcurl` nesse ambiente. **Teste endpoints POST/PATCH pelo Postman, não pelo `curl`/PowerShell.** Um `curl` "travado pra sempre" não significa que o backend está com problema.

2. **`:body` chega como `BLOB` (binário), não `CLOB` (texto), nos handlers PL/SQL desse ORDS** — mesmo com `Mime Types Allowed: application/json`. Tentar usar `:body` direto como `CLOB` (ex.: `v_x CLOB := :body;` ou passar `:body` pra um parâmetro `IN CLOB`) falha **na compilação** do bloco PL/SQL do handler — e como é erro de compilação, nem o `EXCEPTION WHEN OTHERS` do próprio bloco consegue capturar (o bloco nunca chega a rodar). O sintoma no cliente é sempre o mesmo erro genérico: `HTTP 555 / ORDS-25001 "User Defined Resource Error"`, sem detalhe nenhum.

   **Correção**: converter explicitamente com `DBMS_LOB.CONVERTTOCLOB` antes de usar como texto. Ver o bloco completo em `02_ords_endpoint_pedidos_completo.sql`.

3. **Erro de compilação em handler PL/SQL do ORDS sempre aparece como `555 ORDS-25001`, sem nenhum detalhe.** Pra depurar de verdade, teste incrementalmente: primeiro um bloco mínimo (`BEGIN APEX_JSON.OPEN_OBJECT; ...; END;`, sem `:body` nem chamada de procedure) pra confirmar que o handler básico funciona; depois adicione `:body` sozinho; só depois a lógica de negócio. Isso isola exatamente onde a compilação quebra.

## Ordem de aplicação

| # | Arquivo | O que faz |
|---|---|---|
| 1 | [`01_criar_pedido_completo.sql`](01_criar_pedido_completo.sql) | Cria a procedure `criar_pedido_completo`, que insere cabeçalho + itens do pedido em uma única transação (rollback automático em caso de erro, ex.: estoque insuficiente) |
| 2 | [`02_ords_endpoint_pedidos_completo.sql`](02_ords_endpoint_pedidos_completo.sql) | Registra o endpoint `POST /pedidos_completo` no módulo `erp.api` já existente, via `ORDS.DEFINE_TEMPLATE`/`DEFINE_HANDLER` — inclui a conversão de `:body` de BLOB para CLOB. Se o seu ambiente não permitir rodar esses pacotes, use as instruções manuais no fim do arquivo. |
| 3 *(opcional)* | [`03_melhorar_mensagem_estoque_OPCIONAL.sql`](03_melhorar_mensagem_estoque_OPCIONAL.sql) | Reescreve `TRG_ATUALIZA_ESTOQUE` só para incluir o nome do produto na mensagem de `ORA-20001`. Não muda comportamento — pode pular sem prejuízo. |
| 4 | [`04_cancelar_pedido.sql`](04_cancelar_pedido.sql) | Cria a procedure `cancelar_pedido`, que devolve o estoque dos itens e muda o status para `CANCELADO` — só permite cancelar pedidos `PENDENTE`. |
| 5 | [`05_ords_endpoint_cancelar_pedido.sql`](05_ords_endpoint_cancelar_pedido.sql) | Registra `POST /pedidos/:id/cancelar` no módulo `erp.api`. Não precisa de `:body` (o id vem da URL), então não esbarra na pegadinha do BLOB/CLOB. |
| 6 | [`06_criar_caminhoes.sql`](06_criar_caminhoes.sql) | Cria a tabela `CAMINHOES` (frota), com `STATUS` restrito a `LIVRE`/`EM_CARGA`/`EM_ROTA`, para o vendedor ver no dashboard do app quais caminhões estão disponíveis. |
| 7 | [`07_ords_endpoint_caminhoes.sql`](07_ords_endpoint_caminhoes.sql) | Registra `GET /caminhoes` e `POST /caminhoes/:id/status` no módulo `erp.api`. O segundo usa bind automático de `:status` a partir do corpo JSON (objeto simples/plano), sem precisar tratar `:body` como BLOB — inclui fallback comentado com `DBMS_LOB.CONVERTTOCLOB` caso o bind automático não funcione no ambiente. |
| 8 | [`08_corrige_erro_handling_cancelar_pedido.sql`](08_corrige_erro_handling_cancelar_pedido.sql) | **Corrige um bug do endpoint `/pedidos/:id/cancelar`** (já aplicado em produção): ele devolvia HTTP 200 mesmo quando a operação falhava (ex.: cancelar pedido já cancelado), porque capturava o erro e só escrevia `erro_debug` no JSON sem propagar. O app nunca reconhecia isso como erro (só reage a HTTP não-2xx) e mostrava "sucesso" indevidamente. Rode este script para substituir o handler existente pelo corrigido. |
| 10 | [`10_corrige_erro_handling_pedidos_completo.sql`](10_corrige_erro_handling_pedidos_completo.sql) | **Corrige o mesmo bug do item 8, agora em `/pedidos_completo`** — ainda não aplicado. Um erro de negócio (ex.: `ORA-20001` estoque insuficiente) hoje devolve HTTP 200 com `erro_debug` no corpo, e o app trata como pedido criado com sucesso mesmo sem nada gravado no banco. Rode este script para substituir o handler pelo corrigido (`:status_code := 400` + `{"error": SQLERRM}`, mesmo padrão do item 8). **Ainda precisa ser aplicado e testado pelo app.** |

### ⚠️ Pegadinha nova: erro de negócio precisa virar HTTP não-2xx **com a mensagem visível no corpo**

Descoberta em 2026-08-18/19, revisando e testando (pela interface, não só script) o endpoint de caminhões antes de aplicar. Duas camadas do mesmo problema:

1. Um handler que captura `WHEN OTHERS` e só escreve `{"erro_debug": ...}` no corpo, sem propagar o erro, faz o ORDS devolver **HTTP 200** — e o app Flutter (`ApiService._mapError`) só trata como erro quando o HTTP não é 2xx. Ou seja: um handler que "trata" o erro dessa forma faz o app achar que deu certo.
2. A correção óbvia (`RAISE;` no lugar de escrever o JSON) **não é suficiente neste ambiente**: testando de verdade, um erro não capturado (mesmo um `RAISE_APPLICATION_ERROR` de propósito) cai numa página HTML genérica de erro do ORDS (`555`/`ORDS-25001`), **sem expor a mensagem real em lugar nenhum visível**.

**Padrão correto, testado e confirmado funcionando** (endpoint de caminhões, 2026-08-19): dentro do `EXCEPTION`, definir explicitamente `:status_code := 400;` (bind especial do ORDS que controla o HTTP da resposta) **e** escrever o JSON de erro na chave `error` — `{"error": SQLERRM}`. Isso garante as duas coisas: HTTP não-2xx (o app reconhece como falha) e a mensagem real visível no corpo (`ApiService._extractMessage` já sabe ler a chave `error`).

Os handlers de `caminhoes` já nascem com esse padrão. `cancelar_pedido` foi corrigido no item 8 acima. **`criar_pedido_completo`/`/pedidos_completo`** tinha o mesmo bug (`erro_debug` sem propagar → HTTP 200 mesmo em erro de negócio) — corrigido no item 10 (`10_corrige_erro_handling_pedidos_completo.sql`), **ainda não aplicado nem testado pelo app**. Depois de rodar o script, testar o cenário de estoque insuficiente pelo app (não só Postman) antes de considerar fechado.

## Pré-requisitos — confirmados em 2026-08-14 via `user_tab_columns`/`user_triggers`

- ✅ `PEDIDOS(id_pedido, id_cliente, data_pedido, status, valor_total)` — nomes batem.
- ✅ `ITENS_PEDIDO(id_item, id_pedido, id_produto, quantidade, preco_unitario)` — nomes batem.
- ✅ Existem **dois** triggers em `ITENS_PEDIDO` (`INSERT OR UPDATE OR DELETE`, ambos `ENABLED`):
  - `TRG_ATUALIZA_ESTOQUE` — valida/baixa o estoque; é quem gera o `ORA-20001` hoje.
  - `TRG_ATUALIZA_TOTAL_PEDIDO` — recalcula `PEDIDOS.valor_total` sozinho.

  Por causa do segundo trigger, o `UPDATE` manual de `valor_total` que existia na primeira versão da procedure foi **removido** — seria redundante.

- ✅ **DDL de `TRG_ATUALIZA_ESTOQUE` inspecionado em 2026-08-14.** É um *compound trigger*: valida e recusa em `BEFORE EACH ROW` (`RAISE_APPLICATION_ERROR(-20001, 'Estoque insuficiente. Disponível: X, solicitado: Y')`) e aplica a baixa de estoque em `AFTER STATEMENT`, em lote por instrução. Como a procedure insere os itens em um loop de `INSERT`s individuais (uma instrução por item), o trigger dispara corretamente a cada item, na ordem — e o `ROLLBACK` da procedure desfaz também as baixas de estoque já aplicadas. **Totalmente compatível, nenhuma mudança necessária na procedure.**

  A mensagem atual não cita o nome do produto (só "Disponível: X, solicitado: Y") — isso já funciona no app, é só menos específico. Melhoria opcional em `03_melhorar_mensagem_estoque_OPCIONAL.sql`, que reescreve o trigger incluindo o nome do produto na mensagem (comportamento idêntico, fora isso).

## Depois de aplicar

**Use o Postman (ou similar), não `curl`/PowerShell** — ver lição #1 acima.

- Method: `POST`
- URL: `https://oracleapex.com/ords/erp_rafaellourenco/erp/pedidos_completo`
- Body → raw → JSON:
  ```json
  {
    "id_cliente": 1,
    "itens": [
      { "id_produto": 10, "quantidade": 2, "preco_unitario": 24.90 }
    ]
  }
  ```

Esperado: `200 OK`, `{"id_pedido_gerado": <numero>}`.

Para testar o rollback, use um `id_produto` com estoque menor que a `quantidade` pedida — a resposta deve vir com erro contendo `ORA-20001` e **nenhum** pedido/item deve ter sido gravado (confira em `SELECT * FROM pedidos ORDER BY id_pedido DESC` — não deve aparecer um pedido novo).

## Confirmado funcionando

- `POST /pedidos_completo`: `id_pedido_gerado: 241`, testado em 2026-08-14 via Postman. Rollback ainda não testado explicitamente — vale testar antes de considerar o item 100% fechado.
- `POST /pedidos/:id/cancelar`: testado em 2026-08-15 via Postman, caminho feliz e validação. Cancelar pedido `PENDENTE` → `200 OK`, `{"id_pedido": 221, "status": "CANCELADO"}`. Tentar cancelar de novo o mesmo pedido (já `CANCELADO`) → `ORA-20003: Somente pedidos com status PENDENTE podem ser cancelados. Status atual: CANCELADO.` Funcionou de primeira, sem precisar do processo de depuração do item anterior.
