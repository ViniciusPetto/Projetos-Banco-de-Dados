-- Modelo fisico do banco de dados (Criado pela professora Gisele)
use master
go

create database ControleNF
go

use ControleNF
go

create table produto (
codproduto int not null,
nome varchar(60) not null,
preco numeric(5,2) not null,
qtdestoque int not null,
primary key (codproduto)
)
go

create table notafiscal (
numnota numeric(10,0) not null,
valortotal numeric(10,2) not null,
primary key (numnota)
)
go

create table itemnotafiscal (
numnota numeric(10,0) not null,
codproduto int not null,
quantidade int not null,
primary key (numnota,codproduto),
foreign key (numnota) references notafiscal,
foreign key (codproduto) references produto
)
go

create index ixitemnota_codproduto on itemnotafiscal(codproduto)
go

create table fatura (
numfatura int not null,
dtvencimento datetime not null,
dtpagamento datetime null,
valor numeric(5,2) not null,
numnota numeric(10,0) not null,
primary key (numfatura),
foreign key (numnota) references notafiscal
)
go

create index ixfatura_numnota on fatura(numnota)
go

-- Criacao da tabela faturapaga (para utilizacao na questao d)
create table faturapaga (
numfatura int not null,
dtvencimento datetime not null,
dtpagamento datetime null,
valor numeric(5,2) not null,
numnota numeric(10,0) not null,
primary key (numfatura),
foreign key (numnota) references notafiscal
)
go

create index ixfaturapaga_numnota on faturapaga(numnota)
go

-- Insercao de produtos
insert into produto values (1, 'lapis', 1.50, 20)
insert into produto values (2, 'borracha', 2.00, 15)
insert into produto values (3, 'caneta', 3.50, 25)

-- Inserção de notas fiscais
insert into notafiscal values (1, 0)

-- Gatilhos

-- (a) Atualizao da quantidade em estoque e valor da nota fiscal na insercao de um item da nota fiscal
create trigger inclusao_itemnota on itemnotafiscal for insert
as
    update notafiscal set valortotal = valortotal + (select p.preco * i.quantidade
    from produto p inner join inserted i on p.codproduto = i.codproduto)
    where numnota in (select numnota from inserted)

    update produto set qtdestoque = qtdestoque - (select quantidade
    from inserted where produto.codproduto = inserted.codproduto)
    where codproduto in (select codproduto from inserted)

    if @@rowcount = 0
        rollback transaction

execute sp_helptext 'inclusao_itemnota'

-- Inserção de itens da nota fiscal
insert into itemnotafiscal values (1, 1, 10)
insert into itemnotafiscal values (1, 2, 5)
insert into itemnotafiscal values (1, 3, 8)

--------------------------------------------------------------------------------------------------------

-- (b) Atualizao da quantidade em estoque e valor da nota fiscal na exclusao de um item da nota fiscal
create trigger exclusao_itemnota on itemnotafiscal for delete
as
    update notafiscal set valortotal = valortotal - (select p.preco * d.quantidade
    from produto p inner join deleted d on p.codproduto = d.codproduto)
    where numnota in (select numnota from deleted)

    update produto set qtdestoque = qtdestoque + (select quantidade
    from deleted where produto.codproduto = deleted.codproduto)
    where codproduto in (select codproduto from deleted)

    if @@rowcount = 0
        rollback transaction

execute sp_helptext 'exclusao_itemnota'

-- Remocao de itens da nota fiscal
delete from itemnotafiscal where numnota = 1 and codproduto = 2

--------------------------------------------------------------------------------------------------------

-- (c) Atualizao da quantidade em estoque e valor da nota fiscal na alteracao de um item da nota fiscal
create trigger alteracao_itemnota on itemnotafiscal for update
as
    if update(quantidade)
    begin
        update notafiscal set valortotal = valortotal + (select p.preco * (i.quantidade - d.quantidade)
        from produto p inner join deleted d on p.codproduto = d.codproduto
        inner join inserted i on p.codproduto = i.codproduto and i.numnota = d.numnota)
        where numnota in (select numnota from inserted)

        update produto set qtdestoque = qtdestoque - (select i.quantidade - d.quantidade
        from inserted i inner join deleted d on i.codproduto = d.codproduto)
        where codproduto in (select codproduto from inserted)

        if @@rowcount = 0
            rollback transaction
    end

execute sp_helptext 'alteracao_itemnota'

-- Alteracao de itens da nota fiscal
update itemnotafiscal set quantidade = quantidade + 5 where numnota = 1 and codproduto = 1

--------------------------------------------------------------------------------------------------------

-- (d) Remocao da tabela fatura e inclusao em faturapaga (pagamento de fatura/atualizacao da data de pagamento)
create trigger pagamento_fatura on fatura for update
as
    if update(dtpagamento)
    begin
        delete from fatura where numfatura in (select numfatura from deleted)
        insert into faturapaga select * from inserted

        if @@rowcount = 0
            rollback transaction
    end

execute sp_helptext 'pagamento_fatura'

-- Insercao de faturas e atualizacao da data de pagamento
insert into fatura values (1, '2026-10-30', null, (select valortotal from notafiscal where numnota = 1), 1)
update fatura set dtpagamento = getdate() where numfatura = 1

--------------------------------------------------------------------------------------------------------