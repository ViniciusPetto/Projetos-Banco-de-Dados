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
/*on delete cascade permite, ao deletar um registro da tabela pai, ele também é deletado na tabela filho,
evitando dados órfãos*/