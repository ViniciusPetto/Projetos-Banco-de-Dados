## :bust_in_silhouette:  (23/08/2026 17:31)
A partir da query produzida, conseguiria me explicar o que significa:
"constraint pk_atendente primary key (codigo),
constraint fk_atendente_pessoa foreign key (codigo) references pessoa(codigo)"?
## :speech_balloon: SSMS
GitHub Copilot

Explicação curta e direta:

- `constraint pk_atendente primary key (codigo)`
  - Define a restrição de chave primária chamada `pk_atendente` sobre a coluna `codigo` da tabela `atendente`.
  - Garante que `codigo` seja único e não nulo em `atendente`.
  - Cria automaticamente um índice clustered (por padrão) para permitir buscas rápidas pela chave.

- `constraint fk_atendente_pessoa foreign key (codigo) references pessoa(codigo)`
  - Define uma restrição de chave estrangeira chamada `fk_atendente_pessoa` na mesma coluna `codigo`.
  - Obrigatoriamente o valor de `atendente.codigo` deve existir em `pessoa.codigo` — garante integridade referencial.
  - Implica que não é possível inserir em `atendente` um `codigo` que não exista em `pessoa` e que, por padrão, não é possível excluir/alterar a linha em `pessoa` enquanto houver dependentes em `atendente` (comportamento padrão: NO ACTION / RESTRICT), salvo se for especificado `ON DELETE/ON UPDATE CASCADE` ou outro comportamento.

Interpretação prática:
- Como a mesma coluna `codigo` é PK em `atendente` e FK para `pessoa`, isso normalmente modela uma relação 1:1 (ou especialização/subtipo): cada `atendente` é também uma `pessoa` e usa o mesmo identificador.

___

## :bust_in_silhouette:
Toda chave primária que eu utilizar, precisarei usar constraint (nome da chave) primary key (nome do campo no banco)?
## :speech_balloon: SSMS
**Não, é opcional.**

SQL Server oferece três formas de definir chave primária:

**1. Com nome explícito (recomendado)**
```sql
constraint pk_atendente primary key (codigo)
```
— Você nomeou a constraint. Melhor para identificar em erros e scripts de alteração.

**2. Sem nome (SQL Server gera automaticamente)**
```sql
primary key (codigo)
```
— SQL Server cria um nome genérico internamente (ex.: `PK__atendente__...`).

**3. Inline (apenas para coluna única)**
```sql
codigo INT PRIMARY KEY
```
— Sintaxe compacta. Equivalente às anteriores.

**Boa prática:**
- Use **opção 1** (com nome explícito) em scripts de produção — facilita manutenção, debugging e referência em logs de erro.
- Opções 2 e 3 são aceitáveis para protótipos ou queries ad-hoc.

Todos os três cenários criam a mesma constraint logicamente. A diferença é apenas na legibilidade e rastreabilidade.

___

## :bust_in_silhouette:
Como eu uso o dropdatabase em uma base de dados que está em uso atualmente?
## :speech_balloon: SSMS
**Não é possível fazer `DROP` em um banco que você está usando no momento.**

SQL Server impedirá a operação. Você precisa:

**Solução 1: Trocar de conexão (mais simples)**
1. No SSMS, desconecte-se de `VendaLivros`
2. Abra uma nova janela de query e conecte ao banco `master` (ou qualquer outro banco)
3. Então execute:
```sql
DROP DATABASE VendaLivros
```

**Solução 2: Forçar encerramento de conexões (se houver outros usuários conectados)**
```sql
-- Conecte ao master primeiro
USE master
GO

-- Coloque o banco em modo SINGLE_USER e finalize todas as conexões
ALTER DATABASE VendaLivros SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

-- Agora pode fazer DROP
DROP DATABASE VendaLivros
GO
```

**Explicação:**
- `ALTER DATABASE ... SET SINGLE_USER WITH ROLLBACK IMMEDIATE` — força desconexão de todos os usuários, revertem transações abertas e libera o banco para exclusão.
- Sem isso, SQL Server retorna erro: `Cannot drop database "VendaLivros" because it is currently in use.`

**Resumo:**
- Mude a conexão para outro banco primeiro (recomendado).
- Ou use `ALTER DATABASE ... SET SINGLE_USER` antes de `DROP`.

___

## :bust_in_silhouette:
Como eu me desconecto de VendaLivros?
## :speech_balloon: SSMS
**Executando o que você já tem, está correto:**
```sql
use master
drop database VendaLivros
```

**Explicação:**
- `USE master` muda o contexto da sessão atual para o banco `master` — você se "desconecta" de `VendaLivros` nessa janela.
- Assim, `DROP DATABASE VendaLivros` funciona porque você não está mais usando o banco que quer excluir.

**Mas cuidado:**
Se você tem **outras janelas de query abertas** conectadas a `VendaLivros`, o `DROP` ainda falhará. Nesse caso:

1. Feche todas as abas/janelas conectadas a `VendaLivros`
2. Ou execute em cada uma delas:
```sql
USE master
   GO
```
3. Depois execute o `DROP`

**Forma alternativa (se quiser garantir):**
```sql
USE master
GO

ALTER DATABASE VendaLivros SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

DROP DATABASE VendaLivros
GO
```

Isso encerra **todas** as conexões de qualquer origem e já pode fazer `DROP` sem depender de fechar manualmente outras abas.

___

## :bust_in_silhouette:
Qual a funcionalidade do SQL Server que permite gerar um esquema visual do banco de dados atual?
## :speech_balloon: SSMS
A funcionalidade é chamada **Database Diagrams** (Diagramas de Banco de Dados).

**Como usar no SSMS:**

1. **Object Explorer** → Expanda seu banco de dados (`VendaLivros`)
2. Clique com botão direito em **Database Diagrams**
3. Selecione **New Database Diagram**
4. Escolha as tabelas a incluir (ou adicione depois)
5. O SSMS gera um diagrama visual mostrando:
   - Tabelas com suas colunas
   - Relacionamentos (chaves estrangeiras) com linhas conectando as tabelas
   - Tipos de dados e restrições

**Resultado:**
Um diagrama ER (Entity-Relationship) visual que mostra a estrutura de `pessoa → cliente`, `pessoa → atendente`, e `livro` de forma gráfica.

---

**⚠️ Limitações:**

- **Database Diagrams não está disponível em Azure SQL Database** (versão em nuvem).
- Requer permissões específicas no banco.
- Pode estar desabilitado em algumas edições.

**Alternativas se Database Diagrams não funcionar:**

1. **Object Explorer** — navegue tabelas e visualize propriedades manualmente.
2. **Ferramentas de terceiros** — SolarWinds DPA, Redgate SQL Toolbelt, Lucidchart, dbdiagram.io.
3. **Scripts T-SQL** — consulte `sys.tables`, `sys.columns`, `sys.foreign_keys` para gerar diagramas programaticamente.

___

## :bust_in_silhouette:
Qual o comando uso pra ver a situação atual do banco de dados, como tabelas, chaves primárias, secundárias, estrangeiras, etc?
## :speech_balloon: SSMS
**Existem várias formas em SQL Server:**

---

## **1. Stored Procedures do Sistema (mais simples)**
```sql
-- Informações gerais da tabela
sp_help 'cliente'
GO

-- Apenas restrições (PK, FK, CHECK, UNIQUE)
sp_helpconstraint 'cliente'
GO

-- Apenas índices
sp_helpindex 'cliente'
GO
```

---

## **2. Vistas de Sistema (System Catalog Views) — mais completo**
```sql
-- Todas as tabelas do banco
SELECT * FROM sys.tables
GO

-- Colunas de uma tabela
SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('cliente')
GO

-- Chaves primárias
SELECT * FROM sys.key_constraints WHERE type = 'PK'
GO

-- Chaves estrangeiras
SELECT * FROM sys.foreign_keys
GO

-- Todas as constraints
SELECT * FROM sys.constraints
GO

-- Índices
SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('cliente')
GO
```

---

## **3. Object Explorer (GUI — mais intuitivo)**

1. Clique em **Object Explorer** → seu banco (`VendaLivros`)
2. Expanda **Tables**
3. Clique com botão direito em uma tabela → **View Dependencies** ou **Design**
4. Você vê colunas, tipos, constraints e relacionamentos

---

## **Comando prático (recomendado para análise rápida):**
```sql
USE VendaLivros
GO

-- Visão geral completa
sp_help 'cliente'
sp_helpconstraint 'cliente'
sp_helpindex 'cliente'
GO
```

**Resumo:**
- **Rápido & visual**: use **Object Explorer**
- **Análise detalhada**: use `sp_help` + `sp_helpconstraint`
- **Consultasgranulares**: use `sys.tables`, `sys.foreign_keys`, `sys.constraints`

___

## :bust_in_silhouette:
Estou com uma base de dados pronta e revisada, e preciso fazer alguns procedimentos de CRUD nela, mas pra essas operações é necessário usar procedures, views e triggers. Levando em consideração o script da criação da base de dados, quais operações você considera que são necessárias o uso de triggers, views e procedures? Desconsidere operações simples, em que não é necessário transacionar, pois estamos em busca de operações mais complexas, como uma transação com duas ou mais operações, ou uma única operação que possua joins, por exemplo.

Fiz um comentário ao final do documento de alguma operações que usarão transactions, que podem ser procedures ou triggers. No momento não quero que você mexa em nada no documento SQL, apenas traga sugestão de operações e verifique se as operações que comentei estão corretas para usar
## :speech_balloon: SSMS
Preciso revisar o arquivo com o script da base de dados e seus comentários sobre as operações com transactions para fazer uma análise precisa.

**Você pode compartilhar:**

1. O arquivo SQL completo da criação de `VendaLivros` (o que você tem em E:\Documents\...\Script VendaLiivros.sql)
2. Os comentários que você adicionou ao final indicando quais operações usarão transactions

Desta forma poderei:
- ✅ Verificar se suas sugestões de operações com transactions estão corretas
- ✅ Sugerir onde usar **procedures** (operações multi-passo com lógica)
- ✅ Sugerir onde usar **views** (consultas complexas com joins reutilizáveis)
- ✅ Sugerir onde usar **triggers** (validações e efeitos colaterais automáticos)

**Exemplo de operações complexas que você pode estar considerando:**
- Vender um livro → atualizar `qtd_estoque` + criar registro de venda (2+ operações)
- Registrar novo cliente → inserir em `pessoa` + inserir em `cliente` (2 operações, FK)
- Excluir cliente → verificar dependências + apagar dados (validação + transaction)

Compartilhe o arquivo para eu fazer a análise!

___

## :bust_in_silhouette:
Segue em anexo o documento ativo no momento
## :speech_balloon: SSMS
Excelente! Analisando o modelo `NexusImoveis`, identifiquei as operações complexas que necessitam de **Procedures**, **Views** e **Triggers**:

---

## **PROCEDURES (Operações Multi-Passo com Transactions)**

### **Cadastros Complexos (Herança de Pessoas):**
1. ✅ `sp_CadastrarPessoaFisica` — INSERT `pessoa` + INSERT `pessoa_fisica` (2 ops, FK)
2. ✅ `sp_CadastrarPessoaJuridica` — INSERT `pessoa` + INSERT `pessoa_juridica` (2 ops, FK)
3. ✅ `sp_CadastrarVistoriador` — INSERT `pessoa` + INSERT `funcionario` + INSERT `vistoriador` (3 ops, FK em cascata)
4. ✅ `sp_CadastrarAgente` — INSERT `pessoa` + INSERT `funcionario` + INSERT `agente` (3 ops, FK em cascata)
5. ✅ `sp_CadastrarProprietario` — INSERT `pessoa` + INSERT `cliente` + INSERT `proprietario` (3 ops, FK em cascata)
6. ✅ `sp_CadastrarLocatario` — INSERT `pessoa` + INSERT `cliente` + INSERT `locatario` (3 ops, FK em cascata)

### **Operações de Negócio Complexas:**
7. ✅ `sp_CriarContrato` — Validar crédito do locatário + INSERT contrato + atualizar status do imóvel (3 ops, validação + transactions)
8. ✅ `sp_EncerrarContrato` — UPDATE contrato + gerar vistoria final + listar reparos pendentes (multi-passo com lógica)
9. ✅ `sp_RegistrarVistoria` — INSERT vistoria + gerar reparos associados (2 ops, transaction)
10. ✅ `sp_AgendarVisita` — Validar disponibilidade do agente + verificar horário + INSERT agendamento (validação + transaction)
11. ✅ `sp_AtualizarDisponibilidadeVistoriador` — UPDATE vistoriador + verificar vistorias pendentes (lógica condicional)
12. ✅ `sp_ExcluirPessoa` — Validar dependências + DELETE em cascata com verificações (validação + transaction)

---

## **VIEWS (Consultas Complexas com JOINs Reutilizáveis)**

1. ✅ `vw_ImoveisDisponiveis` — JOIN `imovel` + `proprietario` + `pessoa_fisica/juridica`, filtrando por status
2. ✅ `vw_HistoricoContratosPorLocatario` — JOIN `contrato` + `locatario` + `pessoa_fisica` + `imovel` + `proprietario`
3. ✅ `vw_DetalhesImovel` — JOIN `imovel` + `proprietario` + `pessoa` + contagem de vistorias/contratos
4. ✅ `vw_RelatorioAgentes` — JOIN `agente` + `funcionario` + `pessoa_fisica`, com comissões
5. ✅ `vw_VistoriasPorImovel` — JOIN `vistoria` + `imovel` + `vistoriador` + `pessoa_fisica`, com status de reparos
6. ✅ `vw_ImoveisComReparosPendentes` — JOIN `imovel` + `vistoria` + `reparo`, filtrando por status de reparo
7. ✅ `vw_DashboardLocatario` — JOIN `locatario` + `pessoa_fisica` + `contrato` + `imovel` + `proprietario`
8. ✅ `vw_AgendamentosProximosMeses` — JOIN `agendamento` + `agente` + `locatario` + `pessoa_fisica`, com filtro de datas

---

## **TRIGGERS (Validações e Efeitos Colaterais Automáticos)**

1. ✅ `tr_AtualizarStatusImovelContrato` — Ao INSERT/UPDATE `contrato`, atualizar `status_anuncio` do imóvel para "ALUGADO"
2. ✅ `tr_LiberarStatusImovelFimContrato` — Ao UPDATE `contrato` (fim), reverter `status_anuncio` para "DISPONÍVEL"
3. ✅ `tr_ValidarDisponibilidadeVistoriador` — Ao INSERT `vistoria`, validar que `vistoriador.disponibilidade = 1`
4. ✅ `tr_ValidarFormatoCPF` — Ao INSERT/UPDATE `pessoa_fisica`, validar formato/dígitos de CPF (usa função de validação)
5. ✅ `tr_ValidarFormatoCNPJ` — Ao INSERT/UPDATE `pessoa_juridica`, validar formato/dígitos de CNPJ
6. ✅ `tr_PreventirDeleteDePessoaComDependencias` — Ao DELETE `pessoa`, validar que não há contratos/imóveis ativos
7. ✅ `tr_PreventirRepetirAgendamento` — Ao INSERT `agendamento`, validar que agente não tem outro agendamento no mesmo horário
8. ✅ `tr_AuditoriaAlteracoesPessoa` — Ao INSERT/UPDATE/DELETE `pessoa`, registrar em tabela de auditoria (logs)

---

## **RESUMO RECOMENDADO:**

| Tipo | Qtd | Prioridade | Complexidade |
|------|-----|-----------|--------------|
| **Procedures** | 12 | 🔴 Alta | ⭐⭐⭐⭐⭐ |
| **Views** | 8 | 🟡 Média | ⭐⭐⭐ |
| **Triggers** | 8 | 🟡 Média | ⭐⭐⭐⭐ |

**Próximos passos:**
- Quer que eu desenvolva alguma procedure específica primeiro?
- Quer começar pelas views de consulta?
- Ou prefere começar pelos triggers de validação?

___

## :bust_in_silhouette:
Poderia me detalhar porque as seguintes operações de procedures de fato serão usadas como procedures? Ou porque são operações mais complexas?

7.	✅ sp_CriarContrato — Validar crédito do locatário + INSERT contrato + atualizar status do imóvel (3 ops, validação + transactions)
8.	✅ sp_EncerrarContrato — UPDATE contrato + gerar vistoria final + listar reparos pendentes (multi-passo com lógica)
9.	✅ sp_RegistrarVistoria — INSERT vistoria + gerar reparos associados (2 ops, transaction)
10.	✅ sp_AgendarVisita — Validar disponibilidade do agente + verificar horário + INSERT agendamento (validação + transaction)
11.	✅ sp_AtualizarDisponibilidadeVistoriador — UPDATE vistoriador + verificar vistorias pendentes (lógica condicional)
12.	✅ sp_ExcluirPessoa — Validar dependências + DELETE em cascata com verificações (validação + transaction)
## :speech_balloon: SSMS
Excelente pergunta! Vou detalhar cada uma com exemplos práticos de **por que são operações complexas**:

---

## **7. `sp_CriarContrato` — Validar crédito + INSERT + UPDATE**

**Por que é uma Procedure:**
```sql
-- SEM PROCEDURE (problemático):
-- Problema 1: Validações precisam acontecer antes do INSERT
SELECT status_analise_credito FROM locatario WHERE id_pessoa = 5
-- Se status = 'REPROVADO', não deveria inserir contrato!

-- Problema 2: Múltiplas operações desacopladas
INSERT INTO contrato (id_pessoa, id_imovel, ...) VALUES (5, 10, ...)
-- E depois atualizar o imóvel:
UPDATE imovel SET status_anuncio = 'ALUGADO' WHERE id_imovel = 10
-- Se a primeira INSERT falhar e a segunda suceder? Estado inconsistente!

-- COM PROCEDURE (correto):
CREATE PROCEDURE sp_CriarContrato
    @id_locatario INT,
    @id_imovel INT,
    @data_inicio DATE,
    @valor NUMERIC(10,2),
    @numero_meses INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- 1️⃣ VALIDAÇÃO: Crédito do locatário
        DECLARE @status_credito VARCHAR(20)
        SELECT @status_credito = status_analise_credito 
        FROM locatario 
        WHERE id_pessoa = @id_locatario
        
        IF @status_credito != 'APROVADO'
        BEGIN
            THROW 50001, 'Crédito não aprovado', 1
        END
        
        -- 2️⃣ VALIDAÇÃO: Imóvel disponível?
        DECLARE @status_imovel VARCHAR(20)
        SELECT @status_imovel = status_anuncio 
        FROM imovel 
        WHERE id_imovel = @id_imovel
        
        IF @status_imovel != 'DISPONÍVEL'
        BEGIN
            THROW 50002, 'Imóvel não disponível', 1
        END
        
        -- 3️⃣ INSERT contrato
        INSERT INTO contrato 
        (id_pessoa, id_imovel, status_proprietario, status_locatario, 
         data_inicio, data_fim, valor, numero_meses)
        VALUES (@id_locatario, @id_imovel, 1, 1, @data_inicio, NULL, @valor, @numero_meses)
        
        -- 4️⃣ UPDATE imóvel (ATOMICIDADE: se INSERT falha, isso não executa)
        UPDATE imovel 
        SET status_anuncio = 'ALUGADO' 
        WHERE id_imovel = @id_imovel
        
        COMMIT TRANSACTION
        PRINT 'Contrato criado com sucesso'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        THROW
    END CATCH
END
```

**Por que é complexa:**
- ✅ **Múltiplas validações** antes de inserir
- ✅ **Transaction obrigatória** — se o UPDATE falhar após INSERT, a base fica inconsistente
- ✅ **Efeito colateral** — ao criar contrato, deve automaticamente mudar status do imóvel
- ✅ **Lógica condicional** — precisa checar crédito e disponibilidade antes de prosseguir

---

## **8. `sp_EncerrarContrato` — UPDATE + Gerar vistoria + Listar reparos**

**Por que é uma Procedure:**
```sql
-- SEM PROCEDURE (problemático):
-- Usuário tem que fazer 3 queries manuais em ordem:
UPDATE contrato SET data_fim = GETDATE(), status_locatario = 0 WHERE id_contrato = 5
-- Oops, se esquecer, ou errar a ordem, gera inconsistência!

-- Depois listar imóvel:
SELECT id_imovel FROM contrato WHERE id_contrato = 5

-- Depois criar vistoria final (OBRIGATÓRIO por business rule):
INSERT INTO vistoria (id_imovel, id_pessoa, tipo, data_vistoria) VALUES (...)
-- Mas e se a vistoria não for criada? Contrato fica encerrado mas sem vistoria final!

-- COM PROCEDURE (correto):
CREATE PROCEDURE sp_EncerrarContrato
    @id_contrato INT,
    @id_vistoriador INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- 1️⃣ Pega dados do contrato
        DECLARE @id_imovel INT, @data_fim DATE = GETDATE()
        SELECT @id_imovel = id_imovel 
        FROM contrato 
        WHERE id_contrato = @id_contrato
        
        IF @id_imovel IS NULL
        BEGIN
            THROW 50003, 'Contrato não encontrado', 1
        END
        
        -- 2️⃣ UPDATE contrato
        UPDATE contrato 
        SET data_fim = @data_fim, status_locatario = 0 
        WHERE id_contrato = @id_contrato
        
        -- 3️⃣ OBRIGATÓRIO: Criar vistoria final (business rule)
        INSERT INTO vistoria 
        (id_imovel, id_pessoa, tipo, data_vistoria, descricao_estado_conservacao)
        VALUES (@id_imovel, @id_vistoriador, 'FINAL', @data_fim, '')
        
        -- 4️⃣ UPDATE imóvel: voltar a DISPONÍVEL
        UPDATE imovel 
        SET status_anuncio = 'DISPONÍVEL' 
        WHERE id_imovel = @id_imovel
        
        -- 5️⃣ RETORNAR reparos pendentes (para notificação)
        SELECT num_reparo, descricao_necessidade, responsabilidade_financeira
        FROM reparo r
        JOIN vistoria v ON r.id_vistoria = v.id_vistoria
        WHERE v.id_imovel = @id_imovel AND r.status_notificacao = 'PENDENTE'
        
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        THROW
    END CATCH
END
```

**Por que é complexa:**
- ✅ **5 operações diferentes** (SELECT, UPDATE, INSERT, UPDATE, SELECT)
- ✅ **Lógica de negócio** — vistoria final é OBRIGATÓRIA (não pode deixar para o usuário fazer)
- ✅ **Transaction** — se vistoria falhar, não quer deixar contrato encerrado
- ✅ **Retorna dados** — lista reparos pendentes para propriétário ser notificado
- ✅ **Cascata de updates** — contrato + imóvel precisam estar sincronizados

---

## **9. `sp_RegistrarVistoria` — INSERT vistoria + Gerar reparos**

**Por que é uma Procedure:**
```sql
-- SEM PROCEDURE (problemático):
INSERT INTO vistoria (id_imovel, id_pessoa, tipo, data_vistoria) 
VALUES (10, 5, 'ENTRADA', GETDATE())

-- Depois, usuário teria que:
-- 1. Pegar o ID da vistoria gerada (SCOPE_IDENTITY)
-- 2. Inserir cada reparo manualmente
-- 3. Se fizer 1 reparo e esquecer o outro, ficam inconsistentes

-- COM PROCEDURE (correto):
CREATE PROCEDURE sp_RegistrarVistoria
    @id_imovel INT,
    @id_vistoriador INT,
    @tipo CHAR(7),
    @descricao_estado VARCHAR(500),
    @reparos_xml XML  -- Recebe lista de reparos
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- 1️⃣ INSERT vistoria
        DECLARE @id_vistoria INT
        INSERT INTO vistoria (id_imovel, id_pessoa, tipo, descricao_estado_conservacao, data_vistoria)
        VALUES (@id_imovel, @id_vistoriador, @tipo, @descricao_estado, GETDATE())
        
        SET @id_vistoria = SCOPE_IDENTITY()
        
        -- 2️⃣ INSERT todos os reparos AUTOMATICAMENTE (em um loop)
        -- Se houver erro, TUDO reverte (vistoria + reparos)
        INSERT INTO reparo (id_vistoria, data_reparo, status_notificacao, 
                           responsabilidade_financeira, descricao_necessidade)
        SELECT 
            @id_vistoria,
            GETDATE(),
            'PENDENTE',
            r.value('(responsabilidade)[1]', 'CHAR(12)'),
            r.value('(descricao)[1]', 'VARCHAR(500)')
        FROM @reparos_xml.nodes('//reparo') AS t(r)
        
        -- 3️⃣ UPDATE vistoriador: marcar como ocupado
        UPDATE vistoriador 
        SET disponibilidade = 0 
        WHERE id_pessoa = @id_vistoriador
        
        COMMIT TRANSACTION
        PRINT 'Vistoria registrada com sucesso'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        THROW
    END CATCH
END
```

**Por que é complexa:**
- ✅ **INSERT + Looping** — 1 vistoria + múltiplos reparos (quantos forem necessários)
- ✅ **SCOPE_IDENTITY** — precisa capturar o ID gerado da vistoria para criar reparos
- ✅ **Transaction** — se inserir 1 reparo e falhar no 2º, toda vistoria reverte
- ✅ **Processamento de XML** — aceita múltiplos reparos como parâmetro
- ✅ **Efeito colateral** — marca vistoriador como indisponível

---

## **10. `sp_AgendarVisita` — Validar disponibilidade + Verificar horário + INSERT**

**Por que é uma Procedure:**
```sql
-- SEM PROCEDURE (problemático):
-- Verificar se agente está disponível
SELECT disponibilidade FROM agente WHERE id_pessoa = 3
-- Validar se agente não tem outro agendamento no mesmo horário
SELECT COUNT(*) FROM agendamento 
WHERE id_agente = 3 AND data_visita = '2026-11-15' AND hora_visita = '14:00'
-- Depois inserir
INSERT INTO agendamento VALUES (3, 5, '2026-11-15', '14:00')
-- Problema: Race condition! Entre a validação e insert, outro usuário pode agendar!

-- COM PROCEDURE (correto com LOCK):
CREATE PROCEDURE sp_AgendarVisita
    @id_agente INT,
    @id_locatario INT,
    @data_visita DATE,
    @hora_visita TIME
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- 1️⃣ LOCK a tabela agendamento (evita race condition)
        -- 2️⃣ Validar disponibilidade do agente
        DECLARE @disponibilidade BIT
        SELECT @disponibilidade = disponibilidade 
        FROM agente 
        WHERE id_pessoa = @id_agente
        
        IF @disponibilidade = 0
        BEGIN
            THROW 50004, 'Agente não disponível', 1
        END
        
        -- 3️⃣ Validar se agente não tem agendamento no mesmo horário
        IF EXISTS (SELECT 1 FROM agendamento 
                   WHERE id_agente = @id_agente 
                   AND data_visita = @data_visita 
                   AND hora_visita = @hora_visita)
        BEGIN
            THROW 50005, 'Agente já tem agendamento neste horário', 1
        END
        
        -- 4️⃣ Validar se locatário não tem outro agendamento no mesmo horário
        IF EXISTS (SELECT 1 FROM agendamento 
                   WHERE id_locatario = @id_locatario 
                   AND data_visita = @data_visita 
                   AND hora_visita = @hora_visita)
        BEGIN
            THROW 50006, 'Locatário já tem agendamento neste horário', 1
        END
        
        -- 5️⃣ INSERT agendamento
        INSERT INTO agendamento (id_agente, id_locatario, data_visita, hora_visita)
        VALUES (@id_agente, @id_locatario, @data_visita, @hora_visita)
        
        COMMIT TRANSACTION
        PRINT 'Agendamento realizado com sucesso'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        THROW
    END CATCH
END
```

**Por que é complexa:**
- ✅ **Múltiplas validações** (3 SELECTs antes do INSERT)
- ✅ **Race condition** — precisa de LOCK exclusivo na transaction
- ✅ **Business rules** — agente e locatário não podem ter conflito de horário
- ✅ **Transaction obrigatória** — validações devem ser atômicas com INSERT

---

## **11. `sp_AtualizarDisponibilidadeVistoriador` — UPDATE + Lógica condicional**

**Por que é uma Procedure:**
```sql
-- SEM PROCEDURE (problemático):
UPDATE vistoriador SET disponibilidade = 0 WHERE id_pessoa = 5
-- Mas como decide quando marcar como disponível novamente?
-- Manual? Automático baseado em vistorias pendentes? Não há lógica!

-- COM PROCEDURE (com lógica):
CREATE PROCEDURE sp_AtualizarDisponibilidadeVistoriador
    @id_vistoriador INT,
    @disponibilidade BIT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- 1️⃣ Se tentar ATIVAR disponibilidade
        IF @disponibilidade = 1
        BEGIN
            -- Verificar se tem vistorias pendentes
            DECLARE @vistorias_pendentes INT
            SELECT @vistorias_pendentes = COUNT(*) 
            FROM vistoria 
            WHERE id_pessoa = @id_vistoriador 
            AND CAST(data_vistoria AS DATE) > CAST(GETDATE() AS DATE)
            
            -- Só pode ativar se NÃO tem vistorias futuras agendadas
            IF @vistorias_pendentes > 0
            BEGIN
                THROW 50007, 'Vistoriador tem vistorias agendadas para o futuro', 1
            END
        END
        
        -- 2️⃣ UPDATE disponibilidade
        UPDATE vistoriador 
        SET disponibilidade = @disponibilidade 
        WHERE id_pessoa = @id_vistoriador
        
        COMMIT TRANSACTION
        PRINT 'Disponibilidade atualizada com sucesso'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        THROW
    END CATCH
END
```

**Por que é complexa:**
- ✅ **Lógica condicional** — comportamento diferente baseado no valor
- ✅ **Validação de regra de negócio** — não pode ficar disponível se tem vistoria agendada
- ✅ **SELECT + UPDATE** — precisa consultar antes de decidir se atualiza

---

## **12. `sp_ExcluirPessoa` — Validar dependências + DELETE em cascata**

**Por que é uma Procedure:**
```sql
-- SEM PROCEDURE (PERIGOSO):
DELETE FROM pessoa WHERE id_pessoa = 5
-- Problema: Sem validação, pode apagar pessoa com:
-- - Contratos ativos
-- - Imóveis alugados
-- - Agendamentos pendentes
-- - Vistorias não concluídas
-- Desastre! Estado completamente inconsistente!

-- COM PROCEDURE (seguro):
CREATE PROCEDURE sp_ExcluirPessoa
    @id_pessoa INT,
    @force_delete BIT = 0
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- 1️⃣ VALIDAR: Contratos ativos?
        IF EXISTS (SELECT 1 FROM contrato c
                   JOIN locatario l ON c.id_pessoa = l.id_pessoa
                   WHERE l.id_pessoa = @id_pessoa AND c.data_fim IS NULL)
        BEGIN
            IF @force_delete = 0
                THROW 50008, 'Pessoa tem contratos ativos. Use @force_delete = 1', 1
            -- Se force_delete = 1, encerrar contratos
            UPDATE contrato SET data_fim = GETDATE() 
            WHERE id_imovel IN (SELECT id_imovel FROM imovel WHERE id_pessoa = @id_pessoa)
        END
        
        -- 2️⃣ VALIDAR: Imóveis ativos?
        IF EXISTS (SELECT 1 FROM imovel 
                   WHERE id_pessoa = @id_pessoa 
                   AND status_anuncio != 'REMOVIDO')
        BEGIN
            IF @force_delete = 0
                THROW 50009, 'Pessoa tem imóveis ativos', 1
            -- Se force_delete = 1, remover imóveis
            UPDATE imovel SET status_anuncio = 'REMOVIDO' WHERE id_pessoa = @id_pessoa
        END
        
        -- 3️⃣ VALIDAR: Agendamentos pendentes?
        DECLARE @id_agente INT
        SELECT @id_agente = id_pessoa FROM agente WHERE id_pessoa = @id_pessoa
        
        IF @id_agente IS NOT NULL AND EXISTS (
            SELECT 1 FROM agendamento 
            WHERE id_agente = @id_agente 
            AND data_visita > CAST(GETDATE() AS DATE))
        BEGIN
            IF @force_delete = 0
                THROW 50010, 'Agente tem agendamentos pendentes', 1
            -- Se force_delete = 1, deletar agendamentos
            DELETE FROM agendamento WHERE id_agente = @id_agente
        END
        
        -- 4️⃣ DELETE SEGURO (ON DELETE CASCADE cuida do resto)
        DELETE FROM pessoa WHERE id_pessoa = @id_pessoa
        
        COMMIT TRANSACTION
        PRINT 'Pessoa deletada com sucesso'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        THROW
    END CATCH
END
```

**Por que é complexa:**
- ✅ **Múltiplas validações** (verificar 3+ dependências)
- ✅ **Lógica condicional** — comportamento baseado em `@force_delete`
- ✅ **Proteção contra erro** — previne apagar pessoa com dados ativos
- ✅ **Transaction obrigatória** — deve revalidar antes de cada DELETE
- ✅ **Cascata controlada** — gerencia cascata de DELETEs de forma segura

---

## **RESUMO: Por que são Procedures?**

| Procedure | Razão Principal |
|-----------|-----------------|
| **sp_CriarContrato** | 4 operações (validações + INSERT + UPDATE) + transaction |
| **sp_EncerrarContrato** | 5 operações + obrigação de criar vistoria final + retorna dados |
| **sp_RegistrarVistoria** | Looping de reparos + SCOPE_IDENTITY + múltiplas operações |
| **sp_AgendarVisita** | 3 validações + race condition + lock necessário |
| **sp_AtualizarDisponibilidade** | Lógica condicional + validação antes de atualizar |
| **sp_ExcluirPessoa** | 3+ validações + cascata controlada + force delete |

**Todos compartilham:**
- ✅ Múltiplas operações (2+)
- ✅ Transaction obrigatória
- ✅ Validações de business rule
- ✅ Efeitos colaterais (updates relacionados)
- ✅ Lógica condicional ou processamento complexo

**Sem Procedure = Risco de:**
- Inconsistência de dados
- Race conditions
- Regras de negócio não respeitadas
- Código duplicado no cliente

___

## :bust_in_silhouette:
Crie a mesma explicação feita pra procedures, em views e triggers também
## :speech_balloon: SSMS
# VIEWS — Consultas Complexas com JOINs Reutilizáveis

---

## **1. `vw_ImoveisDisponiveis` — Listar imóveis com dados do proprietário**

**Por que é uma View:**
```sql
-- SEM VIEW (problema):
-- Usuário teria que fazer essa query complexa toda vez:
SELECT 
    i.id_imovel, i.endereco, i.valor_aluguel, i.area_m2,
    pf.nome, pf.CPF, p.telefone, p.email
FROM imovel i
JOIN proprietario pr ON i.id_pessoa = pr.id_pessoa
JOIN cliente c ON pr.id_pessoa = c.id_pessoa
JOIN pessoa p ON pr.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
WHERE i.status_anuncio = 'DISPONÍVEL'
AND pr.preferencia_contato IS NOT NULL
ORDER BY i.valor_aluguel ASC

-- Problema: Query longa, fácil de errar joins, precisa repetir em múltiplas telas

-- COM VIEW (correto):
CREATE VIEW vw_ImoveisDisponiveis AS
SELECT 
    i.id_imovel,
    i.endereco,
    i.descricao,
    i.valor_aluguel,
    i.area_m2,
    pf.nome AS nome_proprietario,
    pf.CPF,
    p.telefone,
    p.email,
    pr.preferencia_contato,
    i.num_matricula,
    CAST(i.area_m2 AS DECIMAL(10,2)) / NULLIF(i.valor_aluguel, 0) AS preco_por_m2
FROM imovel i
JOIN proprietario pr ON i.id_pessoa = pr.id_pessoa
JOIN cliente c ON pr.id_pessoa = c.id_pessoa
JOIN pessoa p ON pr.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
WHERE i.status_anuncio = 'DISPONÍVEL'
  AND c.status_conta = 1
  AND pf.nome IS NOT NULL
GO

-- Agora usuário faz consulta simples:
SELECT * FROM vw_ImoveisDisponiveis WHERE valor_aluguel BETWEEN 1000 AND 3000
```

**Por que é complexa:**
- ✅ **4 JOINs cascateados** — pessoa → pessoa_física → cliente → proprietário → imóvel
- ✅ **Reutilizável** — múltiplas telas precisam dessa consulta
- ✅ **Cálculo derivado** — preço por m² (lógica de negócio)
- ✅ **Filtro consistente** — status_anuncio, status_conta sempre aplicados

---

## **2. `vw_HistoricoContratosPorLocatario` — Ver todos os contratos de um locatário**

**Por que é uma View:**
```sql
-- SEM VIEW (problemático):
-- Dashboard do locatário teria que fazer joins complexos:
SELECT 
    c.id_contrato, c.data_inicio, c.data_fim, c.valor,
    i.endereco, i.area_m2, i.valor_aluguel,
    pf.nome AS proprietario_nome,
    c.status_proprietario, c.status_locatario
FROM contrato c
JOIN imovel i ON c.id_imovel = i.id_imovel
JOIN proprietario pr ON i.id_pessoa = pr.id_pessoa
JOIN cliente cl ON pr.id_pessoa = cl.id_pessoa
JOIN pessoa p ON cl.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
JOIN locatario l ON c.id_pessoa = l.id_pessoa
WHERE l.id_pessoa = @id_locatario
ORDER BY c.data_inicio DESC

-- Problema: Muitos joins, código duplicado em várias telas

-- COM VIEW (correto):
CREATE VIEW vw_HistoricoContratosPorLocatario AS
SELECT 
    c.id_contrato,
    c.data_inicio,
    c.data_fim,
    c.valor,
    c.numero_meses,
    DATEDIFF(MONTH, c.data_inicio, ISNULL(c.data_fim, GETDATE())) AS meses_decorridos,
    i.endereco,
    i.area_m2,
    pf.nome AS proprietario_nome,
    p.telefone AS proprietario_telefone,
    pr.preferencia_contato,
    CASE 
        WHEN c.data_fim IS NULL THEN 'ATIVO'
        WHEN c.data_fim < CAST(GETDATE() AS DATE) THEN 'ENCERRADO'
        ELSE 'PENDENTE'
    END AS status_contrato,
    c.status_proprietario,
    c.status_locatario,
    c.id_pessoa AS id_locatario
FROM contrato c
JOIN imovel i ON c.id_imovel = i.id_imovel
JOIN proprietario pr ON i.id_pessoa = pr.id_pessoa
JOIN cliente cl ON pr.id_pessoa = cl.id_pessoa
JOIN pessoa p ON cl.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
GO

-- Uso simples:
SELECT * FROM vw_HistoricoContratosPorLocatario WHERE id_locatario = 5
```

**Por que é complexa:**
- ✅ **6 JOINs cascateados** — locatário → contrato → imóvel → proprietário → pessoa
- ✅ **Lógica de negócio** — cálculo de status_contrato usando CASE
- ✅ **Cálculo derivado** — meses_decorridos (DATEDIFF)
- ✅ **Múltiplas telas precisam** — histórico, dashboard, relatórios

---

## **3. `vw_DetalhesImovel` — Visão completa de um imóvel**

**Por que é uma View:**
```sql
-- SEM VIEW (problemático):
-- Tela de detalhes precisaria fazer múltiplas queries:
SELECT * FROM imovel WHERE id_imovel = 10
SELECT COUNT(*) FROM contrato WHERE id_imovel = 10 AND data_fim IS NULL
SELECT COUNT(*) FROM vistoria WHERE id_imovel = 10
SELECT * FROM proprietario WHERE ...
-- Código repetido, lógica espalhada

-- COM VIEW (correto):
CREATE VIEW vw_DetalhesImovel AS
SELECT 
    i.id_imovel,
    i.endereco,
    i.descricao,
    i.foto,
    i.area_m2,
    i.valor_aluguel,
    i.status_anuncio,
    i.num_matricula,
    pf.nome AS proprietario_nome,
    pf.CPF,
    p.telefone,
    p.email,
    pr.preferencia_contato,
    pr.dados_bancarios_agencia,
    pr.dados_bancarios_conta,
    -- Contadores (sub-queries)
    (SELECT COUNT(*) FROM contrato 
     WHERE id_imovel = i.id_imovel AND data_fim IS NULL) AS contratos_ativos,
    (SELECT COUNT(*) FROM vistoria 
     WHERE id_imovel = i.id_imovel) AS total_vistorias,
    (SELECT COUNT(*) FROM reparo r
     JOIN vistoria v ON r.id_vistoria = v.id_vistoria
     WHERE v.id_imovel = i.id_imovel AND r.status_notificacao = 'PENDENTE') AS reparos_pendentes,
    -- Última vistoria
    (SELECT MAX(data_vistoria) FROM vistoria WHERE id_imovel = i.id_imovel) AS data_ultima_vistoria,
    -- Locatário atual
    (SELECT pf2.nome FROM contrato c
     JOIN locatario l ON c.id_pessoa = l.id_pessoa
     JOIN pessoa p2 ON l.id_pessoa = p2.id_pessoa
     JOIN pessoa_fisica pf2 ON p2.id_pessoa = pf2.id_pessoa
     WHERE c.id_imovel = i.id_imovel AND c.data_fim IS NULL) AS locatario_atual
FROM imovel i
JOIN proprietario pr ON i.id_pessoa = pr.id_pessoa
JOIN cliente c ON pr.id_pessoa = c.id_pessoa
JOIN pessoa p ON c.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
GO

-- Uso:
SELECT * FROM vw_DetalhesImovel WHERE id_imovel = 10
```

**Por que é complexa:**
- ✅ **5 JOINs + Sub-queries** — encapsula lógica complexa
- ✅ **Agregações** — contadores de contratos, vistorias, reparos
- ✅ **Correlação** — sub-queries correlacionadas ao imovel
- ✅ **Dados relacionados** — proprietário, locatário, histórico, tudo em uma query
- ✅ **Reutilizável** — tela de detalhes, relatórios, dashboard

---

## **4. `vw_RelatorioAgentes` — Performance de agentes com comissões**

**Por que é uma View:**
```sql
-- SEM VIEW (problemático):
-- Relatório teria que fazer cálculos manuais:
SELECT 
    ag.id_pessoa,
    pf.nome,
    ag.numero_CRECI,
    ag.porcentagem_comissao,
    COUNT(c.id_contrato) AS total_contratos,
    SUM(c.valor) AS valor_total_contratos,
    SUM(c.valor) * ag.porcentagem_comissao AS comissao_total,
    AVG(c.valor) AS valor_medio_contrato
FROM agente ag
JOIN funcionario f ON ag.id_pessoa = f.id_pessoa
JOIN pessoa p ON ag.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
LEFT JOIN agendamento agd ON ag.id_pessoa = agd.id_agente
LEFT JOIN locatario l ON agd.id_locatario = l.id_pessoa
LEFT JOIN contrato c ON l.id_pessoa = c.id_pessoa
GROUP BY ag.id_pessoa, pf.nome, ag.numero_CRECI, ag.porcentagem_comissao

-- Problema: Cálculo de comissão espalhado, código duplicado em relatórios

-- COM VIEW (correto):
CREATE VIEW vw_RelatorioAgentes AS
SELECT 
    ag.id_pessoa,
    pf.nome,
    ag.numero_CRECI,
    ag.porcentagem_comissao,
    f.data_admissao,
    f.salario,
    f.status_ativo,
    COUNT(DISTINCT c.id_contrato) AS total_contratos,
    ISNULL(SUM(c.valor), 0) AS valor_total_contratos,
    ISNULL(SUM(c.valor), 0) * ag.porcentagem_comissao AS comissao_total,
    ISNULL(AVG(c.valor), 0) AS valor_medio_contrato,
    COUNT(DISTINCT agd.id_locatario) AS locatarios_contatados,
    ag.regiao_atuacao
FROM agente ag
JOIN funcionario f ON ag.id_pessoa = f.id_pessoa
JOIN pessoa p ON ag.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
LEFT JOIN agendamento agd ON ag.id_pessoa = agd.id_agente
LEFT JOIN locatario l ON agd.id_locatario = l.id_pessoa
LEFT JOIN contrato c ON l.id_pessoa = c.id_pessoa 
    AND c.data_inicio >= DATEADD(MONTH, -12, GETDATE())  -- Últimos 12 meses
GROUP BY 
    ag.id_pessoa, pf.nome, ag.numero_CRECI, ag.porcentagem_comissao, 
    f.data_admissao, f.salario, f.status_ativo, ag.regiao_atuacao
GO

-- Uso:
SELECT * FROM vw_RelatorioAgentes WHERE status_ativo = 1 ORDER BY comissao_total DESC
```

**Por que é complexa:**
- ✅ **4 JOINs + LEFT JOINs** — agente → funcionário → pessoa → agendamento → contrato
- ✅ **Agregações complexas** — COUNT(DISTINCT), SUM, AVG
- ✅ **Cálculos de negócio** — comissão (soma × porcentagem)
- ✅ **Filtro temporal** — últimos 12 meses
- ✅ **ISNULL** — tratamento de NULLs em agregações
- ✅ **Reutilizável** — relatórios, dashboard, análise de performance

---

## **5. `vw_VistoriasPorImovel` — Histórico de vistorias com status de reparos**

**Por que é uma View:**
```sql
-- SEM VIEW (problemático):
-- Tela de vistorias precisaria fazer joins complexos:
SELECT 
    v.id_vistoria, v.data_vistoria, v.tipo,
    pf.nome AS vistoriador,
    COUNT(r.num_reparo) AS total_reparos,
    SUM(CASE WHEN r.status_notificacao = 'PENDENTE' THEN 1 ELSE 0 END) AS reparos_pendentes
FROM vistoria v
JOIN vistoriador vi ON v.id_pessoa = vi.id_pessoa
JOIN funcionario f ON vi.id_pessoa = f.id_pessoa
JOIN pessoa p ON f.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
LEFT JOIN reparo r ON v.id_vistoria = r.id_vistoria
GROUP BY v.id_vistoria, v.data_vistoria, v.tipo, pf.nome
WHERE v.id_imovel = @id_imovel

-- Problema: Múltiplos joins, GROUP BY complexo, código repetido

-- COM VIEW (correto):
CREATE VIEW vw_VistoriasPorImovel AS
SELECT 
    v.id_vistoria,
    v.id_imovel,
    v.data_vistoria,
    v.tipo,
    pf.nome AS vistoriador_nome,
    v.descricao_estado_conservacao,
    COUNT(r.num_reparo) AS total_reparos,
    SUM(CASE WHEN r.status_notificacao = 'PENDENTE' THEN 1 ELSE 0 END) AS reparos_pendentes,
    SUM(CASE WHEN r.status_notificacao = 'EXECUTADO' THEN 1 ELSE 0 END) AS reparos_executados,
    MAX(r.data_reparo) AS data_ultimo_reparo,
    STRING_AGG(CAST(r.num_reparo AS VARCHAR), ', ') AS ids_reparos
FROM vistoria v
JOIN vistoriador vi ON v.id_pessoa = vi.id_pessoa
JOIN funcionario f ON vi.id_pessoa = f.id_pessoa
JOIN pessoa p ON f.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
LEFT JOIN reparo r ON v.id_vistoria = r.id_vistoria
GROUP BY 
    v.id_vistoria, v.id_imovel, v.data_vistoria, v.tipo, 
    pf.nome, v.descricao_estado_conservacao
GO

-- Uso:
SELECT * FROM vw_VistoriasPorImovel WHERE id_imovel = 10 ORDER BY data_vistoria DESC
```

**Por que é complexa:**
- ✅ **5 JOINs + LEFT JOIN** — vistoria → vistoriador → funcionário → pessoa → reparo
- ✅ **GROUP BY com CASE** — contadores condicionais (pendentes vs executados)
- ✅ **STRING_AGG** — agregação de strings
- ✅ **Lógica de negócio** — status de reparos por vistoria
- ✅ **Reutilizável** — histórico de vistorias, análise de manutenção

---

## **6. `vw_ImoveisComReparosPendentes` — Imóveis que precisam de manutenção**

**Por que é uma View:**
```sql
-- SEM VIEW (problemático):
-- Notificação de reparos precisaria fazer query complexa:
SELECT DISTINCT
    i.id_imovel, i.endereco, i.valor_aluguel,
    pf.nome AS proprietario,
    COUNT(r.num_reparo) AS reparos_pendentes,
    MIN(v.data_vistoria) AS primeira_vistoria
FROM imovel i
JOIN proprietario pr ON i.id_pessoa = pr.id_pessoa
JOIN pessoa p ON pr.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
JOIN vistoria v ON i.id_imovel = v.id_imovel
JOIN reparo r ON v.id_vistoria = r.id_vistoria
WHERE r.status_notificacao = 'PENDENTE'
GROUP BY i.id_imovel, i.endereco, i.valor_aluguel, pf.nome

-- Problema: Query pesada, precisa ser executada frequentemente

-- COM VIEW (correto):
CREATE VIEW vw_ImoveisComReparosPendentes AS
SELECT 
    i.id_imovel,
    i.endereco,
    i.valor_aluguel,
    i.area_m2,
    pf.nome AS proprietario_nome,
    p.telefone AS proprietario_telefone,
    pr.preferencia_contato,
    COUNT(DISTINCT r.num_reparo) AS total_reparos_pendentes,
    MIN(r.data_reparo) AS data_reparo_mais_antiga,
    DATEDIFF(DAY, MIN(r.data_reparo), GETDATE()) AS dias_pendente,
    STRING_AGG(DISTINCT r.responsabilidade_financeira, ', ') AS responsaveis,
    MAX(v.data_vistoria) AS data_ultima_vistoria
FROM imovel i
JOIN proprietario pr ON i.id_pessoa = pr.id_pessoa
JOIN cliente c ON pr.id_pessoa = c.id_pessoa
JOIN pessoa p ON c.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
JOIN vistoria v ON i.id_imovel = v.id_imovel
JOIN reparo r ON v.id_vistoria = r.id_vistoria
WHERE r.status_notificacao = 'PENDENTE'
GROUP BY 
    i.id_imovel, i.endereco, i.valor_aluguel, i.area_m2,
    pf.nome, p.telefone, pr.preferencia_contato
GO

-- Uso: Notificação automática
SELECT * FROM vw_ImoveisComReparosPendentes 
WHERE dias_pendente > 30
ORDER BY dias_pendente DESC
```

**Por que é complexa:**
- ✅ **5 JOINs cascateados**
- ✅ **Agregações + DATEDIFF** — cálculo de dias pendente
- ✅ **STRING_AGG** — lista de responsáveis
- ✅ **GROUP BY completo** — todas as colunas não agregadas
- ✅ **Filtro WHERE + agregação** — apenas reparos pendentes
- ✅ **Reutilizável** — relatório de manutenção, notificações

---

## **7. `vw_DashboardLocatario` — Visão completa do locatário**

**Por que é uma View:**
```sql
-- SEM VIEW (problemático):
-- Dashboard do locatário precisaria de múltiplas queries:
SELECT * FROM locatario WHERE id_pessoa = 5
SELECT * FROM contrato WHERE id_pessoa = 5 AND data_fim IS NULL
SELECT * FROM agendamento WHERE id_locatario = 5
SELECT COUNT(*) FROM vistoria WHERE ...
-- Código espalhado, múltiplas queries

-- COM VIEW (correto):
CREATE VIEW vw_DashboardLocatario AS
SELECT 
    l.id_pessoa,
    pf.nome,
    pf.CPF,
    p.email,
    p.telefone,
    l.renda_mensal,
    l.status_analise_credito,
    c.data_cadastro,
    c.status_conta,
    -- Contrato ativo
    (SELECT c2.id_contrato FROM contrato c2 
     WHERE c2.id_pessoa = l.id_pessoa AND c2.data_fim IS NULL) AS id_contrato_ativo,
    (SELECT i2.endereco FROM contrato c2 
     JOIN imovel i2 ON c2.id_imovel = i2.id_imovel
     WHERE c2.id_pessoa = l.id_pessoa AND c2.data_fim IS NULL) AS endereco_imovel_alugado,
    (SELECT c2.data_inicio FROM contrato c2 
     WHERE c2.id_pessoa = l.id_pessoa AND c2.data_fim IS NULL) AS data_inicio_aluguel,
    (SELECT c2.data_fim FROM contrato c2 
     WHERE c2.id_pessoa = l.id_pessoa AND c2.data_fim IS NULL) AS data_fim_aluguel,
    -- Agendamentos próximos
    (SELECT COUNT(*) FROM agendamento 
     WHERE id_locatario = l.id_pessoa 
     AND data_visita > CAST(GETDATE() AS DATE)) AS agendamentos_futuros,
    -- Histórico
    (SELECT COUNT(*) FROM contrato WHERE id_pessoa = l.id_pessoa) AS total_contratos,
    (SELECT COUNT(DISTINCT id_imovel) FROM contrato WHERE id_pessoa = l.id_pessoa) AS total_imoveis_alugados
FROM locatario l
JOIN cliente c ON l.id_pessoa = c.id_pessoa
JOIN pessoa p ON c.id_pessoa = p.id_pessoa
JOIN pessoa_fisica pf ON p.id_pessoa = pf.id_pessoa
GO

-- Uso:
SELECT * FROM vw_DashboardLocatario WHERE id_pessoa = 5
```

**Por que é complexa:**
- ✅ **Sub-queries correlacionadas** — dados relacionados a um locatário
- ✅ **Agregações** — contadores de contratos, agendamentos
- ✅ **Lógica de negócio** — filtra apenas contratos ativos
- ✅ **Múltiplos dados relacionados** — contrato, imovel, agendamentos, histórico
- ✅ **Reutilizável** — dashboard, tela de perfil

---

## **8. `vw_AgendamentosProximosMeses` — Agenda de visitas futuras**

**Por que é uma View:**
```sql
-- SEM VIEW (problemático):
-- Calendário teria que fazer query com múltiplos JOINs e FILTROs:
SELECT 
    agd.id_agente, agd.id_locatario, agd.data_visita, agd.hora_visita,
    pf_agente.nome AS agente_nome,
    pf_locatario.nome AS locatario_nome,
    l.renda_mensal,
    agf.numero_CRECI
FROM agendamento agd
JOIN agente agf ON agd.id_agente = agf.id_pessoa
JOIN funcionario f_agente ON agf.id_pessoa = f_agente.id_pessoa
JOIN pessoa p_agente ON f_agente.id_pessoa = p_agente.id_pessoa
JOIN pessoa_fisica pf_agente ON p_agente.id_pessoa = pf_agente.id_pessoa
JOIN locatario l ON agd.id_locatario = l.id_pessoa
JOIN pessoa p_locatario ON l.id_pessoa = p_locatario.id_pessoa
JOIN pessoa_fisica pf_locatario ON p_locatario.id_pessoa = pf_locatario.id_pessoa
WHERE agd.data_visita BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(MONTH, 3, GETDATE())
ORDER BY agd.data_visita, agd.hora_visita

-- Problema: Query muito longa, múltiplos JOINs, código duplicado em agendas

-- COM VIEW (correto):
CREATE VIEW vw_AgendamentosProximosMeses AS
SELECT 
    agd.id_agente,
    agd.id_locatario,
    agd.data_visita,
    agd.hora_visita,
    DATEFROMPARTS(YEAR(agd.data_visita), MONTH(agd.data_visita), 1) AS mes_agendamento,
    DATENAME(MONTH, agd.data_visita) AS mes_nome,
    pf_agente.nome AS agente_nome,
    pf_agente.CPF AS agente_cpf,
    p_agente.telefone AS agente_telefone,
    agf.numero_CRECI,
    agf.regiao_atuacao,
    pf_locatario.nome AS locatario_nome,
    pf_locatario.CPF AS locatario_cpf,
    p_locatario.telefone AS locatario_telefone,
    p_locatario.endereco AS endereco_locatario,
    l.renda_mensal,
    l.status_analise_credito,
    DATEDIFF(DAY, CAST(GETDATE() AS DATE), agd.data_visita) AS dias_para_visita,
    CASE 
        WHEN agd.data_visita < CAST(GETDATE() AS DATE) THEN 'ATRASADO'
        WHEN agd.data_visita = CAST(GETDATE() AS DATE) THEN 'HOJE'
        WHEN DATEDIFF(DAY, CAST(GETDATE() AS DATE), agd.data_visita) <= 7 THEN 'PRÓXIMA SEMANA'
        ELSE 'FUTURO'
    END AS status_agendamento
FROM agendamento agd
JOIN agente agf ON agd.id_agente = agf.id_pessoa
JOIN funcionario f_agente ON agf.id_pessoa = f_agente.id_pessoa
JOIN pessoa p_agente ON f_agente.id_pessoa = p_agente.id_pessoa
JOIN pessoa_fisica pf_agente ON p_agente.id_pessoa = pf_agente.id_pessoa
JOIN locatario l ON agd.id_locatario = l.id_pessoa
JOIN cliente c_locatario ON l.id_pessoa = c_locatario.id_pessoa
JOIN pessoa p_locatario ON c_locatario.id_pessoa = p_locatario.id_pessoa
JOIN pessoa_fisica pf_locatario ON p_locatario.id_pessoa = pf_locatario.id_pessoa
WHERE agd.data_visita >= CAST(GETDATE() AS DATE)
GO

-- Uso:
SELECT * FROM vw_AgendamentosProximosMeses 
WHERE status_agendamento IN ('HOJE', 'PRÓXIMA SEMANA')
ORDER BY data_visita, hora_visita
```

**Por que é complexa:**
- ✅ **6 JOINs cascateados** — agendamento → agente/locatário → pessoa → pessoa_física
- ✅ **Cálculos derivados** — DATEDIFF, DATENAME, DATEFROMPARTS
- ✅ **CASE com lógica** — classificação de agendamentos (hoje, próxima semana, atrasado)
- ✅ **Lógica temporal** — filtra próximas 3 meses
- ✅ **Reutilizável** — agenda, calendário, lembretes

---

## **RESUMO VIEWS:**

| View | Razão Principal |
|------|-----------------|
| **vw_ImoveisDisponiveis** | 4 JOINs + cálculo preço/m² |
| **vw_HistoricoContratosPorLocatario** | 6 JOINs + CASE logic + DATEDIFF |
| **vw_DetalhesImovel** | 5 JOINs + sub-queries correlacionadas + agregações |
| **vw_RelatorioAgentes** | 4 JOINs + LEFT JOINs + agregações complexas + comissões |
| **vw_VistoriasPorImovel** | 5 JOINs + GROUP BY + STRING_AGG |
| **vw_ImoveisComReparosPendentes** | 5 JOINs + agregações + DATEDIFF |
| **vw_DashboardLocatario** | 4 JOINs + múltiplas sub-queries correlacionadas |
| **vw_AgendamentosProximosMeses** | 6 JOINs + CASE logic + cálculos temporais |

---

---

# TRIGGERS — Validações e Efeitos Colaterais Automáticos

---

## **1. `tr_AtualizarStatusImovelContrato` — Marcar imóvel como alugado**

**Por que é um Trigger:**
```sql
-- SEM TRIGGER (problemático):
-- Ao inserir contrato, usuário TERIA que:
INSERT INTO contrato (id_pessoa, id_imovel, ...) VALUES (5, 10, ...)
-- E DEPOIS manualmente:
UPDATE imovel SET status_anuncio = 'ALUGADO' WHERE id_imovel = 10
-- Problema: Se esquecer o UPDATE, imóvel fica marcado como disponível mas está alugado!

-- COM TRIGGER (correto):
CREATE TRIGGER tr_AtualizarStatusImovelContrato
ON contrato
AFTER INSERT
AS
BEGIN
    -- Automaticamente atualizar imóvel para ALUGADO
    UPDATE imovel
    SET status_anuncio = 'ALUGADO'
    WHERE id_imovel IN (SELECT DISTINCT id_imovel FROM inserted)
    
    PRINT 'Imóvel marcado como alugado automaticamente'
END
GO

-- Agora usuário faz apenas:
INSERT INTO contrato (id_pessoa, id_imovel, ...) VALUES (5, 10, ...)
-- BOOM! Imóvel já é marcado como ALUGADO automaticamente!
```

**Por que é um Trigger:**
- ✅ **Efeito colateral automático** — não depende do usuário lembrar
- ✅ **Atomicidade** — INSERT contrato + UPDATE imóvel acontecem juntos
- ✅ **Segurança** — impede imóvel ser listado como disponível enquanto está alugado
- ✅ **Transparência** — usuário não vê a lógica, apenas insere contrato
- ✅ **Reutilizável** — qualquer INSERT (application, SSMS, script) ativa o trigger

---

## **2. `tr_LiberarStatusImovelFimContrato` — Liberar imóvel após encerrar contrato**

**Por que é um Trigger:**
```sql
-- SEM TRIGGER (problemático):
-- Ao encerrar contrato:
UPDATE contrato SET data_fim = GETDATE() WHERE id_contrato = 5
-- E DEPOIS usuário teria que:
UPDATE imovel SET status_anuncio = 'DISPONÍVEL' WHERE id_imovel = 10
-- Problema: Se esquecer, imóvel continua marcado como 'ALUGADO' mas locatário saiu!

-- COM TRIGGER (correto):
CREATE TRIGGER tr_LiberarStatusImovelFimContrato
ON contrato
AFTER UPDATE
AS
BEGIN
    -- Se data_fim foi preenchida (contrato encerrado)
    UPDATE imovel
    SET status_anuncio = 'DISPONÍVEL'
    WHERE id_imovel IN (
        SELECT id_imovel FROM inserted 
        WHERE data_fim IS NOT NULL
    )
    AND id_imovel NOT IN (
        -- Não liberar se ainda há outro contrato ativo
        SELECT id_imovel FROM contrato 
        WHERE data_fim IS NULL
    )
    
    PRINT 'Imóvel liberado para novo aluguel automaticamente'
END
GO

-- Agora:
UPDATE contrato SET data_fim = GETDATE() WHERE id_contrato = 5
-- BOOM! Imóvel já volta para DISPONÍVEL se não há outro contrato!
```

**Por que é um Trigger:**
- ✅ **Efeito colateral automático** — não depende do usuário
- ✅ **Lógica condicional** — verifica se não há outro contrato antes de liberar
- ✅ **Segurança** — impede dupla-aluguel ou deixar imóvel marcado incorretamente
- ✅ **Business rule** — encapsulamento de regra de negócio

---

## **3. `tr_ValidarDisponibilidadeVistoriador` — Impedir vistoria se indisponível**

**Por que é um Trigger:**
```sql
-- SEM TRIGGER (problemático):
-- Ao inserir vistoria, poderia:
INSERT INTO vistoria (id_imovel, id_pessoa, ...) VALUES (10, 5, ...)
-- Mas se vistoriador (id_pessoa=5) está indisponível (disponibilidade=0)
-- Ninguém verifica! Problema: Agendou vistoria com vistoriador indisponível!

-- COM TRIGGER (correto):
CREATE TRIGGER tr_ValidarDisponibilidadeVistoriador
ON vistoria
INSTEAD OF INSERT
AS
BEGIN
    -- Verificar se vistoriador está disponível
    DECLARE @id_vistoriador INT, @disponibilidade BIT
    
    SELECT @id_vistoriador = id_pessoa FROM inserted
    SELECT @disponibilidade = disponibilidade 
    FROM vistoriador 
    WHERE id_pessoa = @id_vistoriador
    
    IF @disponibilidade = 0
    BEGIN
        THROW 50001, 'Vistoriador não está disponível', 1
    END
    
    -- Se passou na validação, permite INSERT
    INSERT INTO vistoria (id_imovel, id_pessoa, tipo, data_vistoria, descricao_estado_conservacao)
    SELECT id_imovel, id_pessoa, tipo, data_vistoria, descricao_estado_conservacao 
    FROM inserted
    
    PRINT 'Vistoria registrada com sucesso'
END
GO

-- Agora se tentar:
INSERT INTO vistoria (id_imovel, id_pessoa, ...) VALUES (10, 5, ...)
-- E vistoriador 5 estiver indisponível:
-- ❌ ERRO! Trigger bloqueia a inserção
```

**Por que é um Trigger:**
- ✅ **Validação automática** — bloqueia INSERT inválido
- ✅ **INSTEAD OF** — intercepta a inserção antes de acontecer
- ✅ **Segurança** — impede agendamento com vistoriador indisponível
- ✅ **Business rule** — encapsula regra de negócio
- ✅ **Transparência** — usuário não vê validação, apenas recebe erro se inválido

---

## **4. `tr_ValidarFormatoCPF` — Validar formato do CPF**

**Por que é um Trigger:**
```sql
-- SEM TRIGGER (problemático):
-- Ao inserir pessoa_física:
INSERT INTO pessoa_fisica (id_pessoa, CPF, nome, ...) 
VALUES (5, '123ABC456', 'João', ...)
-- CPF inválido! Ninguém valida formato antes de inserir

-- COM TRIGGER (correto):
CREATE TRIGGER tr_ValidarFormatoCPF
ON pessoa_fisica
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @cpf CHAR(11), @id_pessoa INT
    
    SELECT @cpf = CPF, @id_pessoa = id_pessoa FROM inserted
    
    -- Validar se tem 11 dígitos e são todos números
    IF (@cpf NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
       OR (ISNUMERIC(@cpf) = 0)
    BEGIN
        THROW 50002, 'CPF deve conter exatamente 11 dígitos numéricos', 1
    END
    
    -- Se passou, permite INSERT
    INSERT INTO pessoa_fisica (id_pessoa, CPF, nome, data_nasc, estado_civil, nacionalidade)
    SELECT id_pessoa, CPF, nome, data_nasc, estado_civil, nacionalidade FROM inserted
    
    PRINT 'CPF válido'
END
GO

-- Agora:
INSERT INTO pessoa_fisica (..., CPF, ...) VALUES (..., '123ABC456', ...)
-- ❌ ERRO! Trigger bloqueia
INSERT INTO pessoa_fisica (..., CPF, ...) VALUES (..., '12345678901', ...)
-- ✅ OK! Trigger permite
```

**Por que é um Trigger:**
- ✅ **Validação de formato** — bloqueia dados inválidos na origem
- ✅ **INSTEAD OF** — intercepta antes de inserir
- ✅ **Data quality** — garante integridade de dados
- ✅ **LIKE + ISNUMERIC** — validação robusta
- ✅ **Aplicável a todos** — qualquer INSERT (application, script, SSMS) passa pela validação

---

## **5. `tr_ValidarFormatoCNPJ` — Validar formato do CNPJ**

**Por que é um Trigger:**
```sql
-- Mesma lógica do CPF, mas para CNPJ

CREATE TRIGGER tr_ValidarFormatoCNPJ
ON pessoa_juridica
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @cnpj CHAR(14), @id_pessoa INT
    
    SELECT @cnpj = CNPJ, @id_pessoa = id_pessoa FROM inserted
    
    -- Validar se tem 14 dígitos e são todos números
    IF (@cnpj NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
       OR (ISNUMERIC(@cnpj) = 0)
    BEGIN
        THROW 50003, 'CNPJ deve conter exatamente 14 dígitos numéricos', 1
    END
    
    -- Se passou, permite INSERT
    INSERT INTO pessoa_juridica 
    (id_pessoa, CNPJ, nome_fantasia, razao_social, data_abertura, inscricao_estadual, porte, status)
    SELECT id_pessoa, CNPJ, nome_fantasia, razao_social, data_abertura, inscricao_estadual, porte, status 
    FROM inserted
    
    PRINT 'CNPJ válido'
END
GO
```

**Por que é um Trigger:**
- ✅ **Validação de formato** — mesma lógica do CPF
- ✅ **Data quality** — garante CNPJ válido
- ✅ **Aplicável a todos** — qualquer INSERT passa pela validação

---

## **6. `tr_PreventirDeleteDePessoaComDependencias` — Impedir deletar pessoa com dados ativos**

**Por que é um Trigger:**
```sql
-- SEM TRIGGER (problemático):
-- Usuário poderia:
DELETE FROM pessoa WHERE id_pessoa = 5
-- Mas pessoa 5 tem:
-- - Cliente ativo
-- - Contratos ativos
-- - Imóveis alugados
-- Desastre! Tudo é deletado em cascata (ON DELETE CASCADE)

-- COM TRIGGER (correto):
CREATE TRIGGER tr_PreventirDeleteDePessoaComDependencias
ON pessoa
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @id_pessoa INT
    SELECT @id_pessoa = id_pessoa FROM deleted
    
    -- Verificar contratos ativos
    IF EXISTS (SELECT 1 FROM contrato c
               WHERE c.id_imovel IN (
                   SELECT id_imovel FROM imovel WHERE id_pessoa = @id_pessoa
               ) AND c.data_fim IS NULL)
    BEGIN
        THROW 50004, 'Pessoa tem contratos ativos. Encerre-os primeiro', 1
    END
    
    -- Verificar imóveis ativos
    IF EXISTS (SELECT 1 FROM imovel 
               WHERE id_pessoa = @id_pessoa AND status_anuncio != 'REMOVIDO')
    BEGIN
        THROW 50005, 'Pessoa tem imóveis ativos. Remova-os primeiro', 1
    END
    
    -- Verificar agendamentos pendentes
    IF EXISTS (SELECT 1 FROM agendamento agd
               WHERE agd.id_agente IN (
                   SELECT id_pessoa FROM agente WHERE id_pessoa = @id_pessoa
               ) AND agd.data_visita > CAST(GETDATE() AS DATE))
    BEGIN
        THROW 50006, 'Agente tem agendamentos pendentes', 1
    END
    
    -- Se passou todas as validações, permite DELETE
    DELETE FROM pessoa WHERE id_pessoa = @id_pessoa
    PRINT 'Pessoa deletada com sucesso'
END
GO

-- Agora:
DELETE FROM pessoa WHERE id_pessoa = 5
-- Se pessoa 5 tem dependências ativas:
-- ❌ ERRO! Trigger bloqueia
-- Se não tem dependências:
-- ✅ OK! Trigger permite deletar
```

**Por que é um Trigger:**
- ✅ **INSTEAD OF DELETE** — intercepta delete antes de acontecer
- ✅ **Múltiplas validações** — verifica 3 tipos de dependências
- ✅ **Proteção de dados** — impede perda acidental de dados
- ✅ **Integridade referencial** — mais rigoroso que FK simples
- ✅ **Aplicável a todos** — qualquer DELETE passa pela validação

---

## **7. `tr_PreventirRepetirAgendamento` — Bloquear agendamento duplicado**

**Por que é um Trigger:**
```sql
-- SEM TRIGGER (problemático):
-- Usuário poderia:
INSERT INTO agendamento VALUES (3, 5, '2026-11-15', '14:00')
-- E depois:
INSERT INTO agendamento VALUES (3, 5, '2026-11-15', '14:00')  -- Duplicado!
-- Agente teria 2 agendamentos ao mesmo tempo!

-- COM TRIGGER (correto):
CREATE TRIGGER tr_PreventirRepetirAgendamento
ON agendamento
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @id_agente INT, @id_locatario INT, @data_visita DATE, @hora_visita TIME
    
    SELECT @id_agente = id_agente, @id_locatario = id_locatario, 
           @data_visita = data_visita, @hora_visita = hora_visita 
    FROM inserted
    
    -- Verificar se agente já tem agendamento no mesmo horário
    IF EXISTS (SELECT 1 FROM agendamento 
               WHERE id_agente = @id_agente 
               AND data_visita = @data_visita 
               AND hora_visita = @hora_visita)
    BEGIN
        THROW 50007, 'Agente já tem agendamento neste horário', 1
    END
    
    -- Verificar se locatário já tem agendamento no mesmo horário
    IF EXISTS (SELECT 1 FROM agendamento 
               WHERE id_locatario = @id_locatario 
               AND data_visita = @data_visita 
               AND hora_visita = @hora_visita)
    BEGIN
        THROW 50008, 'Locatário já tem agendamento neste horário', 1
    END
    
    -- Se passou, permite INSERT
    INSERT INTO agendamento (id_agente, id_locatario, data_visita, hora_visita)
    SELECT id_agente, id_locatario, data_visita, hora_visita FROM inserted
    
    PRINT 'Agendamento realizado com sucesso'
END
GO

-- Agora:
INSERT INTO agendamento VALUES (3, 5, '2026-11-15', '14:00')
-- ✅ OK! Primeiro agendamento
INSERT INTO agendamento VALUES (3, 5, '2026-11-15', '14:00')
-- ❌ ERRO! Trigger bloqueia duplicata
```

**Por que é um Trigger:**
- ✅ **INSTEAD OF INSERT** — valida antes de inserir
- ✅ **Validação de duplicatas** — impede conflito de horários
- ✅ **Segurança** — agente/locatário não podem ter múltiplos agendamentos simultâneos
- ✅ **Business rule** — encapsula regra de calendário

---

## **8. `tr_AuditoriaAlteracoesPessoa` — Registrar todas as alterações em pessoa**

**Por que é um Trigger:**
```sql
-- Primeiro, criar tabela de auditoria:
CREATE TABLE auditoria_pessoa (
    id_auditoria INT IDENTITY PRIMARY KEY,
    id_pessoa INT NOT NULL,
    operacao VARCHAR(10) NOT NULL,  -- INSERT, UPDATE, DELETE
    data_operacao DATETIME NOT NULL DEFAULT GETDATE(),
    usuario VARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    valores_anteriores XML NULL,
    valores_novos XML NULL
)
GO

-- SEM TRIGGER (problemático):
-- Usuário atualiza pessoa:
UPDATE pessoa SET nome = 'João Silva' WHERE id_pessoa = 5
-- Ninguém registra quando, quem, o quê foi alterado!
-- Se há erro depois, não há histórico

-- COM TRIGGER (correto):
CREATE TRIGGER tr_AuditoriaAlteracoesPessoa
ON pessoa
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @operacao VARCHAR(10)
    
    -- Determinar qual operação
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @operacao = 'UPDATE'
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @operacao = 'INSERT'
    ELSE
        SET @operacao = 'DELETE'
    
    -- Registrar auditoria
    INSERT INTO auditoria_pessoa (id_pessoa, operacao, valores_anteriores, valores_novos)
    SELECT 
        ISNULL(d.id_pessoa, i.id_pessoa),
        @operacao,
        -- Valores anteriores (DELETE e UPDATE)
        CASE WHEN d.id_pessoa IS NOT NULL 
             THEN (SELECT d.* FOR XML PATH('pessoa_antes'))
             ELSE NULL 
        END,
        -- Valores novos (INSERT e UPDATE)
        CASE WHEN i.id_pessoa IS NOT NULL 
             THEN (SELECT i.* FOR XML PATH('pessoa_depois'))
             ELSE NULL 
        END
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.id_pessoa = d.id_pessoa
    
    PRINT 'Auditoria registrada: ' + @operacao
END
GO

-- Agora qualquer operação é registrada:
INSERT INTO pessoa (...) VALUES (...)  -- Registra INSERT
UPDATE pessoa SET email = '...' WHERE id_pessoa = 5  -- Registra UPDATE
DELETE FROM pessoa WHERE id_pessoa = 5  -- Registra DELETE

-- Depois consultar histórico:
SELECT * FROM auditoria_pessoa WHERE id_pessoa = 5 ORDER BY data_operacao DESC
-- Resultado:
-- id_auditoria | id_pessoa | operacao | data_operacao | usuario | valores_anteriores | valores_novos
```

**Por que é um Trigger:**
- ✅ **AFTER INSERT, UPDATE, DELETE** — ativa em todas operações
- ✅ **Captura completa** — registra antes (deleted) e depois (inserted)
- ✅ **XML** — preserva todos os valores em formato estruturado
- ✅ **Rastreabilidade** — quando, quem, o quê foi alterado
- ✅ **Automático** — qualquer alteração é registrada
- ✅ **Compliance** — requisito legal/regulatório

---

## **RESUMO TRIGGERS:**

| Trigger | Tipo | Razão Principal |
|---------|------|-----------------|
| **tr_AtualizarStatusImovelContrato** | AFTER INSERT | Efeito colateral: marca imóvel como alugado |
| **tr_LiberarStatusImovelFimContrato** | AFTER UPDATE | Efeito colateral: libera imóvel após encerrar |
| **tr_ValidarDisponibilidadeVistoriador** | INSTEAD OF INSERT | Validação: bloqueia vistoria se indisponível |
| **tr_ValidarFormatoCPF** | INSTEAD OF INSERT | Validação: valida formato do CPF |
| **tr_ValidarFormatoCNPJ** | INSTEAD OF INSERT | Validação: valida formato do CNPJ |
| **tr_PreventirDeleteDePessoaComDependencias** | INSTEAD OF DELETE | Proteção: bloqueia delete com dependências ativas |
| **tr_PreventirRepetirAgendamento** | INSTEAD OF INSERT | Validação: impede agendamento duplicado |
| **tr_AuditoriaAlteracoesPessoa** | AFTER INSERT, UPDATE, DELETE | Rastreamento: registra todas alterações |

**Padrões de Trigger:**

| Padrão | Quando Usar | Tipo |
|--------|-----------|------|
| **Efeito Colateral** | UPDATE automático relacionado | AFTER |
| **Validação** | Bloquear operação inválida | INSTEAD OF |
| **Proteção** | Impedir DELETE/UPDATE perigoso | INSTEAD OF |
| **Auditoria** | Registrar alterações | AFTER |
| **Lógica de Negócio** | Regra complexa que envolve múltiplas tabelas | AFTER ou INSTEAD OF |

---

## **CONCLUSÃO:**

**Procedures**, **Views** e **Triggers** trabalham juntos:
```
┌─────────────────────────────────────────────────────────┐
│  Aplicação (C#, Python, Node.js, etc)                   │
│  INSERT INTO contrato ...                               │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  TRIGGER: tr_AtualizarStatusImovelContrato             │
│  ✅ Valida e marca imóvel como ALUGADO                 │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  PROCEDURE: sp_CriarContrato (melhor prática)          │
│  ✅ Orquestra validações + INSERT contrato + UPDATE    │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  VIEW: vw_HistoricoContratosPorLocatario               │
│  ✅ Consulta dados complexos para dashboard            │
└─────────────────────────────────────────────────────────┘
```

- **Procedures** = Orquestração de operações complexas
- **Views** = Consultas reutilizáveis com JOINs/agregações
- **Triggers** = Regras automáticas + validações + auditoria
