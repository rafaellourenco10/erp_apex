-- ============================================================================
-- Endpoint REST: POST /erp/pedidos_completo
--
-- Expoe a procedure criar_pedido_completo (ver 01_criar_pedido_completo.sql)
-- como um endpoint ORDS.
--
-- HISTORICO (2026-08-14): a primeira tentativa deste script tentava criar um
-- MODULO NOVO ("erp.pedidos.completo") com base_path '/erp/', o que falhou
-- com ORA-00001 (ORDS_UNIQUE_PREFIX_UC) porque ja existe um modulo chamado
-- "erp.api" usando esse mesmo base_path (o que expoe /produtos, /clientes,
-- /pedidos, /itens_pedido). A versao abaixo usa o modulo EXISTENTE.
--
-- TENTE RODAR ESTE SCRIPT em SQL Workshop > SQL Commands. Se der erro de
-- privilegio no pacote ORDS, use a secao "ALTERNATIVA MANUAL" no fim deste
-- arquivo.
-- ============================================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'erp.api',
        p_pattern        => 'pedidos_completo',
        p_comments       => 'POST: cria pedido + itens em transacao unica.'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'erp.api',
        p_pattern        => 'pedidos_completo',
        p_method         => 'POST',
        p_source_type    => ORDS.source_type_plsql,
        p_mimes_allowed  => 'application/json',
        p_comments       => 'Converte :body (BLOB) para CLOB e chama criar_pedido_completo.',
        p_source         => q'[
DECLARE
    v_body_clob   CLOB;
    v_dest_offset INTEGER := 1;
    v_src_offset  INTEGER := 1;
    v_lang_ctx    INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
    v_warning     INTEGER;
    v_id_pedido   NUMBER;
BEGIN
    -- :body chega como BLOB neste ORDS (nao CLOB) -- precisa converter
    -- explicitamente antes de tratar como texto/JSON.
    DBMS_LOB.CREATETEMPORARY(v_body_clob, TRUE);
    DBMS_LOB.CONVERTTOCLOB(
        dest_lob     => v_body_clob,
        src_blob     => :body,
        amount       => DBMS_LOB.LOBMAXSIZE,
        dest_offset  => v_dest_offset,
        src_offset   => v_src_offset,
        blob_csid    => NLS_CHARSET_ID('AL32UTF8'),
        lang_context => v_lang_ctx,
        warning      => v_warning
    );

    criar_pedido_completo(
        p_payload_json => v_body_clob,
        p_id_pedido    => v_id_pedido
    );

    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('id_pedido_gerado', v_id_pedido);
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
--      URI Template: pedidos_completo
-- 4. Dentro do template, Create Handler
--      Method:        POST
--      Source Type:   PL/SQL
--      Mimes Allowed: application/json
--      Source: o bloco DECLARE...END acima (sem os colchetes q'[ ]')
-- 5. Save / Apply Changes.
--
-- Resultado esperado: POST para
--   https://oracleapex.com/ords/erp_rafaellourenco/erp/pedidos_completo
-- com corpo:
--   { "id_cliente": 1, "itens": [ {"id_produto":10,"quantidade":2,"preco_unitario":24.9} ] }
-- devolve:
--   { "id_pedido_gerado": <numero> }
--
-- Confirmado funcionando em 2026-08-14 (id_pedido_gerado: 241).
-- ============================================================================
