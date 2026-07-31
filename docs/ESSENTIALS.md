# Sistemas essenciais

Este documento descreve os módulos incluídos na base `0.2.0` e os testes mínimos antes de promover o servidor para produção.

## Dependências instaladas pela recipe

| Componente | Função |
|---|---|
| ESX Legacy Core | framework, jogadores, empregos, inventário e contas |
| ESX Legacy Addons | jobs, sociedades, banking, billing, lojas, propriedades e veículos |
| oxmysql | persistência MySQL/MariaDB |
| pma-voice | proximidade, rádio e chamadas |
| bob74_ipl | carregamento de IPLs base |
| cfx-server-data | recursos base Cfx.re |

As dependências externas são descarregadas no deploy e não são copiadas para este repositório.

## `sp_bootstrap`

Responsabilidades:

- impedir entrada sem identificador `steam:`;
- verificar recursos essenciais;
- disponibilizar o comando ACE `sp_health`;
- definir `LocalPlayer.state.spReady` quando o jogador termina o carregamento;
- fornecer logging normalizado para os recursos Soul Project.

Teste:

```text
sp_health
```

O resultado deve apresentar `oxmysql`, `es_extended`, `sp_bootstrap`, `sp_radio`, `sp_starterpack` e `sp_phone` como `started`.

## `sp_radio`

### Utilização

| Ação | Comando/tecla |
|---|---|
| abrir ou escolher frequência | `F6` ou `/radio [frequência]` |
| desligar rádio | `/radiooff` |
| alterar volume | `/radiovol 1-100` |

O rádio exige o item `radio` por omissão.

### Frequências

| Intervalo | Acesso |
|---|---|
| 1-49 | Polícia |
| 50-99 | Emergência Médica |
| 100-149 | Polícia e Emergência Médica |
| 150-199 | Mecânicos |
| 200-249 | Táxis |
| 250-999 | Público |

As restrições são validadas no servidor e novamente no `pma-voice`. A frequência é removida quando o jogador perde acesso.

Configuração: `resources/[sp_core]/sp_radio/config.lua`.

## `sp_phone`

### Utilização

- `F1` ou `/phone` abre o telemóvel;
- o item `phone` é obrigatório;
- cada personagem recebe um número persistente `555XXXX`;
- o número e todos os remetentes são resolvidos no servidor.

### Funções

- contactos;
- SMS persistentes;
- conversas e mensagens lidas;
- histórico de chamadas;
- chamadas de voz pelo `pma-voice`;
- pedidos de serviço com coordenadas anexadas.

### Serviços

| Número | Serviço | Emprego destinatário |
|---|---|---|
| 112 | Polícia | `police` |
| 115 | Emergência Médica | `ambulance` |
| 116 | Mecânico | `mechanic` |
| 117 | Táxi | `taxi` |

Configuração: `resources/[sp_ui]/sp_phone/config.lua`.

Tabelas:

- `sp_phone_numbers`;
- `sp_phone_contacts`;
- `sp_phone_messages`;
- `sp_phone_calls`;
- `sp_phone_service_messages`.

## `sp_starterpack`

É entregue uma única vez por identificador de personagem:

- `phone` ×1;
- `radio` ×1;
- `bread` ×2;
- `water` ×2.

A operação usa `INSERT IGNORE` em `sp_starter_claims`, impedindo duplicação após reconnect ou restart.

Configuração: `resources/[sp_core]/sp_starterpack/config.lua`.

## Empregos e economia ESX

A recipe instala o pack completo de addons e importa os esquemas necessários para:

- `esx_addonaccount`;
- `esx_addoninventory`;
- `esx_datastore`;
- `esx_society`;
- `esx_billing`;
- `esx_license`;
- `esx_banking`;
- `esx_jobs`;
- `esx_policejob`;
- `esx_ambulancejob`;
- `esx_mechanicjob`;
- `esx_taxijob`;
- `esx_vehicleshop`;
- `esx_garage`.

O grupo `[esx_addons]` inclui ainda os restantes módulos oficiais compatíveis presentes no pack, como necessidades, HUD, propriedades, lojas e personalização de veículos.

### Empregos principais

| Código ESX | Designação PT-PT |
|---|---|
| `unemployed` | Desempregado |
| `police` | Polícia |
| `ambulance` | Emergência Médica |
| `mechanic` | Mecânico |
| `taxi` | Táxi |
| `cardealer` | Concessionário |
| `realestateagent` | Imobiliária |

A tradução inicial é aplicada por `database/020_sp_jobs_pt.sql` depois dos SQL oficiais.

## Ordem de arranque

A sequência crítica é:

```text
oxmysql
pma-voice
es_extended
[core]
[esx_addons]
[sp_core]
[sp_ui]
```

Não colocar recursos que usam ESX ou MySQL antes das respetivas dependências.

## Checklist de staging

1. Executar a recipe numa base de dados vazia.
2. Confirmar ausência de erros `query_database`.
3. Colocar a Steam Web API Key em `config/secrets.cfg`.
4. Arrancar e executar `sp_health`.
5. Entrar com Steam aberta e confirmar o kit inicial.
6. Reconectar e confirmar que o kit não é repetido.
7. Testar rádio público com dois jogadores.
8. Testar acesso negado a uma frequência profissional.
9. Atribuir `police`, entrar na frequência 1 e retirar novamente o emprego.
10. Enviar SMS, reconnectar e confirmar persistência.
11. Efetuar, atender e terminar uma chamada.
12. Enviar pedidos 112, 115, 116 e 117 com profissionais online.
13. Testar Polícia, Emergência Médica, Mecânico, Táxi, concessionário e garagem.
14. Confirmar billing, society e banking.
15. Rever salários, preços, veículos, posições e permissões antes de produção.

## Limites da base

Esta base fornece um ponto de partida funcional e reproduzível. Não substitui a configuração própria da cidade para:

- coordenadas e MLOs;
- fardas e veículos de serviço;
- equilíbrio económico;
- inventário final;
- dispatch avançado;
- MDT;
- multicharacter e aparência próprios;
- sistemas Soul Project já desenvolvidos separadamente.

Esses módulos devem entrar nas famílias `sp_*` sem editar diretamente o código externo sempre que possível.
