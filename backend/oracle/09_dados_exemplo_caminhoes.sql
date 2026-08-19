-- ============================================================================
-- DADOS DE EXEMPLO — CAMINHOES
--
-- Popula a tabela caminhoes (criada em 06_criar_caminhoes.sql) com registros
-- de teste, para dar para testar a tela pag_caminhoes / Form_Caminhoes no
-- APEX App Builder sem precisar cadastrar um por um manualmente.
--
-- ID_CAMINHAO e DATA_CADASTRO sao preenchidos automaticamente pelo banco
-- (IDENTITY e DEFAULT SYSDATE), nao precisa informar.
--
-- Rode este script em: SQL Workshop > SQL Commands, no workspace
-- erp_rafaellourenco.
-- ============================================================================

INSERT INTO caminhoes (placa, modelo, status, motorista) VALUES ('RAF1A23', 'Volvo FH 540', 'LIVRE', 'Carlos Eduardo Silva');
INSERT INTO caminhoes (placa, modelo, status, motorista) VALUES ('RAF2B34', 'Scania R450', 'EM_ROTA', 'Jose Antonio Souza');
INSERT INTO caminhoes (placa, modelo, status, motorista) VALUES ('RAF3C45', 'Mercedes-Benz Actros 2651', 'EM_CARGA', 'Paulo Roberto Lima');
INSERT INTO caminhoes (placa, modelo, status, motorista) VALUES ('RAF4D56', 'Iveco Daily 70C17', 'LIVRE', 'Marcos Vinicius Alves');
INSERT INTO caminhoes (placa, modelo, status, motorista) VALUES ('RAF5E67', 'VW Constellation 24.280', 'EM_ROTA', 'Andre Luiz Ferreira');
INSERT INTO caminhoes (placa, modelo, status, motorista) VALUES ('RAF6F78', 'DAF XF 480', 'LIVRE', 'Ricardo Gomes Pereira');
INSERT INTO caminhoes (placa, modelo, status, motorista) VALUES ('RAF7G89', 'Ford Cargo 2429', 'EM_CARGA', 'Fabio Henrique Costa');
INSERT INTO caminhoes (placa, modelo, status, motorista) VALUES ('RAF8H90', 'Volkswagen Delivery 9.170', 'LIVRE', 'Bruno Cesar Martins');

COMMIT;
