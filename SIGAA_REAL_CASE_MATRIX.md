# Matriz de Casos Reais - SIGAA Publico (UFBA)

Data de coleta: 2026-05-04  
Ambiente: execucao local Windows via `Invoke-WebRequest -UseBasicParsing`

## Casos por Fonte e Nivel Academico

| Fonte | Source Type | Source ID | Nivel informado | URL testada | Resultado HTTP | Evidencia funcional |
|---|---|---:|---|---|---:|---|
| Departamento de Ciencia da Computacao (DCC/IC) | department | 1114 | graduacao | `https://sigaa.ufba.br/sigaa/public/componentes/busca_componentes.jsf` (POST JSF) | 200 | Retornou listagem tabular com 133 componentes extraiveis |
| Departamento de Computacao Interdisciplinar (DCI/IC) | department | 2440 | graduacao | `https://sigaa.ufba.br/sigaa/public/componentes/busca_componentes.jsf` (POST JSF) | 200 | Retornou listagem tabular com 32 componentes extraiveis |
| Programa de Pos-Graduacao em Ciencia da Computacao (PGCOMP/IC) | program | 1820 | mestrado (stricto) | `https://sigaa.ufba.br/sigaa/public/componentes/busca_componentes.jsf` (POST JSF) | 200 | Retornou listagem tabular com 70 componentes extraiveis (codigos com prefixo `PGCOMP/`) |
| Departamento (IC/UFBA) | department | 1876851 | graduacao | `https://sigaa.ufba.br/sigaa/public/departamento/componentes.jsf?id=1876851` | 200 | Pagina carregada sem componentes (`Nenhuma turma encontrada`) |
| Departamento (IC/UFBA) | department | 1876885 | graduacao | `https://sigaa.ufba.br/sigaa/public/departamento/componentes.jsf?id=1876885` | 200 | Pagina carregada sem componentes (estrutura equivalente) |
| Programa stricto (tentativa real) | program | 25210 | mestrado | `https://sigaa.ufba.br/sigaa/public/programa/curriculo.jsf?lc=pt_BR&id=25210` | 200 | Portal retornou mensagem de incompatibilidade de unidade/programa |
| Programa stricto (tentativa real) | program | 43753 | doutorado | `https://sigaa.ufba.br/sigaa/public/programa/curriculo.jsf?lc=pt_BR&id=43753` | 200 | Portal retornou mensagem de incompatibilidade de unidade/programa |

## Observacoes Tecnicas

- Os casos reais acima foram suficientes para validar robustez negativa do parser (nao gerar disciplinas quando a pagina nao contem linhas curriculares reais).
- Para compatibilidade operacional, o backend passou a usar fallback de URLs SIGAA por `sourceType` e `academicLevel`.
- A descoberta de IDs publicos para DCC/DCI/PGCOMP foi concluida com fluxo JSF de sessao/estado (`javax.faces.ViewState` + POST do formulario `busca_componentes`).
- Fixtures geradas para reproducao: `source-busca-componentes-dcc-1114.html`, `source-busca-componentes-dci-2440.html`, `source-busca-componentes-pgcomp-1820.html`.

## Relatorio de Acuracia por Campo (Etapa Atual)

Escopo medido nesta etapa:
- Caso real sem componentes: `source-department-1876851.html`.
- Caso real com tabela curricular via JSF (amostra estratificada manual):
	- DCC (`1114`, graduacao)
	- DCI (`2440`, graduacao)
	- PGCOMP (`1820`, mestrado/stricto)

| Campo | Criterio | Acuracia positiva em lote (15 amostras) |
|---|---|---:|
| code | formato + captura do codigo curricular | 100% (15/15) |
| name | preenchimento de nome da disciplina | 100% (15/15) |
| department | normalizacao de departamento por tipo de fonte | 100% (15/15) |
| academicLevel | propagacao do nivel recebido | 100% (15/15) |

Artefato de suporte:
- Resultado estruturado da medicao: `ementas-api/src/tests/fixtures/sigaa/accuracy-results.json`.


