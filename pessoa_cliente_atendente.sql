create database VendaLivros
use VendaLivros;

create table pessoa (
codigo INT not null,
nome char(100) not null,
endereco char(200) null,
telefone char(20) null,
constraint pk_pessoa primary key (codigo)
);

create table cliente (
codigo INT not null,
rg char(15) not null,
dtnasc date null,
constraint pk_cliente primary key (codigo),
constraint fk_cliente_pessoa foreign key (codigo) references pessoa(codigo),
constraint uq_cliente_rg unique (rg)
);

create table atendente (
codigo int not null,
salario decimal(10,2) not null,
comissao decimal(5,2) not null,
constraint pk_atendente primary key (codigo),
constraint fk_atendente_pessoa foreign key (codigo) references pessoa(codigo)
);