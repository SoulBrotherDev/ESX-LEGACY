# Soul Project ESX Legacy

Base modular do **Soul Project** para servidores FiveM assentes em **ESX Legacy**. A recipe txAdmin instala as dependências externas e mantém todo o código próprio `sp_*` separado, para permitir atualizações sem transformar o servidor num puzzle de recursos copiados à mão.

## Sistemas incluídos

### Fundação

- ESX Legacy Core e ESX Legacy Addons oficiais;
- `oxmysql`, `pma-voice`, `bob74_ipl` e recursos base Cfx.re;
- configuração PT-PT, OneSync e política Steam-only;
- permissões ACE para `owner`, `admin`, `dev`, `mod` e `support`;
- `sp_bootstrap` com gate Steam, health check e state bag `spReady`;
- migrações SQL cumulativas registadas em `sp_schema_migrations`.

### Comunicação

- `sp_radio` sobre `pma-voice`;
- frequências públicas e frequências reservadas por profissão;
- item `radio`, comandos `/radio`, `/radiooff` e `/radiovol`;
- revalidação server-side após mudança de emprego ou perda do item;
- `sp_phone` com número persistente por personagem;
- contactos, SMS persistentes, histórico de chamadas e chamadas de voz;
- pedidos com localização para Polícia, Emergência Médica, Mecânico e Táxi;
- item `phone`, comando `/phone` e tecla `F1`.

### Economia e roleplay

A instalação importa o SQL necessário para:

- contas partilhadas, inventários partilhados e datastores;
- sociedades e gestão de empresas;
- faturação, licenças e banking;
- lojas e necessidades incluídas nos addons ESX;
- concessionário, veículos próprios e garagem;
- propriedades, personalização, HUD e restantes módulos do pack oficial.

### Empregos essenciais

- Polícia;
- Emergência Médica;
- Mecânico;
- Táxi;
- Concessionário;
- Imobiliária;
- empregos civis do `esx_jobs`.

Os nomes principais são ajustados para PT-PT pela migração `020_sp_jobs_pt.sql`.

### Primeiro personagem

O `sp_starterpack` entrega apenas uma vez:

- 1 telemóvel;
- 1 rádio;
- 2 águas;
- 2 pães.

A entrega é idempotente e fica registada em `sp_starter_claims`.

## Instalação pelo txAdmin

Usa esta recipe personalizada no Server Deployer:

```text
https://raw.githubusercontent.com/SoulBrotherDev/ESX-LEGACY/main/recipe.yaml
```

Depois da instalação, abre `config/secrets.cfg` e coloca a Steam Web API Key. Chaves, tokens e palavras-passe reais nunca devem ser enviados para o Git.

Consulta o guia completo em [`docs/INSTALL.md`](docs/INSTALL.md) e o catálogo funcional em [`docs/ESSENTIALS.md`](docs/ESSENTIALS.md).

## Arranque e diagnóstico

A ordem dos recursos está em `config/resources.cfg`. Após arrancar, executa na consola:

```text
sp_health
```

O comando apresenta o estado do núcleo ESX, base de dados e módulos Soul Project essenciais.

## Estrutura

```text
config/                    Configuração dividida por domínio
database/                  Migrações próprias do Soul Project
docs/                      Instalação, arquitetura e catálogo funcional
resources/[sp_core]/       Bootstrap, rádio e kit inicial
resources/[sp_ui]/         Telefone, interfaces e HUD
resources/[sp_jobs]/       Trabalhos legais próprios
resources/[sp_illegal]/    Sistemas criminais
resources/[sp_maps]/       IPLs, MLOs e mapas próprios
resources/[sp_vehicles]/   Veículos, handling e ecossistema automóvel
resources/[sp_custom]/     Integrações transversais
```

## Qualidade

O GitHub Actions verifica automaticamente:

- ficheiros e dependências obrigatórias;
- SQL próprio incluído na recipe;
- ordem de arranque;
- referências dos manifests;
- sintaxe Lua;
- sintaxe JavaScript;
- whitespace e deteção básica de segredos.

## Regras da base

1. Não versionar chaves, tokens, palavras-passe ou connection strings reais.
2. Recursos de terceiros permanecem fora do Git e são instalados pela recipe.
3. Recursos próprios usam prefixo `sp_` e `fxmanifest.lua`.
4. Alterações SQL próprias são cumulativas e registadas em `sp_schema_migrations`.
5. Autoridade financeira, inventário, rádio, telefone e empregos permanece no servidor.
6. Atualizações do ESX são testadas em staging antes de chegar a produção.
