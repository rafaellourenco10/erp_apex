-- ============================================================================
-- Corrige o tratamento de erro de POST /erp/pedidos/:id/cancelar
--
-- BUG encontrado em 2026-08-18 (revisao antes de aplicar o endpoint de
-- caminhoes, que copiava o mesmo padrao): o handler original, em
-- 05_ords_endpoint_cancelar_pedido.sql, captura QUALQUER erro (inclusive
-- validacoes de negocio, ex.: cancelar um pedido que ja esta CANCELADO) e
-- devolve HTTP 200 com {"erro_debug": "ORA-20003: ..."} no corpo, em vez de
-- propagar como erro HTTP de verdade.
--
-- O app Flutter (ApiService._mapError, em lib/services/api_service.dart) so
-- reconhece erro quando a resposta HTTP NAO eh 2xx -- eh assim que o Dio
-- dispara DioException. Uma resposta 200 com erro dentro do JSON eh tratada
-- como SUCESSO: PedidoService.cancelarPedido() so faz `await` e descarta o
-- corpo da resposta, e HistoricoPedidosProvider.cancelarPedido() entao marca
-- o pedido como CANCELADO na tela mesmo quando o backend recusou a operacao.
-- Esse caminho nunca foi testado pelo app -- so via Postman, onde um humano
-- le o JSON e ve o erro manualmente.
--
-- Este script REDEFINE o mesmo handler (mesmo module/pattern/method de
-- 05_ords_endpoint_cancelar_pedido.sql).
--
-- ATUALIZACAO 2026-08-19: a primeira versao deste script usava so `RAISE;`
-- pra propagar o erro (mesmo padrao que a documentacao antiga descrevia
-- para criar_pedido_completo). Testando o endpoint equivalente de
-- caminhoes (07_ords_endpoint_caminhoes.sql) nesse ambiente, descobrimos
-- que um RAISE nao tratado cai numa pagina generica de erro do ORDS (555
-- ORDS-25001) sem expor a mensagem real em lugar nenhum -- entao um RAISE
-- sozinho nao e suficiente aqui. A correcao real: usar o bind especial
-- `:status_code` pra definir o HTTP explicitamente, e escrever nosso
-- proprio JSON com a mensagem em `error` (chave que
-- ApiService._extractMessage, em lib/services/api_service.dart, ja sabe
-- ler). Esse padrao foi testado e confirmado funcionando (400 + corpo com
-- a mensagem real) no endpoint de caminhoes -- ainda nao foi reconfirmado
-- especificamente para este endpoint nem para /pedidos_completo, entao
-- teste os dois pelo app depois de aplicar (nao so por Postman).
--
-- Rode este script em: SQL Workshop > SQL Commands, no workspace
-- erp_rafaellourenco. Seguro rodar mesmo com o handler antigo ja aplicado:
-- ORDS.DEFINE_HANDLER substitui a definicao existente para o mesmo
-- module/pattern/method.
-- ============================================================================

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'erp.api',
        p_pattern        => 'pedidos/:id/cancelar',
        p_method         => 'POST',
        p_source_type    => ORDS.source_type_plsql,
        p_comments       => 'Chama cancelar_pedido(:id). Erros de negocio viram HTTP 400 com {"error": ...}.',
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
--   POST https://oracleapex.com/ords/erp_rafaellourenco/erp/pedidos/<id>/cancelar
--   com um <id> ja CANCELADO -- esperado agora: HTTP 400 (nao mais 200),
--   corpo { "error": "ORA-20003: Somente pedidos com status PENDENTE podem
--   ser cancelados..." }. Repita o teste pelo APP tambem, nao so Postman --
--   esse era exatamente o caminho que nunca tinha sido exercitado.
-- ============================================================================
