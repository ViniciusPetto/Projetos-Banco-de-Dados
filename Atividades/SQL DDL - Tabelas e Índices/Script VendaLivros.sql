use master;
GO

create database VendaLivros;
GO

use VendaLivros;
GO

create table pessoa (
codigo int not null,
nome char(100) not null,
endereco char(200) null,
telefone char(20) null,
constraint pk_pessoa primary key (codigo)
);

create table cliente (
codigo int not null,
rg char(20) not null,
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

create table livro (
codigo int not null,
titulo char(150) not null,
autor char(100) not null,
preco decimal(10,2) not null,
qtd_estoque int not null default 0,
constraint pk_livro primary key (codigo)
);

create table venda (
codigo int not null,
data date not null,
cod_cli int not null,
cod_aten int not null,
constraint pk_venda primary key (codigo),
constraint fk_venda_cliente foreign key (cod_cli) references cliente(codigo),
constraint fk_venda_atendente foreign key (cod_aten) references atendente(codigo)
);

create index ix_venda_cod_cli on venda(cod_cli);
GO

create index ix_venda_cod_aten on venda(cod_aten);
GO

create table itemvenda (
cod_venda int not null,
cod_livro int not null,
quantidade int not null,
constraint pk_itemvenda primary key (cod_venda, cod_livro),
constraint fk_itemvenda_venda foreign key (cod_venda) references venda(codigo),
constraint fk_itemvenda_livro foreign key (cod_livro) references livro(codigo)
);

create index ix_itemvenda_cod_livro on itemvenda(cod_livro);
GO
