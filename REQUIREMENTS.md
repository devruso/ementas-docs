# Documentação de Requisitos

## Requisitos:

### Épicos:

|Num | Épico | Personas envolvidas | Descrição do épico |
| - | --------- | --------- | --------- |
|01 | Gerenciamento de usuários |Professor | Permitir que o professor gere convite para que novos professores se cadastrem, visualize os usuários cadastrados e edite suas informações.
|02 | Realizar login da aplicação | Professor | Disponibilizar interface de login para permitir que o professor realize o login na aplicação e permitir a redefinição de sua senha.
|03 | Gerenciar conteúdo | Professor, visitante | Permitir que o professor realize o cadastro  disciplinas e seus respectivos conteúdos programáticos, edite e aprove a alteração de suas informações. Permitir a visualização pública das informações das disciplinas cadastradas através do sistema ou importadas via Crawler e seu conteúdo programático, bem como sua exportação para formato específico.

### Histórias de usuário

| E01US01 | Gerar convite de cadastro para um professor |
|---------|-----------------|
| *Descrição da história* |  Como um professor previamente cadastrado, quero gerar um link de convite, para que um professor possa realizar seu cadastro |
|*Critérios de aceitação*| _Cenário 01: Gerar link de convite_ <br> Dado que o professor esteja visualizando os professores cadastrados <br> Quando clicar no botão gerar convite <br> Então o sistema exibirá um link com o convite para aplicação <br> E permitirá que o mesmo copie a informação 

| E01US02 | Permitir o cadastro usuário a partir de convite |
|---------|-----------------|
| *Descrição da história* | Como um professor que recebeu um covite de cadastro na plataforma, quero me cadastrar na aplicação, para que eu possa realizar a gestão das informações das disciplinas.
|*Critérios de aceitação*| Dado que o usuário deseja se cadastrar na aplicação <br> Quando possuir um link válido <br> Então o sistema permitirá que o usuário informe o seu "Nome Completo", "E-mail", "Senha" e que o usuário confirme sua senha na opção "Confirmar senha" <br><br> Dado que o professor esteja se cadastrando com um novo usuário <br> Quando informar um e-mail já cadastrado <br> Então o sistema exibirá a mensagem: "Professor já cadastrado" <br> E cancelará a operação


| E01US03 | Editar informações do professor |
|---------|-----------------|
| *Descrição da história* |  Como um professor previamente cadastrado, quero editar as informações de um professor, para atualizar seu nome ou e-mail |
|*Critérios de aceitação*| _Cenário 01: Editar informações professor_ <br> Dado que o usuário esteja visualizando a lista de professores <br> Quando clicar na opção de editar a informação de um professor <br> Então o sistema exibirá as informações do "Nome Completo" e "E-mail institucional" <br> E permitirá que o mesmo edite as informações descritas. <br> <br> Dado que o usuário esteja editando as informações <br> Quando não preencher uma informação <br> Então o sistema exibirá a mensagem: [Nome do campo] é obrigatório <br> E não concluirá a operação. <br> <br> Dado que o professor esteja editando as informações de um usuário <br> Quando alterar a informação de e-mail <br> E este já pertença a outro usuário cadastrado <br>Então o sistema exibirá a mensagem: "E-mail já cadastrado"<br> E cancelará a operação <br> <br> Dado que o usuário esteja editando as informações <br> Quando salvar as informações com sucesso <br> Então o sistema concluirá a operação <br> E redirecionará o usuário para a interface de listagem.


| E01US04 | Listar professores |
|---------|-----------------|
| *Descrição da história* |  Como um professor previamente cadastrado, quero visualizar as informações dos professores cadastrados, para que eu possa visualizar suas informações|
|*Critérios de aceitação*| Dado que o usuário esteja logado na aplicação <br> Quando desejar visualizar a lista de professores <br> Então o sistema disponibilizará em formato de grade as colunas "Nome", "E-mail" e "Status" de cada usuário <br> E ordenará a listagem pelo nome do usuário <br> E disponibilizará as opções de editar. 


| E02US01 | Realizar login |
|---------|-----------------|
| *Descrição da história* |  Como um usuário no sistema, quero realizar o login na aplicação, para que eu possa realizar operações no sistema|
|*Critérios de aceitação*| _Cenário 01: Realizar login_ <br> Dado que o usuário esteja na interface de login <br> Quando digitar um e-mail e senha válidos <br> Então o sistema redirecionará o usuário para interface de listagem de disciplinas.<br><br> _Cenário 02: Informar erro no login_ <br> Dado que o usuário esteja na interface de login <br> Quando digitar um e-mail e senha inválidos <br> Então o sistema exibirá a mensagem "Usuário ou senha incorretos" <br> E cancelará a operação.

| E02US02 | Redefinir senha |
|---------|-----------------|
| *Descrição da história* |  Como um professor previamente cadastrado, quero solicitar o reset de minha senha, para que eu possa acessar novamente a aplicação|
|*Critérios de aceitação*| _Cenário 01: Esqueci minha senha_ <br>Dado que o usuário clique na opção esqueci minha senha <br> Quando informar um e-mail previamente cadastrado <br> Então o sistema enviará um e-mail com um link para redefinição de senha. <br> <br> _Cenário 02: Redefinição de senha"_ <br> Dado que o usuário acesse o link do e-mail <br> Quando informar uma senha válida no campo "Senha" e confirmá-la corretamente na opção "Confirmar senha" <br> Então o sistema alterará a senha do usuário na aplicação <br> E efetuará automaticamente seu login <br> E o redirecionará para interface de listagem de disciplinas.

| E03US01 | Cadastrar disciplinas/conteúdo programático |
|---------|-----------------|
| *Descrição da história* |  Como um professor, quero cadastrar disciplinas, para que ela fique disponível para aprovação e publicação para acesso externo|
|*Critérios de aceitação*| _Cenário 01 - Cadastro de conteúdo programático_ <br> Dado que o professor esteja visualizando a lista de disciplinas <br> Quando clicar na opção "Cadastrar nova disciplina" <br> Então o sistema deverá disponibilizar, em ordem, que o usuário preencha o: <br> - "Nome"<br>   - "Código"<br> - "Natureza" (Seleção entre as opções) da disciplina <br> - "Departamento"<br> - "Semestre vigente"<br> - "Carga horária - Professor" (Distribuição entre as opções: "Teórica", "Prática", "Teór./Prát", "Estágio", "Prát./Estág") e "Total" (Valor da soma da distribuição anterior) <br> - "Carga horária - Estudante" (Distribuição entre as opções: "Teórica", "Prática", "Teór./Prát", "Estágio", "Prát./Estág") e "Total" (Valor da soma da distribuição anterior)<br> - "Carga horária - Módulo" (Distribuição entre as opções: "Teórica", "Prática", "Teór./Prát", "Estágio", "Prát./Estág") e "Total" (Valor da soma da distribuição anterior)<br> - "Pré-requisitos" (Com a opção de preenchimento opcional de uma ou mais disciplinas através dos campos: "Cód. Curso" e "Cód. Disciplina")<br> - "Ementa", <br> - "Objetivos" <br> - "Conteúdo programático" <br> - "Metodologia", <br> - "Avaliação de aprendizagem", <br> - "Bibliografia"


| E03US02 | Visualizar disciplinas |
|---------|-----------------|
| *Descrição da história* |  Como um professor, quero visualizar a lista de disciplinas cadastradas, para que ela fique disponível para acesso externo|
|*Critérios de aceitação*| _Cenário 01: Buscar disciplinas_ <br> Dado que o usuário esteja na interface de listagem de disciplinas <br> Quando digitar alguma informação no campo "Nome ou código da disciplina" <br> Então o sistema buscará em tempo real _(autocomplete)_ as disciplinas que estejam de acordo ao filtro <br> E exibirá na listagem de disciplinas. <br> E a busca deverá ser tolerante a acentuação (ex.: "expressao" deve encontrar "expressão"). <br><br>_Cenário 02: Listar disciplinas_ <br> Dado que o usuário tenha informado algum dado no campo de busca <br> Quando houverem disciplinas que se encaixam na informação buscada <br> Então o sistema exibirá o código e nome da disciplina <br> E permitirá o clique para visualização dos detalhes da disciplina.


| E03US03 | Visualizar detalhes da disciplina |
|---------|-----------------|
| *Descrição da história* |  Como um professor ou visitante, quero visualizar detalhes das disciplinas, para que eu possa obter as informações importantes acerca da mesma |
|*Critérios de aceitação*| _Cenário 01: Visualizar detalhes da disciplina - Professor_<br> Dado que o professor esteja visualizando a lista de disciplinas retornadas pela busca <br> Quando clicar em uma disciplina <br> E esta possuir informações alteradas ainda não publicadas<br> Então o sistema exibirá as ultimas informações editadas (ainda que não publicadas) da disciplina através dos campos "Departamento", "Carga horária", "Semestre vigente", "Ementa" e "Conteúdo programático"<br> E permitirá que o professor exporte ou edite as informações. <br><br>_Cenário 02: Visualizar detalhes da disciplina - Público_<br> Dado que o visitante esteja visualizando a lista de disciplinas retornadas pela busca <br> Quando clicar em uma disciplina <br> Então o sistema exibirá as ultimas informações publicadas da disciplina através dos campos "Departamento", "Carga horária", "Semestre vigente", "Ementa" e "Conteúdo programático"<br> E permitirá que o visitante exporte as informações.



| E03US04 | Visualizar histórico de alterações da disciplina |
|---------|-----------------|
| *Descrição da história* |  Como um professor ou visitante, quero um histórico das alterações oficiais no conteúdo de uma disciplina, para que eu possa acompanhar as mudanças do conteúdo programático|
|*Critérios de aceitação*| _Cenário 01: Visualizar histórico da disciplina_<br> Dado que o usuário esteja visualizando os detalhes da disciplina <br> Quando clicar no histórico <br> Então o sistema exibirá o histórico de alterações em ordem cronológica do mais recente para o mais antigo.


| E03US05 | Atualizar informações  da disciplina |
|---------|-----------------|
| *Descrição da história* |  Como um professor, quero editar as informações de uma disciplina cadastrada para que seu conteúdo programático esteja de acordo a realidade da disciplina |
|*Critérios de aceitação*| _Cenário 01: Visualizar dados que serão editados_<br> Dado que o professor clique na disciplina buscada <br> Então o sistema exibirá a interface de visualização dos dados <br> E permitirá que o usuário edite as informações cadastradas<br><br> Dado que o professor deseje editar as informações da disciplina <br>Então o sistema exibirá as ultimas alterações salvas (ainda que não publicadas) para o campos descritos nas sessões abaixo.<br> <br> *Geral:* <br> - Código <br> - Nome <br> - Departamento <br> - Semestre Vigente <br> - Modalidade <br><br> *Carga Horária:* <br> - Estudante <br> - Professor <br> - Módulo<br><br> *Pré-requisitos:* <br> - Número do curso <br> - Código do curso  <br> - Botão de adicionar pré-requisito**<br><br>*Ementa:* <br> - Ementa <br><br> *Conteúdo programático:*<br> - Conteúdo programático<br><br> *Metodologia:*<br> - Metodologia<br><br> *Avaliação da aprendizagem:*<br> - Avaliação da aprendizagem<br><br> *Bibliografia:*<br> - Bibliografia<br><br> ** Para o botão de adicionar Pré-requisito, a cada vez que o professor inserir um pré-requisito, uma nova linha abaixo deverá ser adicionada, permitindo sua posterior exclusão. <br><br> ** Cada sessão (Geral, Carga horária, Pré-requisitos, etc.) deverá ser passível de expansão e recolhimento de acordo ao clique do professor.<br><br>_Cenário 02: Editar alterações_<br> Dado que o professor esteja na interface de edição de uma disciplina<br>Quando alterar alguma informação<br>Então o sistema permitirá que o mesmo salve como rascunho a alteração através do botão "Salvar rascunho"<br>Ou salve e publique a alteração através da opção "Salvar e publicar"

| E03US06 | Aprovar alteração de disciplina |
|---------|-----------------|
| *Descrição da história* |  Como um professor, quero aprovar as alterações de uma disciplina, para que ela fique de acordo ao que fora alterado em reunião do colegiado. |
|*Critérios de aceitação*|  _Cenário 01: Aprovar alterações_<br> Dado que o usuário esteja editando as alterações<br>Quando desejar publicá-las<br>Então o sistema exibirá um pop-up com os campos obrigatórios "Data de aprovação" e "Ata de aprovação" e as opções "Salvar" e "Cancelar". 

| E03US07 | Exportar conteúdo de disciplina |
|---------|-----------------|
| *Descrição da história* | Como um professor ou um visitante, quero exportar o conteúdo de uma disciplina, para obter suas informações em formato específico padronizado |
|*Critérios de aceitação*| _Cenário 01: Exportação oficial_ <br> Dado que o usuário esteja na tela de detalhes da disciplina <br> Quando clicar no botão de exportação PDF <br> Então a interface deve indicar explicitamente que o arquivo gerado é da versão oficial publicada da disciplina. |

## Requisitos de Robustez e Regressão

- A busca de disciplina por código nos endpoints de detalhe (publicado e rascunho) deve usar igualdade exata case-insensitive, sem matching parcial por `LIKE`.
- O histórico de atualização de rascunho deve registrar campos alterados e, para campos críticos (`program` e `workload`), também os valores anteriores e novos.
- A diferenciação entre rascunho e versão oficial deve ser explícita na UX de detalhe e exportação.

| E03US08 | Criar serviço de importação de disciplinas |
|---------|-----------------|
| *Descrição da história* | Implementação de Crawler para importar dados de disciplinas. |
|*Critérios de aceitação*| Implementar crawler para que as disciplinas estejam disponíveis inicialmente na aplicação.
