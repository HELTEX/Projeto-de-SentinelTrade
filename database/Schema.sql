-- =====================================================================
-- SentinelTrade - Schema do banco de dados (PostgreSQL 14+)
-- Baseado em docs/requisitos/04-arquitetura-e-dados.md (secao 4.2)
--
-- Como executar:
--   psql -U <usuario> -d <banco> -f database/schema.sql
-- Nenhuma senha ou segredo deve ser colocado neste arquivo.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid() e digest()

-- ---------------------------------------------------------------------
-- TIPOS ENUMERADOS
-- ---------------------------------------------------------------------
CREATE TYPE perfil_usuario  AS ENUM ('INVESTIDOR', 'AUDITOR', 'ADMIN');
CREATE TYPE status_conta    AS ENUM ('ATIVA', 'BLOQUEADA', 'ENCERRADA');
CREATE TYPE tipo_ativo      AS ENUM ('ACAO', 'ETF', 'FII');
CREATE TYPE tipo_ordem      AS ENUM ('COMPRA', 'VENDA');
CREATE TYPE status_ordem    AS ENUM (
    'PENDENTE',
    'VALIDADA',
    'ENVIADA_BOLSA',
    'PARCIALMENTE_EXECUTADA',
    'EXECUTADA',
    'REJEITADA',
    'CANCELADA'
);
CREATE TYPE status_mercado  AS ENUM ('ABERTO', 'FECHADO');

-- ---------------------------------------------------------------------
-- A. INVESTIDOR  (RF01, RF02)
-- ---------------------------------------------------------------------
CREATE TABLE investidor (
    id             UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_completo  VARCHAR(150)   NOT NULL,
    email          VARCHAR(255)   NOT NULL UNIQUE,
    senha_hash     VARCHAR(255)   NOT NULL,          -- hash (ex.: BCrypt), nunca a senha
    mfa_secret     VARCHAR(255),                     -- segredo TOTP (guardar criptografado)
    perfil         perfil_usuario NOT NULL DEFAULT 'INVESTIDOR',
    criado_em      TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- B. CONTA CORRENTE  (RF02, RN01)
-- ---------------------------------------------------------------------
CREATE TABLE conta (
    id               UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    investidor_id    UUID           NOT NULL REFERENCES investidor(id),
    saldo_disponivel NUMERIC(18,2)  NOT NULL DEFAULT 0 CHECK (saldo_disponivel >= 0),
    saldo_bloqueado  NUMERIC(18,2)  NOT NULL DEFAULT 0 CHECK (saldo_bloqueado  >= 0),
    status           status_conta   NOT NULL DEFAULT 'ATIVA',
    criado_em        TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- LIMITES DE RISCO por investidor  (RF05)
-- (acrescentado: o enunciado pede "limites financeiros")
-- ---------------------------------------------------------------------
CREATE TABLE limite_risco (
    investidor_id           UUID          PRIMARY KEY REFERENCES investidor(id),
    valor_max_por_ordem     NUMERIC(18,2) NOT NULL CHECK (valor_max_por_ordem > 0),
    valor_max_diario        NUMERIC(18,2) NOT NULL CHECK (valor_max_diario > 0),
    qtd_max_ordens_diarias  INT           NOT NULL DEFAULT 100 CHECK (qtd_max_ordens_diarias > 0),
    atualizado_em           TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- C. ATIVO FINANCEIRO  (RF03, RN03)
-- ---------------------------------------------------------------------
CREATE TABLE ativo (
    id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    ticker          VARCHAR(12)    NOT NULL UNIQUE,   -- ex.: PETR4, VALE3
    nome            VARCHAR(150)   NOT NULL,
    tipo            tipo_ativo     NOT NULL,
    preco_atual     NUMERIC(18,4)  NOT NULL CHECK (preco_atual > 0),
    status_mercado  status_mercado NOT NULL DEFAULT 'ABERTO',
    atualizado_em   TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- Historico de cotacoes recebidas do provedor (simulado)
CREATE TABLE cotacao_historico (
    id          BIGSERIAL     PRIMARY KEY,
    ativo_id    UUID          NOT NULL REFERENCES ativo(id),
    preco       NUMERIC(18,4) NOT NULL CHECK (preco > 0),
    recebido_em TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- D. POSICAO EM CARTEIRA  (RF02, RN01)
-- ---------------------------------------------------------------------
CREATE TABLE carteira_posicao (
    id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    investidor_id  UUID          NOT NULL REFERENCES investidor(id),
    ativo_id       UUID          NOT NULL REFERENCES ativo(id),
    quantidade     INT           NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
    preco_medio    NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (preco_medio >= 0),
    UNIQUE (investidor_id, ativo_id)
);

-- ---------------------------------------------------------------------
-- E. ORDEM DE NEGOCIACAO  (RF04, RF05, RF06, RNF02)
-- ---------------------------------------------------------------------
CREATE TABLE ordem (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    idempotency_key       VARCHAR(100)  NOT NULL UNIQUE,   -- anti-duplicidade (RNF02)
    investidor_id         UUID          NOT NULL REFERENCES investidor(id),
    conta_id              UUID          NOT NULL REFERENCES conta(id),
    ativo_id              UUID          NOT NULL REFERENCES ativo(id),
    tipo                  tipo_ordem    NOT NULL,
    quantidade            INT           NOT NULL CHECK (quantidade > 0),
    preco_limite          NUMERIC(18,4) NOT NULL CHECK (preco_limite > 0),
    status                status_ordem  NOT NULL DEFAULT 'PENDENTE',
    quantidade_executada  INT           NOT NULL DEFAULT 0,
    preco_execucao        NUMERIC(18,4),
    motivo_rejeicao       VARCHAR(255),
    criado_em             TIMESTAMPTZ   NOT NULL DEFAULT now(),
    atualizado_em         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CHECK (quantidade_executada >= 0 AND quantidade_executada <= quantidade)
);

CREATE INDEX idx_ordem_investidor ON ordem (investidor_id, criado_em DESC);
CREATE INDEX idx_ordem_status     ON ordem (status);
CREATE INDEX idx_cotacao_ativo    ON cotacao_historico (ativo_id, recebido_em DESC);

-- ---------------------------------------------------------------------
-- NOTIFICACOES  (RF07)
-- ---------------------------------------------------------------------
CREATE TABLE notificacao (
    id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    investidor_id  UUID          NOT NULL REFERENCES investidor(id),
    ordem_id       UUID          REFERENCES ordem(id),
    mensagem       VARCHAR(500)  NOT NULL,
    lida           BOOLEAN       NOT NULL DEFAULT FALSE,
    criada_em      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX idx_notificacao_investidor ON notificacao (investidor_id, criada_em DESC);

-- ---------------------------------------------------------------------
-- AUDITORIA IMUTAVEL  (RF08, RN02 - modelo WORM)
-- Cada registro guarda o hash do anterior (cadeia de hashes), entao
-- qualquer alteracao no historico quebra a cadeia e fica detectavel.
-- ---------------------------------------------------------------------
CREATE TABLE auditoria_log (
    id             BIGSERIAL    PRIMARY KEY,
    ocorrido_em    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    investidor_id  UUID,                       -- quem executou (pode ser nulo, ex.: login falho)
    evento         VARCHAR(60)  NOT NULL,      -- ex.: LOGIN_OK, LOGIN_FALHA, ORDEM_CRIADA
    entidade       VARCHAR(40),                -- ex.: ORDEM, CONTA, CARTEIRA
    entidade_id    VARCHAR(64),
    detalhes       JSONB,
    hash_anterior  CHAR(64),
    hash_registro  CHAR(64)     NOT NULL
);

CREATE INDEX idx_auditoria_investidor ON auditoria_log (investidor_id, ocorrido_em DESC);
CREATE INDEX idx_auditoria_evento     ON auditoria_log (evento);

-- Calcula o encadeamento de hashes a cada insercao
CREATE OR REPLACE FUNCTION auditoria_encadear_hash() RETURNS trigger AS $$
DECLARE
    ultimo CHAR(64);
BEGIN
    -- garante ordem serial entre insercoes concorrentes
    PERFORM pg_advisory_xact_lock(hashtext('auditoria_log'));

    SELECT hash_registro INTO ultimo
      FROM auditoria_log ORDER BY id DESC LIMIT 1;

    NEW.hash_anterior := ultimo;
    NEW.hash_registro := encode(
        digest(
            COALESCE(ultimo, '') || '|' || NEW.ocorrido_em::text || '|' ||
            COALESCE(NEW.investidor_id::text, '') || '|' || NEW.evento || '|' ||
            COALESCE(NEW.entidade, '') || '|' || COALESCE(NEW.entidade_id, '') || '|' ||
            COALESCE(NEW.detalhes::text, ''),
            'sha256'),
        'hex');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria_hash
    BEFORE INSERT ON auditoria_log
    FOR EACH ROW EXECUTE FUNCTION auditoria_encadear_hash();

-- Bloqueia UPDATE e DELETE: nem administradores podem alterar (RN02)
CREATE OR REPLACE FUNCTION auditoria_bloquear_alteracao() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'auditoria_log e imutavel: % nao e permitido', TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria_imutavel
    BEFORE UPDATE OR DELETE ON auditoria_log
    FOR EACH ROW EXECUTE FUNCTION auditoria_bloquear_alteracao();

CREATE TRIGGER trg_auditoria_sem_truncate
    BEFORE TRUNCATE ON auditoria_log
    FOR EACH STATEMENT EXECUTE FUNCTION auditoria_bloquear_alteracao();