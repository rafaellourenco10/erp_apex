-- ============================================================================
-- Consultas ao dicionario de dados usadas para gerar SCHEMA.md.
-- Rode em SQL Workshop > SQL Commands, botao "Run" (nao "Explain" - consultas
-- com subquery no FROM/JOIN nao sao suportadas pela funcao Explain Plan do
-- SQL Commands e retornam "Statement not supported").
-- Reexecute quando o modelo de dados mudar para manter o SCHEMA.md atualizado.
-- ============================================================================

-- 1) Tabelas e colunas (tipo, tamanho, obrigatoriedade, se e PK ou FK)
SELECT
    t.table_name,
    c.column_id,
    c.column_name,
    c.data_type ||
      CASE WHEN c.data_type IN ('VARCHAR2','CHAR') THEN '(' || c.char_length || ')'
           WHEN c.data_type = 'NUMBER' AND c.data_precision IS NOT NULL
                THEN '(' || c.data_precision || NVL2(c.data_scale, ',' || c.data_scale, '') || ')'
           ELSE '' END AS tipo,
    c.nullable,
    cc.constraint_type
FROM user_tables t
JOIN user_tab_columns c ON c.table_name = t.table_name
LEFT JOIN (
    SELECT ucc.table_name, ucc.column_name, uc.constraint_type
    FROM user_cons_columns ucc
    JOIN user_constraints uc ON uc.constraint_name = ucc.constraint_name
    WHERE uc.constraint_type IN ('P','R')
) cc ON cc.table_name = c.table_name AND cc.column_name = c.column_name
ORDER BY t.table_name, c.column_id;

-- 2) Chaves estrangeiras (quem referencia quem)
SELECT
    uc.table_name,
    ucc.column_name,
    r_uc.table_name AS tabela_referenciada,
    r_ucc.column_name AS coluna_referenciada
FROM user_constraints uc
JOIN user_cons_columns ucc ON ucc.constraint_name = uc.constraint_name
JOIN user_constraints r_uc ON r_uc.constraint_name = uc.r_constraint_name
JOIN user_cons_columns r_ucc ON r_ucc.constraint_name = r_uc.constraint_name AND r_ucc.position = ucc.position
WHERE uc.constraint_type = 'R'
ORDER BY uc.table_name;

-- 3) Triggers existentes (o que dispara automaticamente em cada tabela)
SELECT trigger_name, table_name, triggering_event, status
FROM user_triggers
ORDER BY table_name, trigger_name;
