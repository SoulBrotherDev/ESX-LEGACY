# Instalação

## Requisitos

- FXServer atualizado com txAdmin;
- MariaDB ou MySQL acessível pelo servidor;
- chave de licença Cfx.re;
- Steam Web API Key para a política Steam-only.

## Deploy recomendado

1. No txAdmin, cria um novo servidor com **Remote URL Template**.
2. Introduz `https://raw.githubusercontent.com/SoulBrotherDev/ESX-LEGACY/main/recipe.yaml`.
3. Preenche o nome, licença Cfx.re, número máximo de jogadores e base de dados.
4. Conclui a recipe e abre `config/secrets.cfg`.
5. Substitui `COLOCAR_STEAM_WEB_API_KEY` pela chave Steam real.
6. Arranca o servidor e executa `sp_health` na consola.

## Primeiro teste

Confirma no arranque:

- `oxmysql` em estado `started`;
- `es_extended` em estado `started`;
- `sp_bootstrap` em estado `started`;
- entrada recusada quando o cliente não apresenta identificador `steam:`;
- criação da tabela `sp_schema_migrations`.

## Produção

Altera em `config/core.cfg`:

```cfg
setr sp:environment "production"
```

Mantém `sv_enforceGameBuild` comentado até o conjunto completo de mapas e veículos ser validado nesse build.
