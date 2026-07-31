# Instalação

## Requisitos

- FXServer atualizado com txAdmin;
- MariaDB ou MySQL acessível pelo servidor;
- chave de licença Cfx.re;
- Steam Web API Key para a política Steam-only;
- portas FiveM e txAdmin configuradas no firewall.

## Deploy recomendado

1. No txAdmin, cria um servidor novo com **Remote URL Template**.
2. Introduz `https://raw.githubusercontent.com/SoulBrotherDev/ESX-LEGACY/main/recipe.yaml`.
3. Preenche nome, licença Cfx.re, lotação e ligação à base de dados.
4. Usa uma base de dados vazia para o primeiro deploy.
5. Conclui a recipe e abre `config/secrets.cfg`.
6. Substitui `COLOCAR_STEAM_WEB_API_KEY` pela chave Steam real.
7. Configura os identificadores ACE dos administradores em `config/permissions.cfg` ou pelo txAdmin.
8. Arranca o servidor e executa `sp_health` na consola.

## O que a recipe instala

- recursos base Cfx.re;
- ESX Legacy Core;
- ESX Legacy Addons;
- oxmysql;
- pma-voice;
- bob74_ipl;
- recursos próprios em `[sp_core]` e `[sp_ui]`;
- SQL oficial de sociedades, billing, banking, jobs, veículos e garagem;
- migrações próprias do telefone, rádio, kit inicial e traduções PT-PT.

## Primeiro teste

Confirma no arranque:

- `oxmysql` em `started`;
- `pma-voice` em `started`;
- `es_extended` em `started`;
- `[core]` e `[esx_addons]` sem erros;
- `sp_bootstrap`, `sp_radio`, `sp_starterpack` e `sp_phone` em `started`;
- entrada recusada sem identificador `steam:`;
- tabelas `sp_schema_migrations`, `sp_phone_numbers` e `sp_starter_claims` criadas.

Executa:

```text
sp_health
```

Depois entra com uma personagem nova e confirma:

- kit inicial entregue apenas uma vez;
- `/radio 250` liga uma frequência pública;
- `F1` abre o telefone;
- SMS e chamadas funcionam entre dois jogadores;
- pedidos 112/115/116/117 chegam aos empregos corretos.

O checklist completo está em [`ESSENTIALS.md`](ESSENTIALS.md).

## Segredos

O ficheiro `config/secrets.cfg` é ignorado pelo Git. Mantém nele apenas valores locais:

```cfg
set steam_webApiKey "CHAVE_REAL_AQUI"
```

A ligação MySQL é preenchida pelo txAdmin no `server.cfg`. Não coloques tokens Discord, licenças Cfx.re ou palavras-passe em documentação, commits ou scripts Lua.

## Produção

Altera em `config/core.cfg`:

```cfg
setr sp:environment "production"
```

Antes de abrir o servidor:

1. ajusta salários e economia;
2. configura garagens, concessionário, lojas e propriedades;
3. revê fardas, veículos e armamento dos empregos;
4. testa todos os recursos com OneSync;
5. cria backup da base de dados;
6. ativa build enforcement apenas depois de validar mapas e veículos nesse build.

Mantém `sv_enforceGameBuild` comentado até o conjunto completo de mapas e veículos ser validado.
