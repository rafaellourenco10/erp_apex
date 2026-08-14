-- ============================================================================
-- criar_pedido_completo
--
-- Cria o cabecalho do pedido e todos os seus itens em UMA UNICA transacao.
-- Se qualquer item falhar (ex.: estoque insuficiente -> ORA-20001 disparado
-- pelo trigger existente em ITENS_PEDIDO), a transacao inteira eh revertida:
-- nenhum pedido "orfao" fica gravado no banco.
--
-- Substitui, do lado do banco, o fluxo atual do app que fazia:
--   POST /pedidos          (cria cabecalho)
--   POST /itens_pedido x N (um item por vez, sem transacao entre eles)
--
-- Rode este script em: SQL Workshop > SQL Commands, no workspace
-- erp_rafaellourenco.
-- ============================================================================

CREATE OR REPLACE PROCEDURE criar_pedido_completo (
    p_payload_json IN  CLOB,     -- corpo JSON recebido pelo endpoint REST
    p_id_pedido    OUT NUMBER    -- id do pedido gerado, devolvido ao chamador
) IS
    v_id_cliente NUMBER;
BEGIN
    -- 1) le o id_cliente do payload
    --    payload esperado: { "id_cliente": 1, "itens": [ {id_produto, quantidade, preco_unitario}, ... ] }
    SELECT JSON_VALUE(p_payload_json, '$.id_cliente')
      INTO v_id_cliente
      FROM dual;

    IF v_id_cliente IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'id_cliente e obrigatorio.');
    END IF;

    -- 2) cria o cabecalho do pedido
    -- AJUSTE: se PEDIDOS.status ou PEDIDOS.data_pedido ja tem DEFAULT/trigger
    -- proprios, pode remover essas colunas do INSERT abaixo (nao ha problema
    -- em manter tambem, contanto que o valor bata com o default).
    INSERT INTO pedidos (id_cliente, data_pedido, status)
    VALUES (v_id_cliente, SYSDATE, 'PENDENTE')
    RETURNING id_pedido INTO p_id_pedido;

    -- 3) insere cada item do array "itens"
    -- Cada INSERT aqui dispara os triggers ja existentes em ITENS_PEDIDO:
    --   TRG_ATUALIZA_ESTOQUE       -> valida/baixa estoque (gera ORA-20001)
    --   TRG_ATUALIZA_TOTAL_PEDIDO  -> recalcula PEDIDOS.valor_total sozinho
    -- (confirmado em USER_TRIGGERS para a tabela ITENS_PEDIDO — por isso o
    -- UPDATE manual de valor_total foi removido: seria redundante.)
    FOR item IN (
        SELECT jt.id_produto, jt.quantidade, jt.preco_unitario
          FROM JSON_TABLE(
                 p_payload_json, '$.itens[*]'
                 COLUMNS (
                     id_produto     NUMBER PATH '$.id_produto',
                     quantidade     NUMBER PATH '$.quantidade',
                     preco_unitario NUMBER PATH '$.preco_unitario'
                 )
               ) jt
    )
    LOOP
        INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario)
        VALUES (p_id_pedido, item.id_produto, item.quantidade, item.preco_unitario);
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;  -- propaga o erro original (ex.: ORA-20001) para o ORDS/app
END criar_pedido_completo;
/

-- ----------------------------------------------------------------------------
-- AJUSTE (opcional, mas recomendado): mensagem do ORA-20001 com nome do produto
--
-- No fluxo antigo, era o app Flutter que sabia dizer qual produto tinha
-- estoque insuficiente, porque enviava um item por vez. Com o envio em lote,
-- so o banco sabe qual item da lista falhou. Se o trigger TRG_ATUALIZA_ESTOQUE
-- (em ITENS_PEDIDO) hoje faz algo como:
--
--   RAISE_APPLICATION_ERROR(-20001, 'Estoque insuficiente.');
--
-- considere ajusta-lo para incluir o nome do produto, por exemplo:
--
--   DECLARE
--     v_nome    produtos.nome%TYPE;
--     v_estoque produtos.estoque%TYPE;
--   BEGIN
--     SELECT nome, estoque INTO v_nome, v_estoque
--       FROM produtos WHERE id_produto = :NEW.id_produto;
--
--     IF :NEW.quantidade > v_estoque THEN
--       RAISE_APPLICATION_ERROR(
--         -20001,
--         'ORA-20001: Estoque insuficiente para o produto "' || v_nome || '".'
--       );
--     END IF;
--
--     UPDATE produtos SET estoque = estoque - :NEW.quantidade
--      WHERE id_produto = :NEW.id_produto;
--   END;
--
-- O app (ApiService) ja foi atualizado para exibir essa mensagem tal como o
-- banco a devolver, em vez de um texto generico fixo.
-- ----------------------------------------------------------------------------
