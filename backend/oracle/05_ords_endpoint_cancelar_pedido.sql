-- ============================================================================
-- Endpoint REST: POST /erp/pedidos/:id/cancelar
--
-- Expoe a procedure cancelar_pedido (ver 04_cancelar_pedido.sql) como
-- endpoint ORDS, no modulo "erp.api" ja existente (mesmo usado por
-- /produtos, /clientes, /pedidos, /pedidos_completo, /itens_pedido).
--
-- Este endpoint NAO precisa de corpo (:body) -- o id do pedido vem da
-- propria URL. Por isso nao esbarra na pegadinha do :body vir como BLOB
-- (ver o historico de depuracao em 02_ords_endpoint_pedidos_completo.sql).
--
-- TENTE RODAR ESTE SCRIPT em SQL Workshop > SQL Commands. Se der erro de
-- privilegio no pacote ORDS, use a secao "ALTERNATIVA MANUAL" no fim deste
-- arquivo.
-- ============================================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'erp.api',
        p_pattern        => 'pedidos/:id/cancelar',
        p_comments       => 'POST: cancela um pedido PENDENTE e devolve o estoque dos itens.'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'erp.api',
        p_pattern        => 'pedidos/:id/cancelar',
        p_method         => 'POST',
        p_source_type    => ORDS.source_type_plsql,
        p_comments       => 'Chama cancelar_pedido(:id).',
        p_source         => q'[
DECLARE
    v_id_pedido NUMBER := :id;
BEGIN
    cancelar_pedido(p_id_pedido => v_id_pedido);

    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('id_pedido', v_id_pedido);
    APEX_JSON.WRITE('status', 'CANCELADO');
    APEX_JSON.CLOSE_OBJECT;
EXCEPTION
    WHEN OTHERS THEN
        APEX_JSON.OPEN_OBJECT;
        APEX_JSON.WRITE('erro_debug', SQLERRM);
        APEX_JSON.WRITE('erro_backtrace', DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        APEX_JSON.CLOSE_OBJECT;
END;
]'
    );

    COMMIT;
END;
/


-- ============================================================================
-- ALTERNATIVA MANUAL (se o script acima nao puder rodar no seu ambiente)
-- ============================================================================
--
-- 1. App Builder > SQL Workshop > RESTful Services
-- 2. Abra o modulo "erp.api" (base path "/erp/")
-- 3. Create Template
--      URI Template: pedidos/:id/cancelar
-- 4. Dentro do template, Create Handler
--      Method:        POST
--      Source Type:   PL/SQL
--      Source: o bloco DECLARE...END acima (sem os colchetes q'[ ]')
-- 5. Save / Apply Changes.
--
-- Teste (Postman, NAO curl/PowerShell -- ver licao #1 do README):
--   POST https://oracleapex.com/ords/erp_rafaellourenco/erp/pedidos/<id>/cancelar
--   (sem corpo, sem headers especiais)
-- Esperado: 200 OK, { "id_pedido": <id>, "status": "CANCELADO" }
--
-- Para testar a validacao: chame de novo com o MESMO id (agora CANCELADO)
-- -- deve vir o erro_debug "Somente pedidos com status PENDENTE podem ser
-- cancelados. Status atual: CANCELADO."
-- ============================================================================
