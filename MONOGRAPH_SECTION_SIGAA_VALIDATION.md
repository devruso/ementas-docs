# Secao de Monografia - Validacao do Crawler SIGAA Publico

## Problema

Durante a evolucao do EMENTAS, a importacao de componentes via SIGAA publico apresentava risco de falso positivo: tokens tecnicos do HTML (CSS/JSF/scripts) podiam ser interpretados como codigo de disciplina quando a pagina nao possuia linhas curriculares reais.

## Justificativa Tecnica

Esse comportamento compromete qualidade de dados, rastreabilidade e confiabilidade academica da base institucional. Em um sistema para gestao formal de ementas e conteudos programaticos, importar dados inexistentes e mais grave que nao importar em um caso ambiguo.

## Decisao de Projeto

Foi adotada estrategia fail-safe no parser SIGAA:
- considerar apenas linhas tabulares com pelo menos duas celulas (`td`);
- extrair codigo curricular apenas nas celulas iniciais da linha, evitando ruido de layout;
- deduplicar por codigo;
- normalizar departamento a partir de celulas de contexto ou cabecalho da pagina;
- manter fallback de URLs por tipo de fonte (`department`/`program`) para ampliar compatibilidade sem alterar contrato da API.

## Evidencias Implementadas

- Ajuste de parser e fallback: `ementas-api/src/services/CrawlerService.ts`.
- Regressao automatizada:
  - `ementas-api/src/tests/CrawlerSigaaParser.spec.ts`;
  - fixture real sem componentes (`source-department-1876851.html`) garantindo rejeicao de falso positivo.
- Resultado de teste:
  - backend crawler/share: suites verdes (`6/6` no recorte executado);
  - frontend detalhe da disciplina: `8/8` cenarios verdes apos estabilizacao.

## Impacto Academico e Pratico

- Reduz risco de poluicao da base oficial por importacoes espurias.
- Reforca principio de fonte canonica: conteudo programatico oficial permanece governado no EMENTAS.
- Melhora auditabilidade da etapa de importacao, permitindo demonstrar criterios de qualidade para banca do TCC.

## Bloco Curto para Monografia (Validação Visual)

Na etapa de validação visual, foi executada conferência no frontend com base em componentes realmente importados pelas rotas de SIAC e SIGAA público. As evidências foram capturadas por links públicos temporários, preservando o estado oficial publicado e permitindo inspeção objetiva da renderização final sem dependência de sessão autenticada. No recorte de 05/05/2026, foram validados os códigos MATA66 e MATE11 (origem SIAC) e IC0027 (origem SIGAA público), com capturas arquivadas em `ementas-docs/assets/validation-shared-mata66.png`, `ementas-docs/assets/validation-shared-mate11.png` e `ementas-docs/assets/validation-shared-ic0027.png`. O resultado confirma aderência entre dados persistidos e apresentação visual institucional, fortalecendo a rastreabilidade requisito -> importação -> evidência para banca.

## Versão Formal em Estrutura ABNT

### Problema

Uma etapa crítica do EMENTAS consiste em demonstrar que os dados importados por rastreamento automatizado não apenas são persistidos corretamente, mas também permanecem coerentes quando exibidos na interface final utilizada para consulta institucional. Sem essa verificação visual, a avaliação poderia se limitar à camada de API, deixando aberta a possibilidade de divergência entre dado persistido e dado efetivamente apresentado ao usuário.

### Método

Para reduzir esse risco, foi adotada uma estratégia de validação visual baseada em evidências produzidas diretamente no frontend. O procedimento utilizou links públicos temporários gerados a partir de componentes oficialmente publicados, o que permitiu observar a renderização final sem dependência de sessão autenticada e sem alterar o estado acadêmico do sistema. O pacote foi organizado de forma estratificada por origem de importação, contemplando três disciplinas provenientes do SIAC (`MATA66`, `MATE11` e `MATA88`) e duas disciplinas provenientes do SIGAA público (`IC0027` e `IC0061`). As capturas foram armazenadas, respectivamente, em `ementas-docs/assets/validation-shared-mata66.png`, `ementas-docs/assets/validation-shared-mate11.png`, `ementas-docs/assets/validation-shared-mata88.png`, `ementas-docs/assets/validation-shared-ic0027.png` e `ementas-docs/assets/validation-shared-ic0061.png`.

### Resultado

As evidências confirmaram que o frontend apresentou, de maneira consistente, os dados oficiais persistidos após importação. No estrato SIAC, observou-se a exibição de componentes com conteúdo programático textual efetivamente preservado. No estrato SIGAA público, observou-se comportamento coerente com a limitação da fonte externa, exibindo mensagens de indisponibilidade de ementa e conteúdo programático quando tais campos não estavam acessíveis na listagem pública. Em ambos os casos, a apresentação visual manteve identificação do componente, contexto institucional e organização informacional adequada para leitura acadêmica.

### Ameaça à Validade

Essa validação não substitui uma medição estatística ampla de acurácia por campo em todo o universo de disciplinas importáveis. O recorte adotado constitui uma amostra orientada por evidência operacional recente, útil para demonstrar consistência ponta a ponta, mas ainda sujeita a limitações de cobertura. Além disso, no caso do SIGAA público, a própria fonte pode restringir a exposição de alguns campos, o que limita a completude da validação visual sem invalidar a corretude do comportamento do sistema diante dessa indisponibilidade.

### Conclusão

Conclui-se que a estratégia de validação visual complementa de forma relevante a validação técnica do crawler e da persistência, pois demonstra aderência entre importação, armazenamento e apresentação final no EMENTAS. Essa evidência fortalece a rastreabilidade entre requisito funcional, implementação e resultado observável, contribuindo para a robustez argumentativa do trabalho perante a banca.

## Limitacoes e Proximos Passos

- Acuracia positiva em maior escala com paginas 100% reais de grade curricular do SIGAA exige completar descoberta de IDs/fluxo JSF que exponham tabela curricular completa sem autenticacao.
- Proximo ciclo recomendado:
  1. automatizar coleta com sessao JSF para DCC/DCI/PGCOMP;
  2. gerar verdade-terreno por amostra manual estratificada;
  3. recalcular acuracia por campo em lote e publicar no plano de testes.




