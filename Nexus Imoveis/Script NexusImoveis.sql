use master;
GO

-- Força usuário único para desconexão do banco de dados e realiza o drop database

if exists (select name from sys.databases where name = 'NexusImoveis')
	alter database NexusImoveis set single_user with rollback immediate;
    drop database NexusImoveis;
GO

create database NexusImoveis;
GO

use NexusImoveis;
GO

-- Tables and Indexes

create table pessoa (
	id_pessoa int identity not null,
	email varchar(100) null,
	telefone char(14) not null,
	endereco varchar(200) not null,
	tipo char(8) not null,

	constraint pk_pessoa primary key (id_pessoa),
	constraint uq_pessoa_email unique (email),
	constraint ck_tipo check (tipo in ('FISICA', 'JURIDICA'))
);
GO

create table pessoa_fisica (
	id_pessoa int not null,
	CPF char(11) not null,
	nome varchar(100) not null,
	data_nasc date not null,
	estado_civil char(15) not null,
	nacionalidade varchar(30) not null,

	constraint pk_pessoa_fisica primary key (id_pessoa),
	constraint fk_pessoa_fisica_pessoa foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade,
	constraint uq_pessoa_fisica unique (CPF)
);
create index idx_pessoa_fisica_nome on pessoa_fisica(nome);
GO

create table pessoa_juridica (
	id_pessoa int not null,
	CNPJ char(14) not null,
	nome_fantasia varchar(100) not null,
	razao_social varchar(100) not null,
	data_abertura date not null,
	inscricao_estadual char(14) not null,
	porte varchar(20) not null,
	status varchar(10) not null,

	constraint pk_pessoa_juridica primary key (id_pessoa),
	constraint fk_pessoa_juridica_pessoa foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade,
	constraint uq_pessoa_juridica unique (CNPJ)
);
GO

create table funcionario(
	id_pessoa int not null,
	data_admissao date not null,
	data_demissao date null,
	status_ativo bit not null,
	salario numeric(10,2) not null,
	tipo char(11) not null,

	constraint pk_funcionario primary key (id_pessoa),
	constraint fk_funcionario_pessoa foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade,
	constraint ck_funcionario_tipo check (tipo in ('VISTORIADOR', 'AGENTE'))
);
GO

create table vistoriador(
	id_pessoa int not null,
	numero_registro_tecnico varchar(50) not null,
	especializacao varchar(50) not null,
	disponibilidade bit not null,

	constraint pk_vistoriador primary key (id_pessoa),
	constraint fk_vistoriador_funcionario foreign key (id_pessoa) references funcionario(id_pessoa) on delete cascade
);
GO

create table agente(
	id_pessoa int not null,
	numero_CRECI varchar(20) not null,
	porcentagem_comissao numeric(5,4) not null constraint chk_porcentagem_comissao check (porcentagem_comissao >= 0 and porcentagem_comissao <= 1),
	regiao_atuacao varchar(50) not null,

	constraint pk_agente primary key(id_pessoa),
	constraint fk_agente_funcionario foreign key (id_pessoa) references funcionario(id_pessoa) on delete cascade
);
GO

create table cliente(
	id_pessoa int not null,
	senha varchar(250) not null,
	data_cadastro date not null,
	status_conta bit not null,

	constraint pk_cliente primary key(id_pessoa),
	constraint fk_cliente_pessoa foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade
);
GO

create table proprietario(
	id_pessoa int not null,
	preferencia_contato varchar(20) not null,
	dados_bancarios_agencia char(6) not null,
	dados_bancarios_conta char(15) not null,

	constraint pk_proprietario primary key(id_pessoa),
	constraint fk_proprietario_cliente foreign key (id_pessoa) references cliente(id_pessoa) on delete cascade
);
GO

create table locatario(
	id_pessoa int not null,
	renda_mensal numeric(10,2) not null,
	status_analise_credito varchar(20) not null,

	constraint pk_locatario primary key(id_pessoa),
	constraint fk_locatario_cliente foreign key (id_pessoa) references cliente(id_pessoa) on delete cascade
);
GO

create table imovel(
	id_imovel int identity not null,
	id_pessoa int not null,
	endereco varchar(200) not null,
	descricao varchar(500) null,
	foto varchar(255) null,
	status_aptidao bit not null,
	num_matricula varchar(50) not null,
	valor_aluguel numeric(10,2) not null,
	area_m2 numeric(10,2) not null,
	status_anuncio char(20) not null,

	constraint pk_imovel primary key(id_imovel),
	constraint fk_imovel_proprietario foreign key (id_pessoa) references proprietario(id_pessoa),
	constraint ck_status_anuncio check (status_anuncio in ('DISPONIVEL', 'INDISPONIVEL'))
);
create index idx_imovel_proprietario on imovel(id_pessoa);
create index idx_imovel_valor_aluguel on imovel(valor_aluguel);
GO

create table contrato(
	id_contrato int identity not null,
	id_pessoa int not null,
	id_imovel int not null,
	status_proprietario bit not null,
	status_locatario bit not null,
	data_inicio date not null,
	data_fim date null,
	valor numeric(10,2) not null,
	numero_meses int not null,

	constraint pk_contrato primary key(id_contrato),
	constraint fk_contrato_locatario foreign key (id_pessoa) references locatario(id_pessoa),
	constraint fk_contrato_imovel foreign key (id_imovel) references imovel(id_imovel)
);
create index idx_contrato_locatario on contrato(id_pessoa);
create index idx_contrato_imovel on contrato(id_imovel);
create index idx_contrato_data_inicio on contrato(data_inicio);
GO

create table vistoria(
	id_vistoria int identity not null,
	id_imovel int not null,
	id_pessoa int not null,
	tipo char(7) not null,
	descricao_estado_conservacao varchar(500) null,
	data_vistoria date not null,

	constraint pk_vistoria primary key(id_vistoria),
	constraint fk_vistoria_imovel foreign key (id_imovel) references imovel(id_imovel),
	constraint fk_vistoria_vistoriador foreign key (id_pessoa) references vistoriador(id_pessoa)
);
create index idx_vistoria_imovel on vistoria(id_imovel);
create index idx_vistoria_vistoriador on vistoria(id_pessoa);
GO

create table reparo(
	num_reparo int identity not null,
	id_vistoria int not null,
	data_reparo date not null,
	status_notificacao char(20) not null,
	responsabilidade_financeira char(12) not null,
	descricao_necessidade varchar(500) not null,

	constraint pk_reparo primary key(id_vistoria, num_reparo),
	constraint fk_reparo_vistoria foreign key (id_vistoria) references vistoria(id_vistoria),
	constraint uq_reparo unique (num_reparo)
);
GO

create table agendamento(
	id_agente int not null,
	id_locatario int not null,
	data_visita date not null,
	hora_visita time not null,

	constraint pk_agendamento primary key(id_agente, data_visita, hora_visita),
	constraint uq_agendamento_locatario unique (id_locatario, data_visita, hora_visita),
	constraint fk_agendamento_agente foreign key (id_agente) references agente(id_pessoa),
	constraint fk_agendamento_locatario foreign key (id_locatario) references locatario(id_pessoa)
);
create index idx_agendamento_locatario on agendamento(id_locatario);
create index idx_agendamento_data on agendamento(data_visita);
GO

create table auditoria_pessoa(
	id_auditoria int identity not null,
	id_pessoa int not null,
	operacao char(6) not null,
	data_operacao datetime not null default GETDATE(),
	usuario varchar(128) not null default SYSTEM_USER,
	valores_anteriores xml null,
	valores_novos xml null,

	constraint pk_auditoria_pessoa primary key (id_auditoria),
	constraint ck_auditoria_operacao check (operacao in ('INSERT', 'UPDATE', 'DELETE'))
);
create index idx_auditoria_pessoa_id_pessoa on auditoria_pessoa(id_pessoa);
GO
	
-- Views
-- Imoveis disponiveis
create view imoveis_disponiveis as
select
	i.id_imovel,
	i.endereco,
	i.descricao,
	i.valor_aluguel,
	i.area_m2,
	i.num_matricula,
	coalesce(pf.nome, pj.nome_fantasia) as nome_proprietario,
	coalesce(pf.CPF, pj.CNPJ) as documento,
	p.tipo as tipo_proprietario,
	p.telefone,
	p.email,
	pr.preferencia_contato
from imovel i
join proprietario pr on i.id_pessoa = pr.id_pessoa
join cliente c on pr.id_pessoa = c.id_pessoa
join pessoa p on c.id_pessoa = p.id_pessoa
left join pessoa_fisica pf on p.id_pessoa = pf.id_pessoa
left join pessoa_juridica pj on p.id_pessoa = pj.id_pessoa
where i.status_anuncio = 'DISPONIVEL' and c.status_conta = 1 and i.status_aptidao = 1
GO

-- Historico de contratos por locatario
create view historico_contratos_por_locatario as
select
	c.id_contrato,
	c.id_pessoa as id_locatario,
	coalesce(pf_loc.nome, pj_loc.nome_fantasia) as nome_locatario,
	i.id_imovel,
	i.endereco as endereco_imovel,
	i.area_m2,
	coalesce(pf_prop.nome, pj_prop.nome_fantasia) as nome_proprietario,
	p_prop.telefone as telefone_proprietario,
	pr.preferencia_contato,
	c.valor,
	c.data_inicio,
	c.numero_meses,
	DATEADD(MONTH, c.numero_meses, c.data_inicio) as data_prevista_fim,
	c.data_fim,
	DATEDIFF(MONTH, c.data_inicio, coalesce(c.data_fim, CAST(GETDATE() AS date))) as meses_decorridos,
	c.status_proprietario,
	c.status_locatario,
	case
		when c.data_fim is null then 'ATIVO'
		when c.data_fim < DATEADD(MONTH, c.numero_meses, c.data_inicio) then 'ENCERRADO ANTES DO PRAZO'
		else 'ENCERRADO NO PRAZO'
	end as status_contrato
from contrato c
join imovel i on c.id_imovel = i.id_imovel
join proprietario pr on i.id_pessoa = pr.id_pessoa
join pessoa p_prop on pr.id_pessoa = p_prop.id_pessoa
left join pessoa_fisica pf_prop on p_prop.id_pessoa = pf_prop.id_pessoa
left join pessoa_juridica pj_prop on p_prop.id_pessoa = pj_prop.id_pessoa
left join pessoa_fisica pf_loc on c.id_pessoa = pf_loc.id_pessoa
left join pessoa_juridica pj_loc on c.id_pessoa = pj_loc.id_pessoa
GO

-- Detalhes do imovel
create view detalhes_imovel as
select
	i.id_imovel,
	i.endereco,
	i.descricao,
	i.foto,
	i.area_m2,
	i.valor_aluguel,
	i.num_matricula,
	i.status_anuncio,
	i.status_aptidao,
	coalesce(pf.nome, pj.nome_fantasia) as nome_proprietario,
	coalesce(pf.CPF, pj.CNPJ) as documento_proprietario,
	p.tipo as tipo_proprietario,
	p.telefone as telefone_proprietario,
	p.email as email_proprietario,
	pr.preferencia_contato,
	(select count(*)
		from contrato c
		where c.id_imovel = i.id_imovel and c.data_fim is null) as contratos_ativos,
	(select top 1 coalesce(pf_loc.nome, pj_loc.nome_fantasia)
		from contrato c
		left join pessoa_fisica pf_loc on c.id_pessoa = pf_loc.id_pessoa
		left join pessoa_juridica pj_loc on c.id_pessoa = pj_loc.id_pessoa
		where c.id_imovel = i.id_imovel and c.data_fim is null
		order by c.data_inicio desc) as locatario_atual,
	(select count(*)
		from vistoria v
		where v.id_imovel = i.id_imovel) as total_vistorias,
	(select max(v.data_vistoria)
		from vistoria v
		where v.id_imovel = i.id_imovel) as data_ultima_vistoria,
	(select count(*)
		from reparo r
		join vistoria v on r.id_vistoria = v.id_vistoria
		where v.id_imovel = i.id_imovel and r.status_notificacao = 'PENDENTE') as reparos_pendentes
from imovel i
join proprietario pr on i.id_pessoa = pr.id_pessoa
join pessoa p on pr.id_pessoa = p.id_pessoa
left join pessoa_fisica pf on p.id_pessoa = pf.id_pessoa
left join pessoa_juridica pj on p.id_pessoa = pj.id_pessoa
GO

SET QUOTED_IDENTIFIER ON;
GO

create view vistorias_por_imovel as
select
	v.id_vistoria,
	i.id_imovel,
	i.endereco as endereco_imovel,
	v.tipo,
	v.data_vistoria,
	v.descricao_estado_conservacao,
	v.id_pessoa as id_vistoriador,
	pf.nome as nome_vistoriador,
	vis.especializacao,
	row_number() over (partition by v.id_imovel order by v.data_vistoria, v.id_vistoria) as numero_vistoria,
	count(*) over (partition by v.id_imovel) as total_vistorias_imovel
from vistoria v
join imovel i on v.id_imovel = i.id_imovel
join vistoriador vis on v.id_pessoa = vis.id_pessoa
join pessoa_fisica pf on vis.id_pessoa = pf.id_pessoa
GO

-- Imoveis com reparos pendentes
create view imoveis_com_reparos_pendentes as
select
	r.num_reparo,
	i.id_imovel,
	i.endereco as endereco_imovel,
	r.id_vistoria,
	r.data_reparo,
	r.status_notificacao,
	r.responsabilidade_financeira,
	r.descricao_necessidade,
	coalesce(pf.nome, pj.nome_fantasia) as nome_proprietario,
	p.telefone as telefone_proprietario
from reparo r
join vistoria v on r.id_vistoria = v.id_vistoria
join imovel i on v.id_imovel = i.id_imovel
join proprietario pr on i.id_pessoa = pr.id_pessoa
join pessoa p on pr.id_pessoa = p.id_pessoa
left join pessoa_fisica pf on p.id_pessoa = pf.id_pessoa
left join pessoa_juridica pj on p.id_pessoa = pj.id_pessoa
where r.status_notificacao = 'PENDENTE'
GO

create view agendamento_proximos_meses as
select
	a.id_agente,
	pf_ag.nome as nome_agente,
	ag.regiao_atuacao,
	a.id_locatario,
	coalesce(pf_loc.nome, pj_loc.nome_fantasia) as nome_locatario,
	p_loc.telefone as telefone_locatario,
	a.data_visita,
	a.hora_visita
from agendamento a
join agente ag on a.id_agente = ag.id_pessoa
join pessoa_fisica pf_ag on ag.id_pessoa = pf_ag.id_pessoa
join pessoa p_loc on a.id_locatario = p_loc.id_pessoa
left join pessoa_fisica pf_loc on p_loc.id_pessoa = pf_loc.id_pessoa
left join pessoa_juridica pj_loc on p_loc.id_pessoa = pj_loc.id_pessoa
where a.data_visita >= CAST(GETDATE() AS date)
	and a.data_visita < DATEADD(MONTH, 3, CAST(GETDATE() AS date))
GO

-- Procedures
-- Cadastro de pessoa fisica
create procedure cadastrar_pessoa_fisica
	@email varchar(100),
	@telefone char(14),
	@endereco varchar(200),
	@CPF char(11),
	@nome varchar(100),
	@data_nasc date,
	@estado_civil char(15),
	@nacionalidade varchar(30)
as
begin
	declare @id int;

	begin try
		begin transaction;

		insert into pessoa (email, telefone, endereco, tipo)
		values (@email, @telefone, @endereco, 'FISICA');

		set @id = SCOPE_IDENTITY();

		insert into pessoa_fisica (id_pessoa, CPF, nome, data_nasc, estado_civil, nacionalidade)
		values (@id, @CPF, @nome, @data_nasc, @estado_civil, @nacionalidade);

		commit transaction;
		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO

-- Cadastro de pessoa juridica
create procedure cadastrar_pessoa_juridica
	@email varchar(100),
	@telefone char(14),
	@endereco varchar(200),
	@CNPJ char(14),
	@nome_fantasia varchar(100),
	@razao_social varchar(100),
	@data_abertura date,
	@inscricao_estadual char(14),
	@porte varchar(20),
	@status varchar(10)
as
begin
	declare @id int;

	begin try
		begin transaction;

		insert into pessoa (email, telefone, endereco, tipo)
		values (@email, @telefone, @endereco, 'JURIDICA');

		set @id = SCOPE_IDENTITY();

		insert into pessoa_juridica (id_pessoa, CNPJ, nome_fantasia, razao_social, data_abertura, inscricao_estadual, porte, status)
		values (@id, @CNPJ, @nome_fantasia, @razao_social, @data_abertura, @inscricao_estadual, @porte, @status);

		commit transaction;
		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO
-- Cadastro de vistoriador (pessoa -> pessoa_fisica -> funcionario -> vistoriador)
create procedure cadastrar_vistoriador
	@email varchar(100),
	@telefone char(14),
	@endereco varchar(200),
	@CPF char(11),
	@nome varchar(100),
	@data_nasc date,
	@estado_civil char(15),
	@nacionalidade varchar(30),
	@data_admissao date,
	@salario numeric(10,2),
	@numero_registro_tecnico varchar(50),
	@especializacao varchar(50)
as
begin
	declare @id int;

	begin try
		begin transaction;

		insert into pessoa (email, telefone, endereco, tipo)
		values (@email, @telefone, @endereco, 'FISICA');

		set @id = SCOPE_IDENTITY();

		insert into pessoa_fisica (id_pessoa, CPF, nome, data_nasc, estado_civil, nacionalidade)
		values (@id, @CPF, @nome, @data_nasc, @estado_civil, @nacionalidade);

		insert into funcionario (id_pessoa, data_admissao, data_demissao, status_ativo, salario, tipo)
		values (@id, @data_admissao, NULL, 1, @salario, 'VISTORIADOR');

		insert into vistoriador (id_pessoa, numero_registro_tecnico, especializacao, disponibilidade)
		values (@id, @numero_registro_tecnico, @especializacao, 1);

		commit transaction;
		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO

-- Cadastro de agente (pessoa -> pessoa_fisica -> funcionario -> agente)
create procedure cadastrar_agente
	@email varchar(100),
	@telefone char(14),
	@endereco varchar(200),
	@CPF char(11),
	@nome varchar(100),
	@data_nasc date,
	@estado_civil char(15),
	@nacionalidade varchar(30),
	@data_admissao date,
	@salario numeric(10,2),
	@numero_CRECI varchar(20),
	@porcentagem_comissao numeric(5,4),
	@regiao_atuacao varchar(50)
as
begin
	declare @id int;

	begin try
		begin transaction;

		insert into pessoa (email, telefone, endereco, tipo)
		values (@email, @telefone, @endereco, 'FISICA');

		set @id = SCOPE_IDENTITY();

		insert into pessoa_fisica (id_pessoa, CPF, nome, data_nasc, estado_civil, nacionalidade)
		values (@id, @CPF, @nome, @data_nasc, @estado_civil, @nacionalidade);

		insert into funcionario (id_pessoa, data_admissao, data_demissao, status_ativo, salario, tipo)
		values (@id, @data_admissao, NULL, 1, @salario, 'AGENTE');

		insert into agente (id_pessoa, numero_CRECI, porcentagem_comissao, regiao_atuacao)
		values (@id, @numero_CRECI, @porcentagem_comissao, @regiao_atuacao);

		commit transaction;
		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO

-- Cadastro de proprietário (pessoa -> pessoa_fisica -> cliente -> proprietario)
create procedure cadastrar_proprietario
	@email varchar(100),
	@telefone char(14),
	@endereco varchar(200),
	@CPF char(11),
	@nome varchar(100),
	@data_nasc date,
	@estado_civil char(15),
	@nacionalidade varchar(30),
	@senha varchar(250),
	@preferencia_contato varchar(20),
	@dados_bancarios_agencia char(6),
	@dados_bancarios_conta char(15)
as
begin
	declare @id int;

	begin try
		begin transaction;

		insert into pessoa (email, telefone, endereco, tipo)
		values (@email, @telefone, @endereco, 'FISICA');

		set @id = SCOPE_IDENTITY();

		insert into pessoa_fisica (id_pessoa, CPF, nome, data_nasc, estado_civil, nacionalidade)
		values (@id, @CPF, @nome, @data_nasc, @estado_civil, @nacionalidade);

		insert into cliente (id_pessoa, senha, data_cadastro, status_conta)
		values (@id, @senha, CAST(GETDATE() AS date), 1);

		insert into proprietario (id_pessoa, preferencia_contato, dados_bancarios_agencia, dados_bancarios_conta)
		values (@id, @preferencia_contato, @dados_bancarios_agencia, @dados_bancarios_conta);

		commit transaction;
		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO

-- Cadastro de locatário (pessoa -> pessoa_fisica -> cliente -> locatario)
create procedure cadastrar_locatario
	@email varchar(100),
	@telefone char(14),
	@endereco varchar(200),
	@CPF char(11),
	@nome varchar(100),
	@data_nasc date,
	@estado_civil char(15),
	@nacionalidade varchar(30),
	@senha varchar(250),
	@renda_mensal numeric(10,2)
as
begin
	declare @id int;

	begin try
		begin transaction;

		insert into pessoa (email, telefone, endereco, tipo)
		values (@email, @telefone, @endereco, 'FISICA');

		set @id = SCOPE_IDENTITY();

		insert into pessoa_fisica (id_pessoa, CPF, nome, data_nasc, estado_civil, nacionalidade)
		values (@id, @CPF, @nome, @data_nasc, @estado_civil, @nacionalidade);

		insert into cliente (id_pessoa, senha, data_cadastro, status_conta)
		values (@id, @senha, CAST(GETDATE() AS date), 1);

		insert into locatario (id_pessoa, renda_mensal, status_analise_credito)
		values (@id, @renda_mensal, 'PENDENTE');

		commit transaction;
		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO

-- Criação de contrato: valida crédito e disponibilidade, grava contrato e marca imóvel como alugado
create procedure criar_contrato
	@id_locatario int,
	@id_imovel int,
	@data_inicio date,
	@numero_meses int
as
begin
	declare @status_credito varchar(20);
	declare @status_imovel char(20);

	begin try
		begin transaction

		select @id_locatario = id_pessoa
		from locatario
		where id_pessoa = @id_locatario

		if @id_locatario is null
			throw 50001, 'Locatário não encontrado', 1;

		select @status_credito = status_analise_credito
		from locatario
		where id_pessoa = @id_locatario;

		if @status_credito is null
			throw 50002, 'Status de crédito não encontrado', 1;

		if @status_credito <> 'APROVADO'
			throw 50003, 'Crédito do locatário não aprovado', 1;

		select @status_imovel = status_anuncio
		from imovel
		where id_imovel = @id_imovel;

		if @status_imovel is null
			throw 50004, 'Imóvel não encontrado', 1;

		if @status_imovel <> 'DISPONIVEL'
			throw 50005, 'Imóvel não disponível', 1;

		insert into contrato (id_pessoa, id_imovel, status_proprietario, status_locatario, data_inicio, data_fim, valor, numero_meses)
		values (@id_locatario, @id_imovel, 0, 0, @data_inicio, NULL, 0, @numero_meses);

		commit transaction;
		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO

-- Encerramento de contrato: fecha o contrato, gera vistoria final e lista reparos pendentes (o imóvel é liberado pelo trigger liberar_status_imovel_contrato)
create procedure encerrar_contrato
	@id_contrato int,
	@id_vistoriador int,
	@descricao_estado varchar(500) = NULL
as
begin
	declare @id_imovel int;
	declare @data_fim date = CAST(GETDATE() AS date);

	begin try
		begin transaction;

		if not exists (select 1 from contrato where id_contrato = @id_contrato)
			throw 50010, 'Contrato não encontrado', 1;

		select @id_imovel = id_imovel
		from contrato
		where id_contrato = @id_contrato and data_fim is null;

		if @id_imovel is null
			throw 50011, 'Contrato já encerrado', 1;

		if not exists (select 1 from vistoriador where id_pessoa = @id_vistoriador)
			throw 50012, 'Vistoriador não encontrado', 1;

		update contrato
		set data_fim = @data_fim, status_locatario = 0
		where id_contrato = @id_contrato;

		insert into vistoria (id_imovel, id_pessoa, tipo, descricao_estado_conservacao, data_vistoria)
		values (@id_imovel, @id_vistoriador, 'FINAL', @descricao_estado, @data_fim);

		commit transaction;

		select r.num_reparo, r.descricao_necessidade, r.responsabilidade_financeira
		from reparo r
		join vistoria v on v.id_vistoria = r.id_vistoria
		where v.id_imovel = @id_imovel and r.status_notificacao = 'PENDENTE';

		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO

-- Registro de vistoria: grava a vistoria, os reparos (recebidos em XML) e marca o vistoriador como ocupado
create procedure registrar_vistoria
	@id_imovel int,
	@id_vistoriador int,
	@tipo char(7),
	@descricao_estado varchar(500),
	@reparos_xml xml = NULL
as
begin
	declare @id_vistoria int;
	declare @disponibilidade bit;

	begin try
		begin transaction;

		if not exists (select 1 from imovel where id_imovel = @id_imovel)
			throw 50013, 'Imóvel não encontrado', 1;

		select @disponibilidade = disponibilidade
		from vistoriador
		where id_pessoa = @id_vistoriador;

		if @disponibilidade is null
			throw 50012, 'Vistoriador não encontrado', 1;

		if @disponibilidade = 0
			throw 50014, 'Vistoriador não está disponível', 1;

		if @tipo not in ('ENTRADA', 'FINAL')
			throw 50015, 'Tipo de vistoria inválido', 1;

		insert into vistoria (id_imovel, id_pessoa, tipo, descricao_estado_conservacao, data_vistoria)
		values (@id_imovel, @id_vistoriador, @tipo, @descricao_estado, CAST(GETDATE() AS date));

		set @id_vistoria = SCOPE_IDENTITY();

		insert into reparo (id_vistoria, data_reparo, status_notificacao, responsabilidade_financeira, descricao_necessidade)
		select
			@id_vistoria,
			CAST(GETDATE() AS date),
			'PENDENTE',
			r.value('(responsabilidade)[1]', 'char(12)'),
			r.value('(descricao)[1]', 'varchar(500)')
		from @reparos_xml.nodes('/reparos/reparo') as t(r);

		update vistoriador
		set disponibilidade = 0
		where id_pessoa = @id_vistoriador;

		commit transaction;
		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO

-- Exclusão de pessoa: bloqueia se houver registros dependentes (o histórico não é apagado)
create procedure excluir_pessoa
	@id_pessoa int
as
begin
	begin try
		begin transaction;

		if not exists (select 1 from pessoa where id_pessoa = @id_pessoa)
			throw 50022, 'Pessoa não encontrada', 1;

		if exists (select 1 from contrato where id_pessoa = @id_pessoa)
			throw 50023, 'Pessoa possui contratos como locatário', 1;

		if exists (select 1 from imovel where id_pessoa = @id_pessoa)
			throw 50024, 'Pessoa possui imóveis cadastrados', 1;

		if exists (select 1 from agendamento where id_agente = @id_pessoa or id_locatario = @id_pessoa)
			throw 50025, 'Pessoa possui agendamentos', 1;

		if exists (select 1 from vistoria where id_pessoa = @id_pessoa)
			throw 50026, 'Pessoa possui vistorias registradas', 1;

		delete from pessoa
		where id_pessoa = @id_pessoa;

		commit transaction;
		return 1;
	end try
	begin catch
		if @@TRANCOUNT > 0
			rollback transaction;
		throw;
	end catch
end
GO

-- Triggers
-- Preenchimento automatico de dados do contrato e alteracao da disponibilidade do imovel
create trigger preencher_dados_contrato_imovel on contrato for insert
as
begin
	update contrato
	set status_proprietario = 1, 
		status_locatario = 1,
		valor = i.valor_aluguel 
	from contrato c 
	inner join inserted ins on c.id_contrato = ins.id_contrato
	inner join imovel i on ins.id_imovel = i.id_imovel

	if @@ROWCOUNT > 0
	begin
		update imovel
		set status_anuncio = 'INDISPONIVEL'
		where id_imovel in (select id_imovel from inserted)

		if @@ROWCOUNT = 0
			rollback transaction
	end
	else
		rollback transaction
end
GO

-- Liberação do imóvel: quando o contrato é encerrado (data_fim preenchida), o imóvel volta a ficar disponível
create trigger liberar_status_imovel_contrato
on contrato
after update
as
begin
	if not exists (
		select 1
		from inserted ins
		join deleted d on d.id_contrato = ins.id_contrato
		where d.data_fim is null and ins.data_fim is not null)
		return;

	update imovel
	set status_anuncio = 'DISPONIVEL'
	from imovel i
	inner join inserted ins on ins.id_imovel = i.id_imovel
	inner join deleted d on d.id_contrato = ins.id_contrato
	where d.data_fim is null and ins.data_fim is not null

	if @@ROWCOUNT = 0
		rollback transaction
end
GO
		
-- Liberação do vistoriador: não permite ficar disponível com vistorias agendadas para o futuro
create trigger validar_liberacao_vistoriador
on vistoriador
after update
as
begin
	if exists (
		select 1
		from inserted i
		join deleted d on d.id_pessoa = i.id_pessoa
		where d.disponibilidade = 0 and i.disponibilidade = 1
		and exists (
			select 1
			from vistoria v
			where v.id_pessoa = i.id_pessoa and v.data_vistoria > CAST(GETDATE() AS date)))
		throw 50021, 'Vistoriador tem vistorias agendadas para os próximos dias', 1;
end
GO

-- Vínculo do agente: impede agendamento de agente sem vínculo ativo com a empresa (conflitos de horário são garantidos pela PK e pela UNIQUE)
create trigger validar_vinculo_agente
on agendamento
after insert
as
begin
	if exists (
		select 1
		from inserted i
		join funcionario f on f.id_pessoa = i.id_agente
		where f.status_ativo = 0)
		throw 50018, 'Agente sem vínculo ativo com a empresa', 1;
end
GO

-- Validação de formato do CPF: vale para qualquer INSERT ou UPDATE em pessoa_fisica
create trigger validar_formato_cpf
on pessoa_fisica
after insert, update
as
begin
	if exists (select 1 from inserted where CPF like '%[^0-9]%')
		throw 50027, 'CPF deve conter exatamente 11 dígitos numéricos', 1;
end
GO

-- Validação de formato do CNPJ: vale para qualquer INSERT ou UPDATE em pessoa_juridica
create trigger validar_formato_cnpj
on pessoa_juridica
after insert, update
as
begin
	if exists (select 1 from inserted where CNPJ like '%[^0-9]%')
		throw 50028, 'CNPJ deve conter exatamente 14 dígitos numéricos', 1;
end
GO

-- Auditoria de pessoa: registra todo INSERT, UPDATE e DELETE, com os valores antes e depois
create trigger auditoria_alteracoes_pessoa
on pessoa
after insert, update, delete
as
begin
	declare @operacao char(6);

	if not exists (select 1 from inserted) and not exists (select 1 from deleted)
		return;

	if exists (select 1 from inserted) and exists (select 1 from deleted)
		set @operacao = 'UPDATE';
	else if exists (select 1 from inserted)
		set @operacao = 'INSERT';
	else
		set @operacao = 'DELETE';

	insert into auditoria_pessoa (id_pessoa, operacao, valores_anteriores, valores_novos)
	select
		coalesce(i.id_pessoa, d.id_pessoa),
		@operacao,
		case when d.id_pessoa is not null
			then (select d.* for xml path('pessoa'), type)
		end,
		case when i.id_pessoa is not null
			then (select i.* for xml path('pessoa'), type)
		end
	from inserted i
	full outer join deleted d on d.id_pessoa = i.id_pessoa;
end
GO
