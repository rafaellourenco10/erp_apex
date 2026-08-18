# Modelo de dados — workspace `erp_rafaellourenco` (Oracle APEX 26.1.3)

Extraído do dicionário de dados (`user_tab_columns`, `user_constraints`, `user_triggers`) em 2026-08-18. Ver os comandos usados em [`schema_queries.sql`](schema_queries.sql).

> Ignorar nas consultas ao dicionário de dados: `DEPT`, `EMP` (schema de exemplo `SCOTT`, vem por padrão em muitos workspaces Oracle) e `HTMLDB_PLAN_TABLE` (tabela interna do APEX, usada pela função "Explain Plan" do SQL Commands). Nenhuma das três pertence ao ERP.

## Diagrama de relacionamentos

```
CLIENTES ──< PEDIDOS ──< ITENS_PEDIDO >── PRODUTOS >── FORNECEDORES
 (1)          (N)            (N)            (1)           (1)
```

- Um cliente tem vários pedidos.
- Um pedido tem vários itens.
- Um item de pedido referencia um produto.
- Um produto pertence a um fornecedor.

## Tabelas

### CLIENTES
| Coluna | Tipo | Obrigatório | Chave |
|---|---|---|---|
| ID_CLIENTE | NUMBER | sim | PK |
| NOME | VARCHAR2(100) | sim | |
| EMAIL | VARCHAR2(100) | não | |
| TELEFONE | VARCHAR2(20) | não | |
| DATA_CADASTRO | DATE | não | |

### PRODUTOS
| Coluna | Tipo | Obrigatório | Chave |
|---|---|---|---|
| ID_PRODUTO | NUMBER | sim | PK |
| NOME | VARCHAR2(150) | sim | |
| DESCRICAO | VARCHAR2(500) | não | |
| PRECO | NUMBER(10,2) | sim | |
| ESTOQUE | NUMBER | não | |
| DATA_CADASTRO | DATE | não | |
| ESTOQUE_MINIMO | NUMBER | não | |
| ID_FORNECEDOR | NUMBER | não | FK → `FORNECEDORES.ID_FORNECEDOR` |

### FORNECEDORES
| Coluna | Tipo | Obrigatório | Chave |
|---|---|---|---|
| ID_FORNECEDOR | NUMBER | sim | PK |
| NOME | VARCHAR2(150) | sim | |
| CNPJ | VARCHAR2(18) | não | |
| TELEFONE | VARCHAR2(20) | não | |
| EMAIL | VARCHAR2(150) | não | |
| CIDADE | VARCHAR2(100) | não | |
| UF | VARCHAR2(2) | não | |
| ATIVO | VARCHAR2(1) | sim | |
| DATA_CADASTRO | DATE | não | |

### PEDIDOS
| Coluna | Tipo | Obrigatório | Chave |
|---|---|---|---|
| ID_PEDIDO | NUMBER | sim | PK |
| ID_CLIENTE | NUMBER | sim | FK → `CLIENTES.ID_CLIENTE` |
| DATA_PEDIDO | DATE | não | |
| STATUS | VARCHAR2(20) | não | valores observados: `PENDENTE`, `APROVADO`, `CANCELADO` |
| VALOR_TOTAL | NUMBER(10,2) | não | recalculado automaticamente por trigger, ver abaixo |

### ITENS_PEDIDO
| Coluna | Tipo | Obrigatório | Chave |
|---|---|---|---|
| ID_ITEM | NUMBER | sim | PK |
| ID_PEDIDO | NUMBER | sim | FK → `PEDIDOS.ID_PEDIDO` |
| ID_PRODUTO | NUMBER | sim | FK → `PRODUTOS.ID_PRODUTO` |
| QUANTIDADE | NUMBER | sim | |
| PRECO_UNITARIO | NUMBER(10,2) | sim | |

## Triggers

Só existem triggers em `ITENS_PEDIDO` (ambos `ENABLED`, disparam em `INSERT OR UPDATE OR DELETE`):

- **`TRG_ATUALIZA_ESTOQUE`** — valida e baixa o estoque de `PRODUTOS` a cada item inserido/alterado/removido. Recusa a operação com `ORA-20001` se a quantidade pedida for maior que o estoque disponível. Documentado em detalhe em [`README.md`](README.md).
- **`TRG_ATUALIZA_TOTAL_PEDIDO`** — recalcula `PEDIDOS.VALOR_TOTAL` sozinho sempre que os itens do pedido mudam. Por isso as procedures do backend (ex. `criar_pedido_completo`) **não devem** atualizar `VALOR_TOTAL` manualmente — seria redundante e pode conflitar com o trigger.

`CLIENTES`, `PRODUTOS`, `FORNECEDORES` e `PEDIDOS` não têm triggers próprios.
