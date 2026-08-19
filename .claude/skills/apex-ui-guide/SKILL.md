---
name: "Oracle APEX UI Guide (erp_apex)"
description: "Verified navigation instructions for the Oracle APEX App Builder / Page Designer UI used by this project's backend (workspace erp_rafaellourenco, app 166105, Oracle APEX 26.1.3). Use whenever the user asks how to do something inside the APEX App Builder or Page Designer (create/edit/delete a page, configure a region, wizards, menus). Forces verification via official docs.oracle.com/en/database/oracle/apex/ documentation or a user-confirmed screenshot before instructing any click — never guesses button/menu names."
---

# Oracle APEX UI Guide — erp_apex

## Regra de ouro

**Nunca instruir "clique em X" no APEX App Builder sem que X esteja confirmado.** Confirmado
significa uma das duas coisas:

1. Já está documentado em [`docs/UI_MAP.md`](docs/UI_MAP.md) (com fonte e data), ou
2. Vai ser verificado agora, nesta ordem:
   - Primeiro tentar `WebSearch`/`WebFetch` em `docs.oracle.com/en/database/oracle/apex/` (a
     versão pública indexada pode ser mais antiga que a 26.1.3 real do usuário — está tudo bem,
     use a mais recente disponível e avise que pode haver pequenas diferenças de versão).
   - Se a instrução baseada na doc não bater com o que o usuário vê (ele manda print
     discordando), o **print do usuário é a fonte de verdade** sobre a UI real dele — corrija e
     grave a correção em `docs/UI_MAP.md`.
   - Se não achar nada confiável, **peça um print** em vez de adivinhar.
3. Depois de confirmar algo novo (por doc ou por print), **adicione a entrada em
   `docs/UI_MAP.md`**, datada, com a fonte — assim a próxima vez (nesta ou na outra máquina, já
   que isso é versionado no git) não precisa reconfirmar do zero.

## Ambiente deste projeto

- Workspace APEX: `erp_rafaellourenco`
- Aplicação: `Application 166105`
- Versão: **Oracle APEX 26.1.3** (hospedado em oracleapex.com)
- Módulo ORDS relacionado (fora do App Builder, é a API REST): `erp.api` — ver
  [`backend/oracle/`](../../../backend/oracle/) no repositório.
- Isso é diferente do app Flutter (`lib/`) e diferente da API ORDS — aqui é especificamente o
  editor visual de páginas do APEX (App Builder / Page Designer).

## Quick start

1. Usuário pergunta algo tipo "como eu crio/apago/edito uma página/região/item no APEX?"
2. Consulte [`docs/UI_MAP.md`](docs/UI_MAP.md) primeiro — pode já estar confirmado.
3. Se não estiver lá, siga a "Regra de ouro" acima antes de responder.
4. Depois de resolvido, atualize `docs/UI_MAP.md`.

## Por que essa skill existe

Em 2026-08-19, dei instruções erradas repetidas vezes sobre onde clicar no App Builder (nomes de
wizard que não existem mais nessa versão, ícone de menu errado pra deletar página) porque respondi
de memória/suposição em vez de verificar. Essa skill existe pra isso não se repetir — ver
[`docs/UI_MAP.md`](docs/UI_MAP.md) para o histórico e o mapa acumulado.
