# Arquitetura

## Princípio

O repositório guarda configuração e código Soul Project. Dependências externas são instaladas pela recipe, evitando forks silenciosos e simplificando atualizações.

## Camadas

1. **Cfx.re**: recursos de sistema e hardcap.
2. **Persistência**: `oxmysql`.
3. **Framework**: `esx_lib`, `es_extended` e `[core]`.
4. **Addons ESX**: pacote oficial `[esx_addons]`.
5. **Soul Project Core**: serviços transversais, permissões e integrações.
6. **Domínios Soul Project**: UI, trabalhos, crime, mapas, veículos e custom.

## Convenções

- todos os recursos próprios começam por `sp_`;
- eventos seguem `sp_recurso:contexto:acao`;
- callbacks e exports públicos são documentados no README do recurso;
- o servidor valida sempre permissões, propriedade e montantes;
- a NUI nunca é fonte de verdade;
- SQL novo entra numa migração numerada e cumulativa.

## Grupos

- `[sp_core]`: identidade técnica, permissões, bridge e serviços partilhados;
- `[sp_ui]`: HUD, menus, identidade e componentes NUI;
- `[sp_jobs]`: trabalhos legais e entidades públicas;
- `[sp_illegal]`: gangs, territórios, laboratórios e contratos;
- `[sp_maps]`: IPLs, MLOs, mapas e loaders;
- `[sp_vehicles]`: veículos, danos, persistência, lojas e handling;
- `[sp_custom]`: integrações temporárias ou transversais.
