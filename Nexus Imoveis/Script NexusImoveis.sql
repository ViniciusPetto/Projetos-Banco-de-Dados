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
	constraint fk_imovel_proprietario foreign key (id_pessoa) references proprietario(id_pessoa)
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

	constraint pk_agendamento primary key(id_agente, id_locatario),
	constraint fk_agendamento_agente foreign key (id_agente) references agente(id_pessoa),
	constraint fk_agendamento_locatario foreign key (id_locatario) references locatario(id_pessoa)
);
create index idx_agendamento_locatario on agendamento(id_locatario);
create index idx_agendamento_data on agendamento(data_visita);
GO

-- Views

-- Procedures
--Cadastro de pessoa fisica
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
	@valor numeric(10,2),
	@numero_meses int
as
begin
	declare @status_credito varchar(20);
	declare @status_imovel char(20);

	begin try
		begin transaction;

		select @status_credito = status_analise_credito
		from locatario
		where id_pessoa = @id_locatario;

		if @status_credito is null
			throw 50001, 'Locatário não encontrado', 1;

		if @status_credito <> 'APROVADO'
			throw 50002, 'Crédito do locatário não aprovado', 1;

		select @status_imovel = status_anuncio
		from imovel
		where id_imovel = @id_imovel;

		if @status_imovel is null
			throw 50003, 'Imóvel não encontrado', 1;

		if @status_imovel <> 'DISPONÍVEL'
			throw 50004, 'Imóvel não disponível', 1;

		insert into contrato (id_pessoa, id_imovel, status_proprietario, status_locatario, data_inicio, data_fim, valor, numero_meses)
		values (@id_locatario, @id_imovel, 1, 1, @data_inicio, NULL, @valor, @numero_meses);

		update imovel
		set status_anuncio = 'ALUGADO'
		where id_imovel = @id_imovel;

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
