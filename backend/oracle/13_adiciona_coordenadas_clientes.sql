-- ============================================================================
-- COORDENADAS DOS CLIENTES — base da pagina "Mapa de Clientes" no APEX
--
-- A regiao Map do APEX precisa de latitude/longitude (ou SDO_GEOMETRY) pra
-- desenhar os pontos; CLIENTES so tinha o endereco em texto (script 11).
-- Este script cria as 2 colunas e preenche coordenadas APROXIMADAS (ficticias,
-- so pra demo) pros clientes de exemplo, batendo com a cidade/bairro do
-- script 12.
--
-- Rode em: SQL Workshop > SQL Commands, workspace erp_rafaellourenco.
-- Rode o ALTER uma vez so (rodar de novo da ORA-01430 "coluna ja existe");
-- os UPDATEs podem ser repetidos.
-- ============================================================================

ALTER TABLE clientes ADD (
    latitude  NUMBER(9,6),
    longitude NUMBER(9,6)
);

-- SQL Commands roda um comando por vez: rode o ALTER acima sozinho, depois
-- este bloco inteiro (um bloco BEGIN/END conta como um comando so).
BEGIN
    UPDATE clientes SET latitude = -23.425300, longitude = -51.938600 WHERE id_cliente = 1;  -- Rafael (centro de Maringa; ajuste se quiser)
    UPDATE clientes SET latitude = -23.410200, longitude = -51.931500 WHERE id_cliente = 21; -- Ana Souza, Maringa (Zona 7)
    UPDATE clientes SET latitude = -23.444100, longitude = -51.874000 WHERE id_cliente = 41; -- Carlos Lima, Sarandi
    UPDATE clientes SET latitude = -23.391500, longitude = -51.947800 WHERE id_cliente = 42; -- Beatriz Alves, Maringa (Jd. Alvorada)
    UPDATE clientes SET latitude = -23.484900, longitude = -51.792000 WHERE id_cliente = 43; -- Diego Ferreira, Marialva
    UPDATE clientes SET latitude = -23.404700, longitude = -51.937300 WHERE id_cliente = 44; -- Fernanda Costa, Maringa (Zona 5)
    COMMIT;
END;

-- ============================================================================
-- Confira com:
--   SELECT id_cliente, nome, cidade, latitude, longitude FROM clientes ORDER BY id_cliente;
-- Esperado: os 6 clientes com latitude/longitude preenchidas.
--
-- Query usada como fonte da camada de pontos no mapa (pagina "Mapa de Clientes"):
--   SELECT c.id_cliente, c.nome, c.cidade, c.latitude, c.longitude,
--          COUNT(p.id_pedido)                                        AS qtd_pedidos,
--          'R$ ' || TO_CHAR(NVL(SUM(CASE WHEN p.status <> 'CANCELADO' THEN p.valor_total END), 0),
--                           'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.''') AS total_comprado
--   FROM clientes c
--   LEFT JOIN pedidos p ON p.id_cliente = c.id_cliente
--   WHERE c.latitude IS NOT NULL
--   GROUP BY c.id_cliente, c.nome, c.cidade, c.latitude, c.longitude
-- ============================================================================
