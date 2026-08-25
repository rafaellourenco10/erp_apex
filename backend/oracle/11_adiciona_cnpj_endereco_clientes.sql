-- ============================================================================
-- Adiciona CPF/CNPJ e endereco estruturado a CLIENTES
--
-- Motivacao: levantamento do lado APEX identificou que CLIENTES nao tem
-- documento fiscal (bloqueia nota fiscal) nem endereco de entrega (bloqueia
-- logistica -- a distribuidora ja tem frota de caminhoes em CAMINHOES, mas
-- nao ha pra onde entregar). Ver docs/MEMORIA.md e conversa de 2026-08-25.
--
-- Decisoes tomadas com o usuario:
-- - CPF/CNPJ: campo unico (aceita os dois formatos, sem separar por tipo de
--   pessoa por enquanto).
-- - Endereco: estruturado (rua/numero/complemento/bairro/cidade/uf/cep), nao
--   texto livre -- necessario para organizar rota de entrega por regiao/CEP
--   no futuro (ver Roadmap).
-- - Todas as colunas NULLABLE: clientes ja cadastrados nao tem esses dados
--   ainda, e nao ha backfill. Tornar obrigatorio eh decisao futura, depois
--   que o formulario estiver no ar e o cadastro existente for revisado.
--
-- Rode este script em: SQL Workshop > SQL Commands, no workspace
-- erp_rafaellourenco. Seguro rodar uma vez; rodar de novo dá erro de coluna
-- já existente (ORA-01430) -- nesse caso já está aplicado, ignore o erro.
-- ============================================================================

ALTER TABLE CLIENTES ADD (
    CPF_CNPJ    VARCHAR2(18),
    ENDERECO    VARCHAR2(150),
    NUMERO      VARCHAR2(10),
    COMPLEMENTO VARCHAR2(60),
    BAIRRO      VARCHAR2(80),
    CIDADE      VARCHAR2(80),
    UF          CHAR(2),
    CEP         VARCHAR2(9)
);

-- ============================================================================
-- Depois de rodar, confirme com:
--   SELECT cpf_cnpj, endereco, numero, complemento, bairro, cidade, uf, cep
--   FROM clientes WHERE ROWNUM <= 1;
-- Esperado: colunas existem, todas NULL nos registros já cadastrados.
-- ============================================================================
