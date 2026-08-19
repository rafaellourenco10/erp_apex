-- ============================================================================
-- Endpoints REST: GET /erp/caminhoes  e  POST /erp/caminhoes/:id/status
--
-- Expoe a tabela CAMINHOES (ver 06_criar_caminhoes.sql) no modulo "erp.api"
-- ja existente (mesmo usado por /produtos, /clientes, /pedidos,
-- /pedidos_completo, /itens_pedido, /pedidos/:id/cancelar).
--
-- NOTA: esses dois endpoints foram construidos e testados pela INTERFACE do
-- APEX (SQL Workshop > RESTful Services), nao rodando este script. Este
-- arquivo existe como referencia/backup caso a interface de algum motivo
-- nao funcione. Duas coisas foram aprendidas testando na pratica em
-- 2026-08-19, que valem tanto pro script quanto pra interface:
--
-- 1) BIND AUTOMATICO DE PROPRIEDADE JSON NAO FUNCIONA NESSE AMBIENTE.
--    A ideia original era deixar o ORDS ler {"status": "EM_ROTA"} e
--    preencher uma variavel :status sozinho (sem tratar :body como BLOB).
--    Na pratica isso deu erro de compilacao silencioso (555/ORDS-25001).
--    Solucao: ler o :body manualmente (BLOB -> CLOB -> JSON_VALUE), mesmo
--    padrao ja usado em 02_ords_endpoint_pedidos_completo.sql. Isso exige
--    "Mimes Allowed: application/json" configurado no handler POST.
--
-- 2) UM RAISE_APPLICATION_ERROR "ESTOURADO" (sem ser capturado) CAI NUMA
--    PAGINA GENERICA DE ERRO DO ORDS (555/ORDS-25001) SEM EXPOR A MENSAGEM.
--    Isso e diferente do que documentamos antes para /pedidos_completo.
--    Solucao testada e confirmada: dentro do EXCEPTION, definir o bind
--    especial `:status_code := 400;` (controla o HTTP da resposta) E
--    escrever nosso proprio JSON com a mensagem em `error`. Isso da os dois
--    lados: HTTP nao-2xx (o app Flutter reconhece como falha via Dio) E a
--    mensagem real visivel no corpo -- "error" e uma das chaves que
--    ApiService._extractMessage (lib/services/api_service.dart) ja sabe
--    ler. NAO usar so `RAISE;` (silenciosamente esconde a mensagem aqui) e
--    NAO usar so escrever o JSON sem `:status_code` (aí o HTTP fica 200 e o
--    app Flutter acha que deu certo -- era o bug original desse endpoint e
--    do /pedidos/:id/cancelar, ver 08_corrige_erro_handling_cancelar_pedido.sql).
--
-- GET /caminhoes
--   Lista todos os caminhoes. Resposta no formato padrao ORDS:
--     { "items": [ { "id_caminhao":.., "placa":.., "modelo":.., "status":..,
--                    "motorista":.., "data_cadastro":.. }, ... ] }
--   Pela interface: Source Type "Query" (so o SELECT, o ORDS empacota
--   sozinho em {"items":[...]}) -- mais simples que o PL/SQL abaixo, que e
--   so a alternativa de script.
--
-- POST /caminhoes/:id/status
--   Atualiza o status de um caminhao. Corpo esperado: { "status": "EM_ROTA" }
--   Resposta de sucesso: { "id_caminhao": <id>, "status": "<status atualizado>" }
--   Resposta de erro: HTTP 400, { "error": "ORA-20004/-20005: <mensagem>" }
--
-- TENTE RODAR ESTE SCRIPT em SQL Workshop > SQL Commands. Se der erro de
-- privilegio no pacote ORDS, use a secao "ALTERNATIVA MANUAL" no fim deste
-- arquivo.
-- ============================================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'erp.api',
        p_pattern        => 'caminhoes',
        p_comments       => 'GET: lista os caminhoes da frota.'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'erp.api',
        p_pattern        => 'caminhoes',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_plsql,
        p_comments       => 'Lista todos os caminhoes via APEX_JSON, formato {"items": [...]}.',
        p_source         => q'[
BEGIN
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.OPEN_ARRAY('items');
    FOR c IN (
        SELECT id_caminhao, placa, modelo, status, motorista, data_cadastro
          FROM caminhoes
         ORDER BY id_caminhao
    ) LOOP
        APEX_JSON.OPEN_OBJECT;
        APEX_JSON.WRITE('id_caminhao', c.id_caminhao);
        APEX_JSON.WRITE('placa', c.placa);
        APEX_JSON.WRITE('modelo', c.modelo);
        APEX_JSON.WRITE('status', c.status);
        APEX_JSON.WRITE('motorista', c.motorista);
        APEX_JSON.WRITE('data_cadastro', c.data_cadastro);
        APEX_JSON.CLOSE_OBJECT;
    END LOOP;
    APEX_JSON.CLOSE_ARRAY;
    APEX_JSON.CLOSE_OBJECT;
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        APEX_JSON.OPEN_OBJECT;
        APEX_JSON.WRITE('error', SQLERRM);
        APEX_JSON.CLOSE_OBJECT;
END;
]'
    );

    COMMIT;
END;
/


BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'erp.api',
        p_pattern        => 'caminhoes/:id/status',
        p_comments       => 'POST: atualiza o status de um caminhao (LIVRE, EM_CARGA ou EM_ROTA).'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'erp.api',
        p_pattern        => 'caminhoes/:id/status',
        p_method         => 'POST',
        p_source_type    => ORDS.source_type_plsql,
        p_mimes_allowed  => 'application/json',
        p_comments       => 'Atualiza caminhoes.status. :id vem da URL, :status e lido manualmente do :body.',
        p_source         => q'[
DECLARE
    v_id_caminhao NUMBER := :id;
    v_body_clob   CLOB;
    v_status      VARCHAR2(20);
    v_dest_offset INTEGER := 1;
    v_src_offset  INTEGER := 1;
    v_lang_ctx    INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
    v_warning     INTEGER;
BEGIN
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

    SELECT JSON_VALUE(v_body_clob, '$.status') INTO v_status FROM dual;

    IF v_status IS NULL OR v_status NOT IN ('LIVRE', 'EM_CARGA', 'EM_ROTA') THEN
        RAISE_APPLICATION_ERROR(-20004, 'Status invalido. Valores permitidos: LIVRE, EM_CARGA, EM_ROTA.');
    END IF;

    UPDATE caminhoes
       SET status = v_status
     WHERE id_caminhao = v_id_caminhao;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Caminhao nao encontrado: ' || v_id_caminhao);
    END IF;

    COMMIT;

    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('id_caminhao', v_id_caminhao);
    APEX_JSON.WRITE('status', v_status);
    APEX_JSON.CLOSE_OBJECT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
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
-- ALTERNATIVA MANUAL / o que foi feito de fato pela interface
-- ============================================================================
--
-- 1. SQL Workshop > RESTful Services > modulo "erp.api" (base path "/erp/")
-- 2. Create Template
--      URI Template: caminhoes
--    Dentro do template, Create Handler
--      Method:        GET
--      Source Type:   Query  (mais simples: so o SELECT, sem APEX_JSON)
--      Source:
--        SELECT id_caminhao, placa, modelo, status, motorista, data_cadastro
--          FROM caminhoes
--         ORDER BY id_caminhao
-- 3. Create Template
--      URI Template: caminhoes/:id/status
--    Dentro do template, Create Handler
--      Method:        POST
--      Source Type:   PL/SQL
--      Mimes Allowed: application/json  (obrigatorio, senao :body nao liga)
--      Source: o bloco DECLARE...END do POST acima (sem os colchetes q'[ ]')
-- 4. Save / Apply Changes.
--
-- Teste (Postman, NAO curl/PowerShell -- ver licao #1 do README):
--   GET  https://oracleapex.com/ords/erp_rafaellourenco/erp/caminhoes
--   Esperado: 200 OK, { "items": [ ... ] }
--
--   POST https://oracleapex.com/ords/erp_rafaellourenco/erp/caminhoes/<id>/status
--   Body -> raw -> JSON: { "status": "EM_ROTA" }
--   Esperado (caminhao existente): 200 OK, { "id_caminhao": <id>, "status": "EM_ROTA" }
--   Esperado (id inexistente): 400, { "error": "ORA-20005: Caminhao nao encontrado: <id>" }
--   Esperado (status invalido, ex. "PARADO"): 400, { "error": "ORA-20004: Status invalido..." }
-- ============================================================================
