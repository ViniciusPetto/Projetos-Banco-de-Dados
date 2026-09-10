use master;
GO

create database NexusImoveis;
GO

use NexusImoveis;
GO

create table pessoa (
	id_pessoa int identity not null,
	email char(40) null,
	telefone char(14) not null,
	rua varchar(100) not null,
	numero char(20) not null,
	bairro varchar(80) not null,
	CEP int not null,
	cidade char(50) not null,
	estado char(2) not null,

	constraint pk_pessoa primary key (id_pessoa)
);

create table pessoa_fisica (
	id_pessoa int not null,
	CPF char(11) not null,
	nome varchar(100) not null,
	data_nasc date not null,
	estado_civil char(11) not null,
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
	porte char(30) not null,
	status char(10) not null,

	constraint pk_pessoa_juridica primary key (id_pessoa),
	constraint fk_pessoa_juridica_pessoa foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade,
	constraint uq_pessoa_juridica unique (CNPJ)
);

create table funcionario(
	id_pessoa int not null,
	data_admissao date not null,
	data_demissao date null,
	status_ativo boolean not null,
	salario numeric(10,2) not null,

	constraint pk_funcionario primary key (id_pessoa),
	constraint fk_funcionario foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade
);

create table vistoriador(
	id_pessoa int not null,
	numero_registro_tecnico char(50) not null,
	especializacao char(50) not null,
	disponibilidade boolean not null,

	constraint pk_vistoriador primary key (id_pessoa),
	constraint fk_vistoriador foreign key (id_pessoa) references funcionario(id_pessoa) on delete cascade,
	constraint uq_vistoriador unique (numero_registro_tecnico)
);

create table agente(
	id_pessoa int not null,
	numero_CRECI char(20) not null,
	porcentagem_comissao numeric(5,4) not null constraint chk_porcentagem_comissao check (porcentagem_comissao>= 0 and porcentagem_comissao <=1),
	regiao_atuacao char(50) not null,

	constraint pk_agente primary key(id_pessoa),
	constraint fk_agente foreign key (id_pessoa) references funcionario(id_pessoa) on delete cascade,
	constraint uq_agente unique (numero_CRECI)
);

create table cliente(
	id_pessoa int not null,
	senha varchar(250) not null,
	data_cadastro date not null,
	status_conta boolean not null,

	constraint pk_cliente primary key(id_pessoa),
	constraint fk_cliente foreign key (id_pessoa) references pessoa(id_pessoa) on delete cascade,
);

/*on delete cascade permite, ao deletar um registro da tabela pai, ele também é deletado na tabela filho,
evitando dados órfãos*/