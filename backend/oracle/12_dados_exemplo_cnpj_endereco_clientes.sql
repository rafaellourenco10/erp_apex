-- ============================================================================
-- DADOS DE EXEMPLO — CPF/CNPJ e endereco dos clientes ja cadastrados
--
-- Complementa 11_adiciona_cnpj_endereco_clientes.sql: aquele script so cria as
-- colunas (todas ficam NULL). Este aqui preenche dados FICTICIOS de teste nos
-- clientes que ja existem no banco, para dar pra testar a Tela Clientes (app)
-- e o Relatorio de Vendas -> Itens do Pedido (impressao) com dados completos,
-- sem precisar editar um por um no Form_Clientes.
--
-- Mesmo padrao de 09_dados_exemplo_caminhoes.sql. CPF sem pontuacao (mesmo
-- formato que ja foi usado manualmente no cliente #1, Rafael, ao testar o
-- formulario em 2026-08-25) -- so digitos, sem "." nem "-".
--
-- Nao inclui o cliente #1 (Rafael) -- ja tem dado real preenchido.
--
-- Rode este script em: SQL Workshop > SQL Commands, no workspace
-- erp_rafaellourenco. Seguro rodar mais de uma vez (so sobrescreve com os
-- mesmos valores).
-- ============================================================================

UPDATE clientes SET
    cpf_cnpj    = '45123698745',
    endereco    = 'Rua das Palmeiras',
    numero      = '120',
    complemento = 'Bloco B, Apto 12',
    bairro      = 'Zona 7',
    cidade      = 'Maringa',
    uf          = 'PR',
    cep         = '87020-100'
WHERE id_cliente = 21; -- Ana Souza

UPDATE clientes SET
    cpf_cnpj    = '32165498712',
    endereco    = 'Avenida Brasil',
    numero      = '850',
    complemento = NULL,
    bairro      = 'Centro',
    cidade      = 'Sarandi',
    uf          = 'PR',
    cep         = '87111-000'
WHERE id_cliente = 41; -- Carlos Lima

UPDATE clientes SET
    cpf_cnpj    = '78945612330',
    endereco    = 'Rua Minas Gerais',
    numero      = '45',
    complemento = NULL,
    bairro      = 'Jardim Alvorada',
    cidade      = 'Maringa',
    uf          = 'PR',
    cep         = '87035-100'
WHERE id_cliente = 42; -- Beatriz Alves

UPDATE clientes SET
    cpf_cnpj    = '15975348620',
    endereco    = 'Rua Parana',
    numero      = '300',
    complemento = 'Sala 2',
    bairro      = 'Vila Operaria',
    cidade      = 'Marialva',
    uf          = 'PR',
    cep         = '86990-000'
WHERE id_cliente = 43; -- Diego Ferreira

UPDATE clientes SET
    cpf_cnpj    = '96385274110',
    endereco    = 'Avenida Colombo',
    numero      = '5790',
    complemento = NULL,
    bairro      = 'Zona 5',
    cidade      = 'Maringa',
    uf          = 'PR',
    cep         = '87020-900'
WHERE id_cliente = 44; -- Fernanda Costa

COMMIT;

-- ============================================================================
-- Confira o resultado com:
--   SELECT id_cliente, nome, cpf_cnpj, endereco, numero, bairro, cidade, uf, cep
--   FROM clientes ORDER BY id_cliente;
-- Esperado: todos os 6 clientes (incluindo o #1, ja preenchido antes) com
-- CPF/CNPJ e endereco completos, nenhum "-"/NULL restante.
-- ============================================================================
