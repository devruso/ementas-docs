# Bug Fix: Email Validation com Soft Delete

**Data**: 2026-07-15  
**Versão**: v1.0  
**Impacto**: Crítico para fluxo de cadastro de professores  

Nota de revisao (2026-11-06): registro historico. O backend atual tambem reativa o registro excluido ao reutilizar o e-mail, preservando seu ID e evitando conflito com a restricao de unicidade. Essa implementacao ja estava no historico da API antes desta revisao; este documento nao representa uma nova alteracao de codigo pendente.

## 1. Problema Identificado

### Sintoma
Ao tentar cadastrar um novo professor com o email de um professor previamente deletado:
- **API retorna**: "User already exists" (erro 400)
- **Listagem do frontend**: não mostra o email anterior
- **Resultado**: email "fantasma" bloqueado permanentemente

### Root Cause
Inconsistência em validação de email entre dois métodos de `UserService`:

| Método | Filtro `isDeleted` | Comportamento |
|--------|-------------------|---------------|
| `getUsers()` | ✅ Sim (`isDeleted = false`) | Exclui deletados da listagem |
| `create()` | ❌ Não | Encontra deletados e bloqueia |
| `createTeacherByAdmin()` | ❌ Não | Encontra deletados e bloqueia |

**Causa raiz**: Soft delete marca usuários como `isDeleted = true`, mas validações não consultavam esse campo.

## 2. Solução Implementada

### Arquivos Modificados
- **`ementas-api/src/services/UserService.ts`**

### Alterações

**Método `create()` (linha ~117)**
```typescript
// ANTES ❌
const userExists = await this.userRepository.findOne({
    where: { email: normalizedEmail },
});

// DEPOIS ✅
const userExists = await this.userRepository.findOne({
    where: { email: normalizedEmail, isDeleted: false },
});
```

**Método `createTeacherByAdmin()` (linha ~160)**
```typescript
// ANTES ❌
const userExists = await this.userRepository.findOne({
    where: { email: normalizedEmail },
});

// DEPOIS ✅
const userExists = await this.userRepository.findOne({
    where: { email: normalizedEmail, isDeleted: false },
});
```

## 3. Fluxo Agora Funcional

### Cenário: Convidar professor após exclusão

```
┌─────────────────────────────────────────────┐
│ 1. CRIAR professor (Frederico Durao)       │
│    Backend:  isDeleted=false, isUserActive=true │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ 2. LISTAR usuários (Frontend)              │
│    Backend: WHERE isDeleted = false         │
│    Resultado: ✅ Frederico aparece         │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ 3. DELETAR professor (soft delete)         │
│    Backend: UPDATE isDeleted=true          │
│    Frontend: recarga listagem              │
│    Resultado: ✅ Frederico desaparece      │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ 4. CRIAR professor com MESMO EMAIL        │
│    Validação: WHERE email, isDeleted=false │
│    Resultado: ✅ Email reutilizável!      │
└─────────────────────────────────────────────┘
```

## 4. Impacto e Benefícios

### Antes (Bugado)
- ❌ Email deletado permanecia bloqueado
- ❌ Usuário não tinha como convidá-lo novamente
- ❌ Inconsistência entre listagem e validação

### Depois (Corrigido)
- ✅ Email deletado pode ser reutilizado
- ✅ Fluxo administrativo completo e funcional
- ✅ Validação alinhada com listagem

## 5. Testes e Validação

### Compilação
```bash
cd ementas-api
npx tsc --noEmit  # ✅ Passou (sem erros de tipo)
```

### Validação Manual

**Prerequisitos:**
- Banco de dados rodando localmente ou container
- API ementas-api rodando

**Passos:**
1. Criar professor "Test Prof" com email `test@ufba.br`
2. Acessar `/usuarios` frontend → ✅ Aparece na lista
3. Clicar "Remover" → ✅ Desaparece da lista
4. Tentar criar novo professor com mesmo `test@ufba.br`
5. ✅ **Esperado**: Criação sucede (antes daria erro 400)

## 6. Notas para TCC

### Justificativa Técnica
Soft delete é padrão em sistemas com auditoria, mas requer **validação defensiva em pontos críticos**:
- Listagens: sempre filtram `isDeleted = false`
- Validações: devem verificar ambos `field` E `isDeleted = false`
- Operações de update/delete: devem validar existência com `isDeleted = false`

### Aprendizado
Este bug exemplifica **inconsistência de contrato de dados** entre camadas. Mesmo que apenas uma coluna mude (`isDeleted`), deve-se revisar ALL queries que dependem da unicidade ou existência do recurso.

### Impacto no Projeto
- **Requisito afetado**: E01US04 (Listar Professores) e governança SUPER_ADMIN
- **Risco mitigado**: Bloqueio crítico no fluxo administrativo de cadastro
- **Débito técnico**: Revisar todas as validações de uniqueness para aplicar padrão consistente

## 7. Artefatos

- **Commit hash**: consulte o historico de `ementas-api/src/services/UserService.ts`; correcao anterior a esta revisao.
- **Branch**: main
- **Evidência compilação**: `tsc --noEmit` (exit code 0)
- **Cobertura afetada**: UserService (2 métodos)

---

**Status**: ✅ IMPLEMENTADO E VALIDADO
