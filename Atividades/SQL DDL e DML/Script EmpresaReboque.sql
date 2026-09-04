USE master;
GO

-- Criando base de dados da Empresa de Reboque e suas tabelas
CREATE DATABASE EmpresaReboque;
GO

USE EmpresaReboque;
GO

CREATE TABLE motorista (
    codigo        INT          NOT NULL,
    nome          CHAR(100)    NOT NULL,
    nro_carteira  INT          NOT NULL,
    hora_entrada  TIME         NULL,
    hora_saida    TIME         NULL,
    CONSTRAINT pk_motorista PRIMARY KEY (codigo)
);

CREATE TABLE cliente (
    codigo    INT         NOT NULL,
    rg        CHAR(15)    NOT NULL,
    nome      CHAR(100)   NOT NULL,
    endereco  CHAR(200)   NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (codigo),
    CONSTRAINT uq_cliente_rg UNIQUE (rg)
);

CREATE TABLE veiculo (
    placa  CHAR(7)     NOT NULL,
    marca  CHAR(50)    NOT NULL,
    cor    CHAR(50)    NULL,
    CONSTRAINT pk_veiculo PRIMARY KEY (placa)
);

CREATE TABLE ocorrencia (
    codigo         INT           NOT NULL,
    end_busca      CHAR(200)     NOT NULL,
    end_entrega    CHAR(200)     NOT NULL,
    data           DATE          NOT NULL,
    distancia      INT           NOT NULL,
    preco          DECIMAL(10,2) NOT NULL,
    pago           DECIMAL(10,2) NOT NULL,
    cod_motorista  INT           NOT NULL,
    cod_cliente    INT           NOT NULL,
    placa          CHAR(7)       NOT NULL,
    CONSTRAINT pk_ocorrencia PRIMARY KEY (codigo),
    CONSTRAINT fk_ocorrencia_motorista FOREIGN KEY (cod_motorista) REFERENCES motorista(codigo),
    CONSTRAINT fk_ocorrencia_cliente FOREIGN KEY (cod_cliente) REFERENCES cliente(codigo),
    CONSTRAINT fk_ocorrencia_veiculo FOREIGN KEY (placa) REFERENCES veiculo(placa)
);

CREATE INDEX idx_ocorrencia_motorista ON ocorrencia(cod_motorista);

CREATE INDEX idx_ocorrencia_cliente ON ocorrencia(cod_cliente);
GO
    
CREATE INDEX idx_ocorrencia_veiculo ON ocorrencia(placa);
GO


-- CRUD no banco de dados
-- A)
INSERT INTO motorista VALUES (1, 'Joao da Silva', 123456, '06:00:00', '13:00:00');
INSERT INTO motorista VALUES (5, 'Rogerio Nunes', 789101, '11:00:00', '17:30:00');

-- B)
INSERT INTO cliente VALUES (1, '123456789', 'Roberto Gomes', 'Rua das Flores, 197, Bairro Sao Joao, LImeira - SP');

-- C)
INSERT INTO veiculo VALUES ('ABC1D23', 'Volkswagen', 'Branco');
INSERT INTO veiculo VALUES ('AAA5555', 'Chevrolet', 'Prata');
-- D)
INSERT INTO ocorrencia 
(
    codigo,
    end_busca,
    end_entrega,
    data,
    distancia,
    preco,
    pago,
    cod_motorista,
    cod_cliente,
    placa
)
VALUES 
(
    10,
    'Rua das Palmeiras, 100, Limeira - SP',
    'Avenida Brasil, 500, Limeira - SP',
    '2026-08-15',
    12,
    180.00,
    'N',
    1,
    1,
    'ABC1D23'
);
``
-- E)

UPDATE ocorrencia
SET pago = 'S'
WHERE codigo = 10;

-- F)

UPDATE motorista SET hora_saida = '18:00:00' WHERE codigo = 5;

-- G)

DELETE FROM ocorrencia
WHERE data >= '2026-08-01'
  AND data < '2026-09-01'
  AND pago = 'S';

-- H)

DELETE FROM veiculo
WHERE placa = 'AAA5555';

-- I)

SELECT *
FROM motorista
WHERE hora_entrada = '06:00:00'
  AND hora_saida = '13:00:00';

-- J)

-- K)

-- L)

-- M)

-- N)
