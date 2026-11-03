# Como rodar o banco

## Opcao 1 - Docker (recomendada)

```bash
cp .env.example .env        # preencha DB_PASSWORD
docker compose up -d
```

O `schema.sql` e o `seed.sql` sao executados automaticamente na primeira subida.
Para recriar do zero: `docker compose down -v && docker compose up -d`.

## Opcao 2 - PostgreSQL instalado na maquina

Crie o banco e rode os dois scripts, nesta ordem:

```bash
psql -U <usuario> -d <banco> -f database/schema.sql
psql -U <usuario> -d <banco> -f database/seed.sql
```

## Conferindo

```bash
psql -U <usuario> -d <banco> -c "SELECT ticker, preco_atual FROM ativo;"
```
