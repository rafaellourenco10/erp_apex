-- ============================================================================
-- OPCIONAL: melhora a mensagem de ORA-20001 do TRG_ATUALIZA_ESTOQUE para
-- incluir o nome do produto.
--
-- Hoje a mensagem eh: 'Estoque insuficiente. Disponivel: X, solicitado: Y'
-- Com este script passa a ser:
--   'Estoque insuficiente para "Leite Ninho 400g". Disponivel: X, solicitado: Y'
--
-- Isso e puramente cosmetico: o app JA funciona sem este script (o texto
-- atual e exibido normalmente). Aplique so se quiser a mensagem mais
-- especifica para o vendedor.
--
-- Unica mudanca em relacao ao trigger atual: a secao BEFORE EACH ROW passou
-- a buscar tambem PRODUTOS.NOME e incluir na mensagem. Todo o resto (baixa
-- de estoque em AFTER STATEMENT, logica de INSERT/UPDATE/DELETE) permanece
-- IDENTICO ao trigger original.
-- ============================================================================

CREATE OR REPLACE EDITIONABLE TRIGGER "WKSP_RAFAELLOURENCO"."TRG_ATUALIZA_ESTOQUE"
FOR INSERT OR UPDATE OR DELETE ON itens_pedido
COMPOUND TRIGGER
    TYPE t_ajuste IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_produto t_ajuste;
    v_qtd     t_ajuste;
    v_count   PLS_INTEGER := 0;

    BEFORE EACH ROW IS
        v_estoque_atual NUMBER;
        v_qtd_vendida   NUMBER;
        v_nome_produto  produtos.nome%TYPE;
    BEGIN
        IF INSERTING THEN
            v_qtd_vendida := :NEW.quantidade;
        ELSIF UPDATING THEN
            v_qtd_vendida := :NEW.quantidade - :OLD.quantidade;
        ELSE
            v_qtd_vendida := 0;
        END IF;

        IF v_qtd_vendida > 0 THEN
            SELECT estoque, nome
              INTO v_estoque_atual, v_nome_produto
              FROM produtos
             WHERE id_produto = :NEW.id_produto;

            IF v_estoque_atual < v_qtd_vendida THEN
                RAISE_APPLICATION_ERROR(
                    -20001,
                    'Estoque insuficiente para "' || v_nome_produto || '". Disponível: '
                        || v_estoque_atual || ', solicitado: ' || v_qtd_vendida
                );
            END IF;
        END IF;
    END BEFORE EACH ROW;

    AFTER EACH ROW IS
    BEGIN
        v_count := v_count + 1;
        IF INSERTING THEN
            v_produto(v_count) := :NEW.id_produto;
            v_qtd(v_count) := -:NEW.quantidade;
        ELSIF UPDATING THEN
            v_produto(v_count) := :NEW.id_produto;
            v_qtd(v_count) := :OLD.quantidade - :NEW.quantidade;
        ELSIF DELETING THEN
            v_produto(v_count) := :OLD.id_produto;
            v_qtd(v_count) := :OLD.quantidade;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        FOR i IN 1 .. v_count LOOP
            UPDATE produtos SET estoque = estoque + v_qtd(i) WHERE id_produto = v_produto(i);
        END LOOP;
    END AFTER STATEMENT;
END trg_atualiza_estoque;
/

ALTER TRIGGER "WKSP_RAFAELLOURENCO"."TRG_ATUALIZA_ESTOQUE" ENABLE;
