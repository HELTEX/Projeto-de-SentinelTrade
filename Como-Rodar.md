# Como rodar o SentinelTrade

Este guia mostra o passo a passo **manual**. No final há a opção de rodar tudo com um único comando (`make`).

## Pré-requisitos

| Ferramenta | Versão | Para quê |
|---|---|---|
| JDK | 21 | Backend (Java) |
| Maven | 3.9+ | Compilar e rodar o backend |
| Docker (com Docker Compose) | recente | Banco PostgreSQL |
| Node.js | 20+ | Frontend (Vue) |

Confira no terminal:

```bash
java -version
mvn -version
docker --version
docker compose version
node --version
```

---

## Passo a passo manual

### 1. Configurar as variáveis de ambiente

Na raiz do projeto:

```bash
cp .env.example .env
```

Abra o `.env` e defina o valor de `DB_PASSWORD`. O arquivo `.env` **nunca** deve ser commitado (já está no `.gitignore`).

### 2. Subir o banco de dados

```bash
docker compose up -d --wait
```

Na primeira vez, o PostgreSQL executa sozinho o `database/schema.sql` e o `database/seed.sql`. Confira:

```bash
docker compose exec postgres psql -U sentinel -d sentineltrade -c "SELECT ticker, preco_atual FROM ativo;"
```

Devem aparecer ativos como PETR4, VALE3 e HGLG11. (Se você mudou `DB_USER` ou `DB_NAME` no `.env`, use os seus valores no comando.)

### 3. Rodar o backend

Em um terminal, a partir da raiz:

```bash
cd backend
mvn spring-boot:run
```

Teste em outro terminal ou no navegador:

```bash
curl http://localhost:8080/actuator/health
```

O esperado é `{"status":"UP"}`.

### 4. Rodar o frontend

Em **outro** terminal, a partir da raiz:

```bash
cd frontend
npm install
npm run dev
```

Abra http://localhost:5173. Por enquanto a página é em branco.

### 5. Encerrar

- Backend e frontend: `Ctrl+C` em cada terminal.
- Banco: `docker compose down` (mantém os dados) ou `docker compose down -v` (apaga tudo).

---

## Sem Docker (PostgreSQL instalado na máquina)

Crie um banco e rode os scripts, nesta ordem:

```bash
psql -U <usuario> -d <banco> -f database/schema.sql
psql -U <usuario> -d <banco> -f database/seed.sql
```

Depois ajuste `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` e `DB_PASSWORD` no `.env` e siga do passo 3.

## Problemas comuns

| Sintoma | O que fazer |
|---|---|
| Porta 5432 já em uso | Pare o PostgreSQL local ou mude `DB_PORT` no `.env` |
| Porta 8080 ou 5173 em uso | Mude `SERVER_PORT` no `.env` (backend) ou feche o outro programa |
| Backend: `password authentication failed` | O banco foi criado com outra senha. Rode `docker compose down -v` e suba de novo |
| Alterei o `schema.sql` e nada mudou | Os scripts só rodam com o banco vazio. Use `docker compose down -v` e suba de novo |
| `mvn: command not found` | Instale o Maven e abra um novo terminal |

---

## Rodando tudo com `make`

Existe um `Makefile` na raiz que automatiza os passos acima. Com ele, **um comando** sobe o banco, o backend e o frontend:

```bash
make
```

Isso é equivalente a `make run`: cria o `.env` se não existir, sobe o PostgreSQL, espera ele ficar saudável, instala as dependências do frontend se faltarem e inicia backend e frontend juntos. `Ctrl+C` encerra os dois. O banco continua rodando em segundo plano; para pará-lo, use `make stop`.

Outros comandos:

| Comando | O que faz |
|---|---|
| `make` ou `make run` | Sobe banco, backend e frontend |
| `make db-up` | Só o banco |
| `make backend` | Só o backend (porta 8080) |
| `make frontend` | Só o frontend (porta 5173) |
| `make stop` | Para o banco (mantém os dados) |
| `make db-reset` | Apaga os dados e recria o banco com schema e seed |
| `make setup` | Só cria o `.env` a partir do `.env.example` |
| `make help` | Lista os comandos |

**Instalando o `make`:**
- **Linux:** `sudo apt install make`
- **macOS:** `xcode-select --install`
- **Windows:** o `make` não vem instalado. Use o **WSL** ou o **Git Bash** com `make` instalado, ou então siga o passo a passo manual acima.