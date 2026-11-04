## :bust_in_silhouette:
Segue em anexo o documento ativo no momento
## :speech_balloon: SSMS
Excelente! Analisando o modelo `NexusImoveis`, identifiquei as operações complexas que necessitam de **Procedures**, **Views** e **Triggers**:

---

## **PROCEDURES (Operações Multi-Passo com Transactions)**
_Legenda: ✅ implementada · ⏳ pendente_

### **Cadastros Complexos (Herança de Pessoas):**
1. ✅ `cadastrar_pessoa_fisica` — INSERT `pessoa` + INSERT `pessoa_fisica` (2 ops, FK)
2. ✅ `cadastrar_pessoa_juridica` — INSERT `pessoa` + INSERT `pessoa_juridica` (2 ops, FK)
3. ✅ `cadastrar_vistoriador` — INSERT `pessoa` + INSERT `pessoa_fisica` + INSERT `funcionario` + INSERT `vistoriador` (4 ops, FK em cascata)
4. ✅ `cadastrar_agente` — INSERT `pessoa` + INSERT `pessoa_fisica` + INSERT `funcionario` + INSERT `agente` (4 ops, FK em cascata)
5. ✅ `cadastrar_proprietario` — INSERT `pessoa` + INSERT `pessoa_fisica` + INSERT `cliente` + INSERT `proprietario` (4 ops, FK em cascata)
6. ✅ `cadastrar_locatario` — INSERT `pessoa` + INSERT `pessoa_fisica` + INSERT `cliente` + INSERT `locatario` (4 ops, FK em cascata)

### **Operações de Negócio Complexas:**
7. ✅ `criar_contrato` — Validar crédito do locatário + validar disponibilidade do imóvel + INSERT contrato (validação + transactions; o status do imóvel fica com o trigger `preencher_dados_contrato_imovel`)
8. ✅ `encerrar_contrato` — UPDATE contrato + gerar vistoria final + listar reparos pendentes (multi-passo com lógica; o imóvel é liberado pelo trigger `liberar_status_imovel_contrato`)
9. ✅ `registrar_vistoria` — INSERT vistoria + gerar reparos associados (2 ops, transaction)
10. ✅ `excluir_pessoa`

---

## **VIEWS (Consultas Complexas com JOINs Reutilizáveis)**

1. ✅ `imoveis_disponiveis` — JOIN `imovel` + `proprietario` + `pessoa_fisica/juridica`, filtrando por status
2. ✅ `historico_contratos_por_locatario` — JOIN `contrato` + `imovel` + `proprietario` + `pessoa_fisica/juridica`, com data prevista de fim e status do contrato (ATIVO, ENCERRADO NO PRAZO, ENCERRADO ANTES DO PRAZO)
3. ✅ `detalhes_imovel` — JOIN `imovel` + `proprietario` + `pessoa_fisica/juridica` + subqueries de contratos ativos, locatário atual, vistorias e reparos pendentes
4. ⏳ `relatorio_agentes` — JOIN `agente` + `funcionario` + `pessoa_fisica`, com comissões
5. ⏳ `vistorias_por_imovel` — JOIN `vistoria` + `imovel` + `vistoriador` + `pessoa_fisica`, com status de reparos
6. ⏳ `imoveis_com_reparos_pendentes` — JOIN `imovel` + `vistoria` + `reparo`, filtrando por status de reparo
7. ⏳ `dashboard_locatario` — JOIN `locatario` + `pessoa_fisica` + `contrato` + `imovel` + `proprietario`
8. ⏳ `agendamentos_proximos_meses` — JOIN `agendamento` + `agente` + `locatario` + `pessoa_fisica`, com filtro de datas

---

## **TRIGGERS (validações e consistência)**

1. ✅ `validar_formato_cpf` — Após INSERT/UPDATE em `pessoa_fisica`, bloqueia CPF que não tenha exatamente 11 dígitos numéricos
2. ✅ `validar_formato_cnpj` — Após INSERT/UPDATE em `pessoa_juridica`, bloqueia CNPJ que não tenha exatamente 14 dígitos numéricos
3. ✅ `validar_liberacao_vistoriador` — Após UPDATE em `vistoriador`, bloqueia a ativação quando há vistorias agendadas para o futuro (substitui a procedure `atualizar_disponibilidade_vistoriador`)
4. ✅ `validar_vinculo_agente` — Após INSERT em `agendamento`, bloqueia agente sem vínculo ativo com a empresa (conflitos de horário ficam com PK e UNIQUE)
5. ✅ `preencher_dados_contrato_imovel` — Após INSERT em `contrato`, preenche valor e assinaturas e deixa o imóvel INDISPONIVEL
6. ✅ `liberar_status_imovel_contrato` — Após UPDATE em `contrato`, devolve o imóvel para DISPONIVEL quando o contrato é encerrado (`data_fim` preenchida)

---
## **RESUMO RECOMENDADO:**

| Tipo | Qtd | Prioridade | Complexidade |
|------|-----|-----------|--------------|
| **Procedures** | 10 | 🔴 Alta | ⭐⭐⭐⭐⭐ |
| **Views** | 8 | 🟡 Média | ⭐⭐⭐ |
| **Triggers** | 6 | 🟡 Média | ⭐⭐⭐⭐ |

**Status atual:** 11 procedures implementadas · 4 triggers implementados · 7 views criadas (6 do mapeamento + `situacao_contratos`) · auditoria removida do escopo.

**Próximos passos:** views `relatorio_agentes` e `dashboard_locatario` do mapeamento; decidir sobre vendas (ver pendências).

**Decisões registradas:**
- **Agendamento:** PK `(id_agente, data_visita, hora_visita)` e `UNIQUE (id_locatario, data_visita, hora_visita)`. O mesmo par agente/locatário pode ter visitas em horários diferentes, e o banco garante os dois conflitos.
- **Contrato:** nasce com as assinaturas pendentes (`0`). `registrar_assinatura_contrato` marca cada lado separadamente. O contrato está validado quando as duas assinaturas estão marcadas (view `situacao_contratos`).
- **Um contrato ativo por imóvel:** garantido por índice único filtrado (`ux_contrato_ativo_imovel`), além da checagem na procedure.
- **Valor:** o valor negociado é informado em `criar_contrato`. O valor do aluguel do imóvel não é copiado automaticamente.
- **Tipo de vistoria:** `ENTRADA` ou `SAIDA`. A vistoria de encerramento grava `SAIDA`.
- **Triggers de contrato removidos:** `preencher_dados_contrato_imovel` e `liberar_status_imovel_contrato` duplicavam as procedures. A marcação e a liberação do imóvel agora ficam em `criar_contrato` e `encerrar_contrato`.
- **Validação de CPF/CNPJ:** em trigger, por valer para qualquer INSERT ou UPDATE, independentemente da procedure.
- **Exclusão:** `excluir_pessoa` não tem `@force_delete`. Remover em cascata contratos e vistorias apagaria o histórico.
- **Domínio de status:** `imovel.status_anuncio` aceita `DISPONIVEL` e `INDISPONIVEL`. Imóvel alugado fica `INDISPONIVEL`.

**Pendências conhecidas:**
- **Agenda por horário de trabalho do agente:** não há onde guardar o expediente. Precisaria de uma tabela própria.
- **Multa por quebra antecipada:** a view `situacao_contratos` identifica a quebra, mas o percentual da multa ainda não foi definido.
- **Vendas:** a descrição do sistema cita venda, mas a entrega final cobre só locação. Não há tabela de venda.
- **Fotos do imóvel:** `imovel.foto` guarda uma coluna só. O requisito fala em fotos no plural.
- **Aptidão do imóvel com reparos:** o requisito sugere marcar o imóvel como inapto quando há reparos. Ainda não está automatizado.
___

## :bust_in_silhouette:
Poderia me detalhar porque as seguintes operações de procedures de fato serão usadas como procedures? Ou porque são operações mais complexas?

7.	✅ `criar_contrato` — Validar crédito do locatário + INSERT contrato + atualizar status do imóvel (3 ops, validação + transactions)
8.	✅ `encerrar_contrato` — UPDATE contrato + gerar vistoria final + listar reparos pendentes (multi-passo com lógica)
9.	✅ `registrar_vistoria` — INSERT vistoria + gerar reparos associados (2 ops, transaction)
10.	✅ `excluir_pessoa`
## :speech_balloon: SSMS
Excelente pergunta! Vou detalhar cada uma com exemplos práticos de **por que são operações complexas**:

---

## **7. `criar_contrato` — Validar crédito + INSERT + UPDATE**

**Por que é uma Procedure:**
```sql
-- SEM PROCEDURE (problemático):
-- Problema 1: Validações precisam acontecer antes do INSERT
SELECT status_analise_credito FROM locatario WHERE id_pessoa = 5
-- Se status = 'REPROVADO', não deveria inserir contrato!

-- Problema 2: Múltiplas operações desacopladas
INSERT INTO contrato (id_pessoa, id_imovel, ...) VALUES (5, 10, ...)
-- E depois atualizar o imóvel:
UPDATE imovel SET status_anuncio = 'INDISPONIVEL' WHERE id_imovel = 10
-- Se a primeira INSERT falhar e a segunda suceder? Estado inconsistente!

-- COM PROCEDURE (correto):
CREATE PROCEDURE criar_contrato
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
        
        IF @status_imovel != 'DISPONIVEL'
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
        SET status_anuncio = 'INDISPONIVEL' 
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

## **8. `encerrar_contrato` — UPDATE + Gerar vistoria + Listar reparos**

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
CREATE PROCEDURE encerrar_contrato
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
        
        -- 4️⃣ UPDATE imóvel: voltar a DISPONIVEL
        UPDATE imovel 
        SET status_anuncio = 'DISPONIVEL' 
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

## **9. `registrar_vistoria` — INSERT vistoria + Gerar reparos**

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
CREATE PROCEDURE registrar_vistoria
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



## **10. `excluir_pessoa` — Validar dependências + DELETE em cascata**

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
CREATE PROCEDURE excluir_pessoa
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
| **criar_contrato** | 4 operações (validações + INSERT + UPDATE) + transaction |
| **encerrar_contrato** | 5 operações + obrigação de criar vistoria final + retorna dados |
| **registrar_vistoria** | Looping de reparos + SCOPE_IDENTITY + múltiplas operações |
| **excluir_pessoa** | 3+ validações + cascata controlada + force delete |

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
# VIEWS — Consultas Complexas com JOINs Reutilizáveis

---

## **1. `imoveis_disponiveis` — Listar imóveis com dados do proprietário**

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
WHERE i.status_anuncio = 'DISPONIVEL'
AND pr.preferencia_contato IS NOT NULL
ORDER BY i.valor_aluguel ASC

-- Problema: Query longa, fácil de errar joins, precisa repetir em múltiplas telas

-- COM VIEW (correto):
CREATE VIEW imoveis_disponiveis AS
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
WHERE i.status_anuncio = 'DISPONIVEL'
  AND c.status_conta = 1
  AND pf.nome IS NOT NULL
GO

-- Agora usuário faz consulta simples:
SELECT * FROM imoveis_disponiveis WHERE valor_aluguel BETWEEN 1000 AND 3000
```

**Por que é complexa:**
- ✅ **4 JOINs cascateados** — pessoa → pessoa_física → cliente → proprietário → imóvel
- ✅ **Reutilizável** — múltiplas telas precisam dessa consulta
- ✅ **Cálculo derivado** — preço por m² (lógica de negócio)
- ✅ **Filtro consistente** — status_anuncio, status_conta sempre aplicados

---

## **2. `historico_contratos_por_locatario` — Ver todos os contratos de um locatário**

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
CREATE VIEW historico_contratos_por_locatario AS
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
SELECT * FROM historico_contratos_por_locatario WHERE id_locatario = 5
```

**Por que é complexa:**
- ✅ **6 JOINs cascateados** — locatário → contrato → imóvel → proprietário → pessoa
- ✅ **Lógica de negócio** — cálculo de status_contrato usando CASE
- ✅ **Cálculo derivado** — meses_decorridos (DATEDIFF)
- ✅ **Múltiplas telas precisam** — histórico, dashboard, relatórios

---

## **3. `detalhes_imovel` — Visão completa de um imóvel**

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
CREATE VIEW detalhes_imovel AS
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
SELECT * FROM detalhes_imovel WHERE id_imovel = 10
```

**Por que é complexa:**
- ✅ **5 JOINs + Sub-queries** — encapsula lógica complexa
- ✅ **Agregações** — contadores de contratos, vistorias, reparos
- ✅ **Correlação** — sub-queries correlacionadas ao imovel
- ✅ **Dados relacionados** — proprietário, locatário, histórico, tudo em uma query
- ✅ **Reutilizável** — tela de detalhes, relatórios, dashboard

---

## **4. `relatorio_agentes` — Performance de agentes com comissões**

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
CREATE VIEW relatorio_agentes AS
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
SELECT * FROM relatorio_agentes WHERE status_ativo = 1 ORDER BY comissao_total DESC
```

**Por que é complexa:**
- ✅ **4 JOINs + LEFT JOINs** — agente → funcionário → pessoa → agendamento → contrato
- ✅ **Agregações complexas** — COUNT(DISTINCT), SUM, AVG
- ✅ **Cálculos de negócio** — comissão (soma × porcentagem)
- ✅ **Filtro temporal** — últimos 12 meses
- ✅ **ISNULL** — tratamento de NULLs em agregações
- ✅ **Reutilizável** — relatórios, dashboard, análise de performance

---

## **5. `vistorias_por_imovel` — Histórico de vistorias com status de reparos**

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
CREATE VIEW vistorias_por_imovel AS
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
SELECT * FROM vistorias_por_imovel WHERE id_imovel = 10 ORDER BY data_vistoria DESC
```

**Por que é complexa:**
- ✅ **5 JOINs + LEFT JOIN** — vistoria → vistoriador → funcionário → pessoa → reparo
- ✅ **GROUP BY com CASE** — contadores condicionais (pendentes vs executados)
- ✅ **STRING_AGG** — agregação de strings
- ✅ **Lógica de negócio** — status de reparos por vistoria
- ✅ **Reutilizável** — histórico de vistorias, análise de manutenção

---

## **6. `imoveis_com_reparos_pendentes` — Imóveis que precisam de manutenção**

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
CREATE VIEW imoveis_com_reparos_pendentes AS
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
SELECT * FROM imoveis_com_reparos_pendentes 
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

## **7. `dashboard_locatario` — Visão completa do locatário**

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
CREATE VIEW dashboard_locatario AS
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
SELECT * FROM dashboard_locatario WHERE id_pessoa = 5
```

**Por que é complexa:**
- ✅ **Sub-queries correlacionadas** — dados relacionados a um locatário
- ✅ **Agregações** — contadores de contratos, agendamentos
- ✅ **Lógica de negócio** — filtra apenas contratos ativos
- ✅ **Múltiplos dados relacionados** — contrato, imovel, agendamentos, histórico
- ✅ **Reutilizável** — dashboard, tela de perfil

---

## **8. `agendamentos_proximos_meses` — Agenda de visitas futuras**

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
CREATE VIEW agendamentos_proximos_meses AS
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
SELECT * FROM agendamentos_proximos_meses 
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
| **imoveis_disponiveis** | 4 JOINs + cálculo preço/m² |
| **historico_contratos_por_locatario** | 6 JOINs + CASE logic + DATEDIFF |
| **detalhes_imovel** | 5 JOINs + sub-queries correlacionadas + agregações |
| **relatorio_agentes** | 4 JOINs + LEFT JOINs + agregações complexas + comissões |
| **vistorias_por_imovel** | 5 JOINs + GROUP BY + STRING_AGG |
| **imoveis_com_reparos_pendentes** | 5 JOINs + agregações + DATEDIFF |
| **dashboard_locatario** | 4 JOINs + múltiplas sub-queries correlacionadas |
| **agendamentos_proximos_meses** | 6 JOINs + CASE logic + cálculos temporais |

---

---

# TRIGGERS — Validação de formato e consistência

## **Decisão: onde colocar cada regra**

Dois critérios definem o lugar de cada regra:

- **Validação de dados: trigger first.** Regras de formato e integridade que devem valer para qualquer INSERT ou UPDATE, venha de onde vier. Exemplo: CPF e CNPJ. Essas regras começam sempre como trigger.
- **Operação de negócio: procedure.** Operações com várias etapas, regras de negócio e transação explícita. Exemplo: `criar_contrato`, `registrar_vistoria`.

**Motivos:**
- Um trigger de validação garante a regra em qualquer caminho de escrita. Uma validação só dentro da procedure cobre apenas quem chama a procedure.
- Procedure deixa explícito o fluxo de uma operação. Quem lê `criar_contrato` vê as validações, o INSERT e a mudança de status do imóvel no mesmo lugar.
- Evita duplicação: se a procedure e um trigger fizessem o mesmo efeito, a regra existiria em dois lugares.

**Trade-off:** um trigger roda sem ser chamado, então quem lê o INSERT não vê a validação. Por isso, ela fica documentada aqui. Um `THROW` dentro do trigger desfaz o comando inteiro.

**Destino das regras migradas:**

| Trigger original | Destino | Status |
|---|---|---|
| `atualizar_status_imovel_contrato` | `preencher_dados_contrato_imovel` (trigger) | ✅ implementada |
| `liberar_status_imovel_fim_contrato` | `liberar_status_imovel_contrato` (trigger) | ✅ implementada |
| `validar_disponibilidade_vistoriador` | `registrar_vistoria` | ✅ implementada |
| `prevenir_repetir_agendamento` | `validar_vinculo_agente` (trigger) e PK/UNIQUE de `agendamento` | ✅ implementada |
| `atualizar_disponibilidade_vistoriador` (procedure) | `validar_liberacao_vistoriador` (trigger) | ✅ implementada |
| `prevenir_delete_pessoa_com_dependencias` | `excluir_pessoa` | ✅ implementada |
| `validar_formato_cpf` | mantido em trigger (validação de dados) | ✅ implementada |
| `validar_formato_cnpj` | mantido em trigger (validação de dados) | ✅ implementada |

**Procedure ou trigger, em resumo:**

| | Procedure | Trigger |
|---|---|---|
| Quando roda | Quando é chamada com `EXEC` | Automaticamente, em INSERT, UPDATE ou DELETE |
| Quem decide | A aplicação | O próprio banco, sempre |
| Parâmetros | Sim | Não (acessa `inserted` e `deleted`) |
| Retorno | Código de retorno e resultados; erros via `THROW` | Não retorna valor |
| Transação | Controlada explicitamente | Faz parte da transação do comando que disparou |
| Uso típico | Operações com várias etapas e regras de negócio | Validação de dados e efeitos automáticos, regras que não podem ser esquecidas |

---
| Uso típico | Operações com várias etapas e regras de negócio | Validação de dados e efeitos automáticos, regras que não podem ser esquecidas |

---

## **RESUMO TRIGGERS:**

| Trigger | Tipo | Razão Principal |
|---------|------|-----------------|
| **validar_formato_cpf** | AFTER INSERT, UPDATE | Validação: CPF com 11 dígitos numéricos |
| **validar_formato_cnpj** | AFTER INSERT, UPDATE | Validação: CNPJ com 14 dígitos numéricos |
| **validar_liberacao_vistoriador** | AFTER UPDATE | Validação: vistoriador não é ativado com vistorias futuras |
| **validar_vinculo_agente** | AFTER INSERT | Validação: impede agendamento com agente sem vínculo ativo |
| **preencher_dados_contrato_imovel** | AFTER INSERT | Consistência: preenche valor e assinaturas do contrato e deixa o imóvel INDISPONIVEL |
| **liberar_status_imovel_contrato** | AFTER UPDATE | Consistência: devolve o imóvel para DISPONIVEL quando o contrato é encerrado |

---
## **CONCLUSÃO:**

**Procedures**, **Views** e **Triggers** trabalham juntos:
```
┌─────────────────────────────────────────────────────────┐
│  Aplicação (C#, Python, Node.js, etc)                   │
│  EXEC criar_contrato ...                                │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  PROCEDURE: criar_contrato                              │
│  ✅ Valida crédito e disponibilidade                    │
│  ✅ INSERT contrato                                     │    
│  ✅ Transação explícita, erros via THROW                │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│  TRIGGER: preencher_dados_contrato_imovel               │
│  ✅ Preenche o valor e deixa o imóvel INDISPONIVEL      │
└─────────────────────────────────────────────────────────┘

VIEW: historico_contratos_por_locatario  (somente leitura)
```

- **Procedures** = operações com várias etapas e regras de negócio. São a forma padrão de alterar dados.
- **Views** = consultas reutilizáveis com JOINs e agregações, somente leitura.
- **Triggers** = validação de formato (CPF/CNPJ) e status do imóvel no contrato: regras que precisam valer para qualquer origem de alteração.
