-- ============================================================================
-- Corrige o tratamento de erro de POST /erp/pedidos_completo
--
-- BUG: o handler original, em 02_ords_endpoint_pedidos_completo.sql, captura
-- QUALQUER erro (inclusive erro de negocio, ex.: ORA-20001 estoque
-- insuficiente) e devolve HTTP 200 com {"erro_debug": "ORA-20001: ..."} no
-- corpo, em vez de propagar como erro HTTP de verdade. Mesmo bug corrigido
-- em 08_corrige_erro_handling_cancelar_pedido.sql para o endpoint de
-- cancelamento -- ficou pendente aqui.
--
-- O app Flutter (ApiService._mapError, em lib/services/api_service.dart) so
-- reconhece erro quando a resposta HTTP NAO eh 2xx (eh assim que o Dio
-- dispara DioException). Uma resposta 200 com erro dentro do JSON eh tratada
-- como SUCESSO: PedidoProvider.confirmarPedido() preencheria idPedidoCriado
-- mesmo quando o pedido NAO foi criado (estoque insuficiente, payload
-- invalido, etc.), levando o vendedor pra tela de sucesso com um pedido que
-- nao existe no banco.
--
-- Padrao de correcao (mesmo do script 08, ja testado e confirmado
-- funcionando no endpoint de caminhoes e no de cancelamento): usar o bind
-- especial `:status_code` pra definir o HTTP explicitamente como 400, e
-- escrever o JSON de erro na chave `error` -- chave que
-- ApiService._extractMessage ja sabe ler (lib/services/api_service.dart:86).
-- ApiService._mapError tambem ja trata especificamente ORA-20001 dentro
-- dessa mensagem, entao nao precisa de nenhuma mudanca no app.
--
-- Este script REDEFINE o mesmo handler (mesmo module/pattern/method de
-- 02_ords_endpoint_pedidos_completo.sql), preservando a conversao de :body
-- de BLOB para CLOB (pegadinha original desse endpoint).
--
-- Rode este script em: SQL Workshop > SQL Commands, no workspace
-- erp_rafaellourenco. Seguro rodar mesmo com o handler antigo ja aplicado:
-- ORDS.DEFINE_HANDLER substitui a definicao existente para o mesmo
-- module/pattern/method.
-- ============================================================================

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'erp.api',
        p_pattern        => 'pedidos_completo',
        p_method         => 'POST',
        p_source_type    => ORDS.source_type_plsql,
        p_mimes_allowed  => 'application/json',
        p_comments       => 'Converte :body (BLOB) para CLOB e chama criar_pedido_completo. Erros de negocio viram HTTP 400 com {"error": ...}.',
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
        :status_code := 400;
        APEX_JSON.OPEN_OBJECT;
        APEX_JSON.WRITE('error', SQLERRM);
        APEX_JSON.CLOSE_OBJECT;
END;
]'
    );

    COMMIT;
END;
/

-- ============================================================================
-- Teste (Postman, NAO curl/PowerShell -- ver licao #1 do README):
--   POST https://oracleapex.com/ords/erp_rafaellourenco/erp/pedidos_completo
--   com um id_produto cuja quantidade solicitada seja maior que o estoque
--   disponivel -- esperado agora: HTTP 400 (nao mais 200), corpo
--   { "error": "ORA-20001: Estoque insuficiente. Disponivel: X, ..." }.
--   Confira tambem que NENHUM pedido foi gravado
--   (SELECT * FROM pedidos ORDER BY id_pedido DESC).
--
-- Repita o teste pelo APP tambem, nao so Postman -- esse caminho nunca foi
-- exercitado de verdade (so o caminho feliz foi testado em 2026-08-14).
-- ============================================================================
