# Soul Project ESX Legacy

Base modular do **Soul Project** para servidores FiveM assentes em **ESX Legacy**. O repositório não duplica o código de terceiros: a recipe do txAdmin instala as dependências oficiais e mantém o código `sp_*` isolado para atualizações e manutenção sem colisões.

## Incluído

- ESX Legacy Core e ESX Legacy Addons oficiais;
- `oxmysql`, `pma-voice`, `bob74_ipl` e recursos base Cfx.re;
- configuração PT-PT, OneSync e política Steam-only;
- grupos próprios para core, UI, trabalhos, crime, mapas e veículos;
- `sp_bootstrap` com gate Steam, health check e state bag de prontidão;
- SQL de controlo de migrações Soul Project;
- validação automática no GitHub Actions, incluindo deteção básica de segredos.

## Instalação pelo txAdmin

Usa esta recipe personalizada no Server Deployer:

```text
https://raw.githubusercontent.com/SoulBrotherDev/ESX-LEGACY/main/recipe.yaml
```

Depois da instalação, abre `config/secrets.cfg` e coloca a Steam Web API Key. Sem essa chave o servidor não conseguirá fornecer identificadores `steam:` e o gate Steam-only recusará ligações.

## Arranque

A ordem de recursos está em `config/resources.cfg`. Após arrancar, executa na consola:

```text
sp_health
```

O comando apresenta o estado de `oxmysql`, `es_extended` e dos módulos Soul Project essenciais.

## Estrutura

```text
config/                    Configuração dividida por domínio
database/                  Migrações próprias do Soul Project
docs/                      Instalação e arquitetura
resources/[sp_core]/       Núcleo transversal Soul Project
resources/[sp_ui]/         Interfaces e HUD
resources/[sp_jobs]/       Trabalhos legais
resources/[sp_illegal]/    Sistemas criminais
resources/[sp_maps]/       IPLs, MLOs e mapas próprios
resources/[sp_vehicles]/   Veículos, handling e ecossistema automóvel
resources/[sp_custom]/     Integrações transversais
```

## Regras da base

1. Não versionar chaves, tokens, palavras-passe ou connection strings reais.
2. Recursos de terceiros permanecem fora do Git e são instalados pela recipe.
3. Recursos próprios usam prefixo `sp_` e manifest `fxmanifest.lua`.
4. Alterações SQL próprias são cumulativas e registadas em `sp_schema_migrations`.
5. Atualizações do ESX são testadas em staging antes de chegar a produção.
