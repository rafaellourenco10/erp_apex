-- ============================================================================
-- cancelar_pedido
--
-- Cancela um pedido com status PENDENTE: devolve o estoque de cada item e
-- muda o status para CANCELADO. Os itens do pedido NAO sao apagados --
-- continuam visiveis na tela de detalhe, so que sob um pedido cancelado.
--
-- So permite cancelar pedidos com status PENDENTE. Tentar cancelar um
-- pedido em outro status (APROVADO, FATURADO, ENTREGUE, ja CANCELADO)
-- gera erro ORA-20003.
--
-- Rode este script em: SQL Workshop > SQL Commands, no workspace
-- erp_rafaellourenco.
-- ============================================================================

CREATE OR REPLACE PROCEDURE cancelar_pedido (
    p_id_pedido IN NUMBER
) IS
    v_status pedidos.status%TYPE;
BEGIN
    SELECT status
      INTO v_status
      FROM pedidos
     WHERE id_pedido = p_id_pedido
       FOR UPDATE;

    IF UPPER(v_status) != 'PENDENTE' THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Somente pedidos com status PENDENTE podem ser cancelados. Status atual: ' || v_status || '.'
        );
    END IF;

    -- devolve o estoque de cada item do pedido (UPDATE direto em produtos;
    -- nao mexe em itens_pedido, entao os triggers TRG_ATUALIZA_ESTOQUE e
    -- TRG_ATUALIZA_TOTAL_PEDIDO nao disparam aqui -- e o comportamento
    -- desejado: nao queremos apagar os itens nem recalcular valor_total).
    FOR item IN (
        SELECT id_produto, quantidade
          FROM itens_pedido
         WHERE id_pedido = p_id_pedido
    )
    LOOP
        UPDATE produtos
           SET estoque = estoque + item.quantidade
         WHERE id_produto = item.id_produto;
    END LOOP;

    UPDATE pedidos
       SET status = 'CANCELADO'
     WHERE id_pedido = p_id_pedido;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'Pedido nao encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END cancelar_pedido;
/
