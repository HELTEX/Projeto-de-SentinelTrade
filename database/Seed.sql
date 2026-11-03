-- =====================================================================
-- SentinelTrade - Dados simulados para desenvolvimento e testes
-- Executar DEPOIS do schema.sql:
--   psql -U <usuario> -d <banco> -f database/seed.sql
--
-- ATENCAO: todos os dados sao ficticios (Orion Capital e simulada).
-- Senha de TODOS os usuarios de teste: Teste@123  (guardada apenas como hash BCrypt)
-- Segredo MFA de teste (TOTP, base32): JBSWY3DPEHPK3PXP
-- Nunca reutilize estes valores fora do ambiente de desenvolvimento.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- USUARIOS (2 investidores, 1 auditor, 1 admin)
-- ---------------------------------------------------------------------
INSERT INTO investidor (id, nome_completo, email, senha_hash, mfa_secret, perfil) VALUES
 ('11111111-1111-1111-1111-111111111111', 'Ana Investidora',  'ana@orion.test',
  '$2a$10$smi0tjNYZ2yQQl52UVnsg.j56UOgBMMALSN4Is.Bm.bxxG5w5lpi6', 'JBSWY3DPEHPK3PXP', 'INVESTIDOR'),
 ('22222222-2222-2222-2222-222222222222', 'Bruno Trader',     'bruno@orion.test',
  '$2a$10$smi0tjNYZ2yQQl52UVnsg.j56UOgBMMALSN4Is.Bm.bxxG5w5lpi6', 'JBSWY3DPEHPK3PXP', 'INVESTIDOR'),
 ('33333333-3333-3333-3333-333333333333', 'Carla Auditora',   'auditor@orion.test',
  '$2a$10$smi0tjNYZ2yQQl52UVnsg.j56UOgBMMALSN4Is.Bm.bxxG5w5lpi6', 'JBSWY3DPEHPK3PXP', 'AUDITOR'),
 ('44444444-4444-4444-4444-444444444444', 'Diego Admin',      'admin@orion.test',
  '$2a$10$smi0tjNYZ2yQQl52UVnsg.j56UOgBMMALSN4Is.Bm.bxxG5w5lpi6', 'JBSWY3DPEHPK3PXP', 'ADMIN');

-- ---------------------------------------------------------------------
-- CONTAS
-- Ana: saldo baixo (util para testar o CA02: comprar R$ 10.000 com R$ 5.000)
-- Bruno: saldo alto
-- ---------------------------------------------------------------------
INSERT INTO conta (id, investidor_id, saldo_disponivel, saldo_bloqueado, status) VALUES
 ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',   5000.00, 0.00, 'ATIVA'),
 ('aaaaaaaa-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 250000.00, 0.00, 'ATIVA');

-- ---------------------------------------------------------------------
-- LIMITES DE RISCO
-- ---------------------------------------------------------------------
INSERT INTO limite_risco (investidor_id, valor_max_por_ordem, valor_max_diario, qtd_max_ordens_diarias) VALUES
 ('11111111-1111-1111-1111-111111111111',  20000.00,  50000.00,  20),
 ('22222222-2222-2222-2222-222222222222', 200000.00, 500000.00, 100);

-- ---------------------------------------------------------------------
-- ATIVOS (precos simulados)
-- MGLU3 fica com mercado FECHADO para testar a RN03
-- ---------------------------------------------------------------------
INSERT INTO ativo (id, ticker, nome, tipo, preco_atual, status_mercado) VALUES
 ('bbbbbbbb-0000-0000-0000-000000000001', 'PETR4',  'Petrobras PN',                'ACAO', 38.50,  'ABERTO'),
 ('bbbbbbbb-0000-0000-0000-000000000002', 'VALE3',  'Vale ON',                     'ACAO', 62.10,  'ABERTO'),
 ('bbbbbbbb-0000-0000-0000-000000000003', 'ITUB4',  'Itau Unibanco PN',            'ACAO', 33.75,  'ABERTO'),
 ('bbbbbbbb-0000-0000-0000-000000000004', 'MGLU3',  'Magazine Luiza ON',           'ACAO',  9.80,  'FECHADO'),
 ('bbbbbbbb-0000-0000-0000-000000000005', 'BOVA11', 'ETF iShares Ibovespa',        'ETF', 128.40,  'ABERTO'),
 ('bbbbbbbb-0000-0000-0000-000000000006', 'IVVB11', 'ETF iShares S&P 500',         'ETF', 305.20,  'ABERTO'),
 ('bbbbbbbb-0000-0000-0000-000000000007', 'HGLG11', 'CSHG Logistica FII',          'FII', 160.90,  'ABERTO'),
 ('bbbbbbbb-0000-0000-0000-000000000008', 'MXRF11', 'Maxi Renda FII',              'FII',  10.35,  'ABERTO');

-- Historico inicial de cotacoes (um ponto por ativo)
INSERT INTO cotacao_historico (ativo_id, preco)
SELECT id, preco_atual FROM ativo;

-- ---------------------------------------------------------------------
-- CARTEIRA (posicoes iniciais)
-- Ana tem PETR4 (permite testar venda e venda acima da posicao)
-- ---------------------------------------------------------------------
INSERT INTO carteira_posicao (investidor_id, ativo_id, quantidade, preco_medio) VALUES
 ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0000-0000-0000-000000000001', 100,  35.20),
 ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-0000-0000-0000-000000000002', 500,  58.00),
 ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-0000-0000-0000-000000000005', 300, 120.00),
 ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-0000-0000-0000-000000000007', 200, 155.00);

-- ---------------------------------------------------------------------
-- ORDEM DE EXEMPLO (historico) + notificacao + auditoria
-- ---------------------------------------------------------------------
INSERT INTO ordem (id, idempotency_key, investidor_id, conta_id, ativo_id, tipo, quantidade, preco_limite,
                   status, quantidade_executada, preco_execucao)
VALUES
 ('cccccccc-0000-0000-0000-000000000001', 'seed-ordem-0001',
  '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000002',
  'bbbbbbbb-0000-0000-0000-000000000002', 'COMPRA', 100, 62.50, 'EXECUTADA', 100, 62.10);

INSERT INTO notificacao (investidor_id, ordem_id, mensagem) VALUES
 ('22222222-2222-2222-2222-222222222222', 'cccccccc-0000-0000-0000-000000000001',
  'Sua ordem de compra de 100 VALE3 foi executada a R$ 62,10.');

-- O trigger da tabela calcula hash_anterior e hash_registro automaticamente.
-- Os valores abaixo sao placeholders exigidos pela coluna NOT NULL e sao sobrescritos.
INSERT INTO auditoria_log (investidor_id, evento, entidade, entidade_id, detalhes, hash_registro) VALUES
 ('22222222-2222-2222-2222-222222222222', 'ORDEM_CRIADA',    'ORDEM', 'cccccccc-0000-0000-0000-000000000001',
  '{"tipo":"COMPRA","ticker":"VALE3","quantidade":100}'::jsonb, 'x'),
 ('22222222-2222-2222-2222-222222222222', 'ORDEM_EXECUTADA', 'ORDEM', 'cccccccc-0000-0000-0000-000000000001',
  '{"preco_execucao":62.10}'::jsonb, 'x');

COMMIT;