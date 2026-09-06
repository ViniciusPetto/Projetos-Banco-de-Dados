use master;
GO

create database SistemaFiscal;
GO

use SistemaFiscal;
GO

create table produto(
codproduto int not null,
nome char(100) not null,
preco decimal(10,2) not null,
qtdestoque int not null default 0,
constraint pk_produto primary key (codproduto)
);


create table notafiscal(
numnota int not null,
valortotal decimal(10,2) not null,
constraint pk_notafiscal primary key (numnota)
);

create table itemnotafiscal(
numnota int not null,
codproduto int not null,
quantidade int not null default 0,
constraint pk_itemnotafiscal primary key (numnota, codproduto),
constraint fk_itemnotafiscal_codproduto foreign key (codproduto) references produto(codproduto),
constraint fk_itemnotafiscal_notafiscal foreign key (numnota) references notafiscal(numnota)
);

create index ix_itemnotafiscal_codproduto on itemnotafiscal(codproduto);
GO

create index ix_itemnotafiscal_numnota on itemnotafiscal(numnota);
GO

create table fatura(
numfatura int not null,
dtvencimento date not null,
dtpagamento date not null,
valor decimal(10,2) not null,
numnota int not null,
constraint pk_numfatura primary key (numfatura),
constraint fk_fatura_numnota foreign key (numnota) references notafiscal(numnota)
);

create index ix_fatura_numnota on fatura(numnota);
GO 

