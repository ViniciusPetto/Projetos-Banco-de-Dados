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
dtpagamento date null,
valor decimal(10,2) not null,
numnota int not null,
constraint pk_numfatura primary key (numfatura),
constraint fk_fatura_numnota foreign key (numnota) references notafiscal(numnota)
);

create index ix_fatura_numnota on fatura(numnota);
GO 

--A)
Use SistemaFiscal;
GO

create view NeverSold as
select p.codproduto, p.nome, p.qtdestoque
from produto p
left join itemnotafiscal inf on p.codproduto = inf.codproduto where inf.codproduto is null;
GO

--B)
Use SistemaFiscal;
GO

create view Sold as
select p.codproduto, p.nome, SUM(inf.quantidade) as QuantidadeVendida
from produto p 
inner join itemnotafiscal inf on  p.codproduto = inf.codproduto
group by p.codproduto, p.nome;
GO

--C)
Use SistemaFiscal;
GO

create view TotalSold as 
select p.nome, p.preco, nf.numnota, nf.valortotal, inf.quantidade as QuantidadeVendida, (inf.quantidade * p.preco) as ValorVendido
from notafiscal nf 
inner join itemnotafiscal inf on nf.numnota = inf.numnota
inner join produto p on p.codproduto = inf.codproduto;
GO

--D)
Use SistemaFiscal;
GO

create view NotPaid as
select nf.numnota, nf.valortotal, f.numfatura, f.dtvencimento, f.valor
from notafiscal nf
inner join fatura f on nf.numnota = f.numnota where f.dtpagamento is null;
GO

--E)
Use SistemaFiscal;
GO

create view Paid as 
select nf.numnota, nf.valortotal
from notafiscal nf
inner join fatura f on nf.numnota = f.numnota 
group by nf.numnota, nf.valortotal
having COUNT (f.numfatura) = COUNT (f.dtpagamento);
GO


