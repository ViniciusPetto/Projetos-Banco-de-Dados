use master;
GO

if db_id('ControleVendas') is not null
begin
    alter database ControleVendas set single_user with rollback immediate;
    drop database ControleVendas;
end
GO

create database ControleVendas;
GO

use ControleVendas;
GO

create table pessoa(
    codigo   int       not null,
    nome     char(100) not null,
    endereco char(200) not null,
    telefone char(20)  not null,
    constraint pk_pessoa primary key (codigo)
);
GO

create table cliente(
    codigo int      not null,
    rg     char(20) not null,
    dtnasc date     not null,
    constraint pk_cliente primary key (codigo),
    constraint fk_cliente_pessoa foreign key (codigo) references pessoa(codigo)
);
GO

create table atendente(
    codigo   int           not null,
    salario  decimal(10,2) not null,
    comissao decimal(5,2)  not null,
    constraint pk_atendente primary key (codigo),
    constraint fk_atendente_pessoa foreign key (codigo) references pessoa(codigo),
    constraint ck_atendente_salario check (salario >= 0),
    constraint ck_atendente_comissao check (comissao >= 0 and comissao <= 100)
);
GO

create table livro(
    codigo      int           not null,
    titulo      char(150)     not null,
    autor       char(100)     not null,
    preco       decimal(10,2) not null,
    qtd_estoque int           not null constraint df_livro_qtd_estoque default 0,
    constraint pk_livro primary key (codigo),
    constraint ck_livro_preco check (preco >= 0),
    constraint ck_livro_qtd_estoque check (qtd_estoque >= 0)
);
GO

create table venda(
    codigo   int  not null,
    data     date not null,
    cod_cli  int  not null,
    cod_aten int  not null,
    constraint pk_venda primary key (codigo),
    constraint fk_venda_cliente foreign key (cod_cli) references cliente(codigo),
    constraint fk_venda_atendente foreign key (cod_aten) references atendente(codigo)
);
GO

create index ix_venda_cod_cli on venda(cod_cli);
GO

create index ix_venda_cod_aten on venda(cod_aten);
GO

create table itemvenda(
    cod_venda  int not null,
    cod_livro  int not null,
    quantidade int not null,
    constraint pk_itemvenda primary key (cod_venda, cod_livro),
    constraint fk_itemvenda_venda foreign key (cod_venda) references venda(codigo),
    constraint fk_itemvenda_livro foreign key (cod_livro) references livro(codigo),
    constraint ck_itemvenda_quantidade check (quantidade > 0)
);
GO

create index ix_itemvenda_cod_livro on itemvenda(cod_livro);
GO
