# MER do Sistema de Ementas

Este modelo registra o recorte das entidades TypeORM em 2026-07-29 e a correcao de integracao entre departamentos e componentes curriculares.

Nota de revisao (2026-11-06): este diagrama e historico. Nao inclui evolucoes posteriores, como cursos, favoritos, sessoes e historico imutavel de publicacoes (`component_versions`). Consulte as entidades e migrations da API para o esquema vigente.

Observacao importante: `components.department` e `component_drafts.department` continuam existindo como texto denormalizado para exibicao e compatibilidade com dados legados, mas a relacao canonica agora e `department_id -> departments.id`.

```mermaid
erDiagram
    USERS {
        uuid id PK
        varchar name
        varchar email UK
        varchar password
        boolean is_user_active
        boolean is_deleted
        varchar role
        varchar signature_hash
        timestamptz signature_updated_at
        varchar signature_file_key
        varchar signature_file_provider
        varchar signature_file_content_type
        integer signature_file_size
        varchar signature_file_hash
        timestamptz created_at
        timestamptz updated_at
    }

    DEPARTMENTS {
        uuid id PK
        varchar name UK
        varchar code UK
        timestamptz created_at
        timestamptz updated_at
    }

    COMPONENTS {
        uuid id PK
        uuid created_by FK
        uuid workload_id FK
        uuid component_draft_id FK
        uuid department_id FK
        varchar status
        varchar code UK
        varchar name
        varchar department
        varchar modality
        varchar program
        varchar semester
        varchar academic_level
        varchar prerequeriments
        varchar methodology
        varchar objective
        varchar syllabus
        varchar learningAssessment
        varchar bibliography
        varchar referencesBasic
        varchar referencesComplementary
        timestamptz created_at
        timestamptz updated_at
    }

    COMPONENT_DRAFTS {
        uuid id PK
        uuid component_id FK
        uuid created_by FK
        uuid workload_id FK
        uuid department_id FK
        varchar code UK
        varchar name
        varchar department
        varchar modality
        varchar program
        varchar semester
        varchar academic_level
        varchar prerequeriments
        varchar methodology
        varchar objective
        varchar syllabus
        varchar learningAssessment
        varchar bibliography
        varchar referencesBasic
        varchar referencesComplementary
        timestamptz created_at
        timestamptz updated_at
    }

    COMPONENT_WORKLOADS {
        uuid id PK
        integer teacher_theory
        integer teacher_practice
        integer teacher_theory_practice
        integer teacher_internship
        integer teacher_practice_internship
        integer teacher_extension
        integer student_theory
        integer student_practice
        integer student_theory_practice
        integer student_internship
        integer student_practice_internship
        integer student_extension
        integer module_theory
        integer module_practice
        integer module_theory_practice
        integer module_internship
        integer module_practice_internship
        integer module_extension
    }

    COMPONENT_LOGS {
        uuid id PK
        uuid component_id FK
        uuid component_draft_id FK
        uuid updated_by FK
        varchar agreement_number
        timestamptz agreement_date
        varchar version_code
        text official_program
        text official_syllabus
        varchar description
        varchar type
        timestamptz created_at
        timestamptz updated_at
    }

    COMPONENT_RELATIONS {
        uuid id PK
        uuid component_id FK
        varchar relation_type
        varchar related_code
        timestamptz created_at
        timestamptz updated_at
    }

    COMPONENT_CURRICULUM_CONTEXTS {
        uuid id PK
        uuid component_id FK
        varchar source_key UK
        varchar curriculum_code
        varchar curriculum_name
        varchar course_name
        varchar implementation_semester
        integer recommended_period
        boolean is_required
        boolean is_active
        text prerequeriments
        varchar academic_level
        timestamptz created_at
        timestamptz updated_at
    }

    COMPONENT_PUBLIC_SHARES {
        uuid id PK
        uuid component_id FK
        uuid created_by FK
        varchar token UK
        timestamptz expires_at
        timestamptz revoked_at
        timestamptz created_at
        timestamptz updated_at
    }

    USER_INVITE_SHORT_LINKS {
        uuid id PK
        varchar short_code UK
        text invite_token
        varchar recipient_email
        timestamptz expires_at
        timestamptz created_at
        timestamptz updated_at
    }

    USERS ||--o{ COMPONENTS : creates
    USERS ||--o{ COMPONENT_DRAFTS : creates
    USERS ||--o{ COMPONENT_LOGS : updates
    USERS ||--o{ COMPONENT_PUBLIC_SHARES : creates

    DEPARTMENTS ||--o{ COMPONENTS : owns
    DEPARTMENTS ||--o{ COMPONENT_DRAFTS : owns

    COMPONENTS ||--o| COMPONENT_WORKLOADS : has
    COMPONENT_DRAFTS ||--o| COMPONENT_WORKLOADS : has

    COMPONENTS ||--o| COMPONENT_DRAFTS : active_draft
    COMPONENTS ||--o| COMPONENT_DRAFTS : draft_of

    COMPONENTS ||--o{ COMPONENT_LOGS : records
    COMPONENT_DRAFTS ||--o{ COMPONENT_LOGS : records

    COMPONENTS ||--o{ COMPONENT_RELATIONS : has
    COMPONENTS ||--o{ COMPONENT_CURRICULUM_CONTEXTS : appears_in
    COMPONENTS ||--o{ COMPONENT_PUBLIC_SHARES : shares
```

## Regras de integridade relevantes

- `departments.name` e `departments.code` possuem unicidade normalizada por migration.
- `components.department_id` referencia `departments.id` com `ON DELETE SET NULL`.
- `component_drafts.department_id` referencia `departments.id` com `ON DELETE SET NULL`.
- Novos componentes criados manualmente, rascunhos, aprovacoes e imports SIGAA/SIAC passam a resolver/criar `Department` e preencher `department_id`.
- A migration `1782000000000-backfillComponentDepartments` reconcilia dados de producao: cria departamentos faltantes a partir dos textos existentes e preenche `department_id`.
- `component_curriculum_contexts` representa os contextos de matriz curricular extraidos do SIGAA e pertence a `components`.
