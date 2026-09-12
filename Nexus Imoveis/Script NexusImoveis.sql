use master;
GO

if exists (select name from sys.databases where name = 'NexusImoveis')
    drop database NexusImoveis;
GO

create database NexusImoveis;
GO

use NexusImoveis;
GO

-- Tables

create table pessoa (
	id_pessoa int identity not null,
	email varchar(100) null,
	telefone char(14) not null,
	rua varchar(100) not null,
	numero varchar(10) not null,
	bairro varchar(50) not null,
	CEP char(8) not null,
	cidade varchar(50) not null,
	estado char(2) not null,

	constraint pk_pessoa primary key (id_pessoa)
);

create table pessoa_fisica (
	id_pessoa int not null,
	CPF char(11) not null,
	nome varchar(100) not null,
	data_nasc date not null,
	estado_civil varchar(15) not null,
	nacionalidade varchar(30) not null,

	constraint pk_pessoa_fisica primary key (id_pessoa),
	constraint fk_pessoa_fisica_pessoa foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade,
	constraint uq_pessoa_fisica unique (CPF)
);

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

create table funcionario(
	id_pessoa int not null,
	data_admissao date not null,
	data_demissao date null,
	status_ativo bit not null,
	salario numeric(10,2) not null,

	constraint pk_funcionario primary key (id_pessoa),
	constraint fk_funcionario foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade
);

create table vistoriador(
	id_pessoa int not null,
	numero_registro_tecnico varchar(50) not null,
	especializacao varchar(50) not null,
	disponibilidade bit not null,

	constraint pk_vistoriador primary key (id_pessoa),
	constraint fk_vistoriador foreign key (id_pessoa) references funcionario(id_pessoa) on delete cascade,
	constraint uq_vistoriador unique (numero_registro_tecnico)
);

create table agente(
	id_pessoa int not null,
	numero_CRECI varchar(20) not null,
	porcentagem_comissao numeric(5,4) not null constraint chk_porcentagem_comissao check (porcentagem_comissao >= 0 and porcentagem_comissao <= 1),
	regiao_atuacao varchar(50) not null,

	constraint pk_agente primary key(id_pessoa),
	constraint fk_agente foreign key (id_pessoa) references funcionario(id_pessoa) on delete cascade,
	constraint uq_agente unique (numero_CRECI)
);

create table cliente(
	id_pessoa int not null,
	senha varchar(250) not null,
	data_cadastro date not null,
	status_conta bit not null,

	constraint pk_cliente primary key(id_pessoa),
	constraint fk_cliente foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade
);

create table proprietario(
	id_pessoa int not null,
	preferencia_contato varchar(20) not null,
	dados_bancarios_agencia char(6) not null,
	dados_bancarios_conta varchar(15) not null,

	constraint pk_proprietario primary key(id_pessoa),
	constraint fk_proprietario_cliente foreign key (id_pessoa) references cliente(id_pessoa) on delete cascade
);

create table locatario(
	id_pessoa int not null,
	renda_mensal numeric(10,2) not null,
	status_analise_credito varchar(20) not null,

	constraint pk_locatario primary key(id_pessoa),
	constraint fk_locatario_cliente foreign key (id_pessoa) references cliente(id_pessoa) on delete cascade
);

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
	status_anuncio varchar(20) not null,

	constraint pk_imovel primary key(id_imovel),
	constraint fk_imovel_proprietario foreign key (id_pessoa) references proprietario(id_pessoa)
);

create table vistoria(
	id_vistoria int identity not null,
	id_imovel int not null,
	id_pessoa int not null,
	tipo char(7) not null, -- Entrada ou Saida
	descricao_estado_conservacao varchar(500) null,
	data_vistoria date not null,

	constraint pk_vistoria primary key(id_vistoria),
	constraint fk_vistoria_imovel foreign key (id_imovel) references imovel(id_imovel),
	constraint fk_vistoria_vistoriador foreign key (id_pessoa) references vistoriador(id_pessoa)
);

create table reparo(
	num_reparo int identity not null,
	id_vistoria int not null,
	data_reparo date not null,
	status_notificacao varchar(20) not null,
	responsabilidade_financeira varchar(12) not null,
	descricao_necessidade varchar(500) not null,

	constraint pk_reparo primary key(num_reparo),
	constraint fk_reparo_vistoria foreign key (id_vistoria) references vistoria(id_vistoria)
);

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

create table agendamento(
	id_agente int not null,
	id_locatario int not null,
	data_visita date not null,
	hora_visita time not null,

	constraint pk_agendamento primary key(id_agente, id_locatario, data_visita, hora_visita),
	constraint fk_agendamento_agente foreign key (id_agente) references agente(id_pessoa),
	constraint fk_agendamento_locatario foreign key (id_locatario) references locatario(id_pessoa)
);

-- Indexes

create index idx_pessoa_email on pessoa(email);
create index idx_pessoa_fisica_nome on pessoa_fisica(nome);
create index idx_imovel_status_anuncio on imovel(status_anuncio);
create index idx_imovel_valor_aluguel on imovel(valor_aluguel);
create index idx_vistoria_data on vistoria(data_vistoria);
create index idx_contrato_data_inicio on contrato(data_inicio);

GO
