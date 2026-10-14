-- Modelo fisico do banco de dados (Criado pela professora Gisele)
use master;
GO

create database ControleVendas;
GO

use ControleVendas;
GO

create table pessoa (
codigo numeric(6,0) not null,
nome char(40) not null,
endereco varchar(40) not null,
telefone numeric(12,0) null,
primary key(codigo)
)
go

create table cliente (
codigo numeric(6,0) not null,
rg char(10) not null,
dtnasc datetime null,
primary key (codigo),
foreign key (codigo) references pessoa,
unique (rg) )
go

create table atendente (
codigo numeric(6,0) not null,
salario numeric(7,2) not null,
comissao numeric(3,1) not null,
primary key (codigo),
foreign key (codigo) references pessoa )
go

create table livro (
codigo numeric(6,0) not null,
titulo char(30) not null,
autor char(30) not null,
preco numeric(7,2) not null,
qtd_estoque numeric(3,0) not null, primary key(codigo) )
go

create table venda (
codigo numeric(6,0) not null,
data datetime not null,
cod_cli numeric(6,0) not null,
cod_aten numeric(6,0) not null,
primary key (codigo),
foreign key (cod_cli) references cliente,
foreign key (cod_aten) references atendente, )
go

create index ixvenda_cli on venda(cod_cli)
go

create index ixvenda_aten on venda(cod_aten)
go

create table itemvenda (
cod_venda numeric(6,0) not null,
cod_livro numeric(6,0) not null,
quantidade numeric(3,0) not null,
primary key (cod_venda, cod_livro),
foreign key (cod_venda) references venda,
foreign key (cod_livro) references livro )
go

create index ixitemvenda_livro on itemvenda(cod_livro)
go

-- Procedimentos e transacoes

-- (a) Cadastrar cliente
create procedure cadastrar_cliente
@codigo numeric(6,0),
@nome char(40),
@endereco varchar(40),
@telefone numeric(12,0),
@rg char(10),
@dtnasc datetime
as
begin transaction
insert into pessoa values (@codigo, @nome, @endereco, @telefone)
if @@rowcount > 0
begin
    insert into cliente values (@codigo, @rg, @dtnasc)
    if @@rowcount > 0
    begin
        commit transaction
        return 1
    end
    else
    begin
        rollback transaction
        return 0
    end
end
else
begin
    rollback transaction
    return 0
end

-- Execucao da procedure cadastrar_cliente e exibicao do retorno
declare @retorno int
exec @retorno = cadastrar_cliente 
    @codigo = 1, 
    @nome = 'Jose da Silva Junior', 
    @endereco = 'Rua das Flores, 199', 
    @telefone = 11988887777, 
    @rg = '123456789', 
    @dtnasc = '1975-07-12'
print @retorno


-- (b) Cadastrar atendente
create procedure cadastrar_atendente
@codigo numeric(6,0),
@nome char(40),
@endereco varchar(40),
@telefone numeric(12,0),
@salario numeric(7,2),
@comissao numeric(3,1)
as
begin transaction
insert into pessoa values (@codigo, @nome, @endereco, @telefone)
if @@rowcount > 0
begin
    insert into atendente values (@codigo, @salario, @comissao)
    if @@rowcount > 0
    begin
        commit transaction
        return 1
    end
    else
    begin
        rollback transaction
        return 0
    end
end
else
begin
    rollback transaction
    return 0
end

-- Execucao da procedure cadastrar_atendente e exibicao do retorno
declare @retorno int
exec @retorno = cadastrar_atendente 
    @codigo = 2, 
    @nome = 'Laura Cardoso', 
    @endereco = 'Rua Ipanema, 301', 
    @telefone = 11977778888, 
    @salario = 2700.00, 
    @comissao = 10.0
print @retorno


-- (c) Cadastro de venda

-- Insercao de dois livro
insert into livro
values (1, 'Codigo Limpo', 'Robert C. Martin', 75.00, 3);

insert into livro
values (2, 'Programacao Utilizando IA', 'Tom Taulli', 60.00, 5);

create procedure cadastrar_itemvenda
@codigo numeric(6,0),
@data datetime,
@cod_cli numeric(6,0),
@cod_aten numeric(6,0),
@cod_venda numeric(6,0),
@cod_livro1 numeric(6,0),
@cod_livro2 numeric(6,0),
@quantidade_livro1 numeric(3,0),
@quantidade_livro2 numeric(3,0)
as
begin transaction
insert into venda values (@codigo, @data, @cod_cli, @cod_aten)
if @@rowcount > 0
begin
    insert into itemvenda values(@cod_venda, @cod_livro1, @quantidade_livro1)
    if @@rowcount > 0
    begin
        update livro set qtd_estoque = qtd_estoque - @quantidade_livro1 where codigo = @cod_livro1
        if @@rowcount > 0
        begin
            insert into itemvenda values(@cod_venda, @cod_livro2, @quantidade_livro2)
            if @@rowcount > 0
            begin
                update livro set qtd_estoque = qtd_estoque - @quantidade_livro2 where codigo = @cod_livro2
                if @@rowcount > 0
                begin
                    commit transaction
                    return 1
                end
                else
                begin
                    rollback transaction
                    return 0
                end
            end
            else
            begin
                rollback transaction
                return 0
            end
        end
        else
        begin
            rollback transaction
            return 0
        end
    end
    else
    begin
        rollback transaction
        return 0
    end
end
else
begin
    rollback transaction
    return 0
end

-- Execucao da procedure cadastrar_itemvenda e exibicao do retorno
declare @retorno int
declare @data_atual datetime = getdate()
exec @retorno = cadastrar_itemvenda 
    @codigo = 1, 
    @data = @data_atual, 
    @cod_cli = 1, 
    @cod_aten = 2, 
    @cod_venda = 1, 
    @cod_livro1 = 1, 
    @cod_livro2 = 2, 
    @quantidade_livro1 = 1, 
    @quantidade_livro2 = 2
print @retorno
