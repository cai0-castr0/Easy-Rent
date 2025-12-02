CREATE TABLE Categoria (
                           id_categoria SERIAL PRIMARY KEY,
                           nome VARCHAR(50) NOT NULL UNIQUE,
                           valor_diaria NUMERIC(10, 2) NOT NULL
);

CREATE TABLE Carro (
                       id_carro SERIAL PRIMARY KEY,
                       placa CHAR(7) NOT NULL UNIQUE,
                       modelo VARCHAR(100) NOT NULL,
                       ano INTEGER,
                       cor VARCHAR(50),
                       status VARCHAR(20) NOT NULL CHECK (status IN ('Disponível', 'Alugado', 'Manutenção')), -- Status de disponibilidade
                       id_categoria INTEGER NOT NULL,
                       FOREIGN KEY (id_categoria) REFERENCES Categoria(id_categoria)
);

CREATE TABLE Cliente (
                         id_cliente SERIAL PRIMARY KEY,
                         cpf CHAR(11) NOT NULL UNIQUE,
                         nome VARCHAR(100) NOT NULL,
                         cnh VARCHAR(20) NOT NULL UNIQUE,
                         telefone VARCHAR(15),
                         email VARCHAR(100)
);

CREATE TABLE Funcionario (
                             id_funcionario SERIAL PRIMARY KEY,
                             cpf CHAR(11) NOT NULL UNIQUE,
                             nome VARCHAR(100) NOT NULL,
                             cargo VARCHAR(50)
);

CREATE TABLE Locacao (
                         id_locacao SERIAL PRIMARY KEY,
                         data_retirada DATE NOT NULL,
                         data_prevista_devolucao DATE NOT NULL,
                         data_devolucao DATE,
                         valor_total NUMERIC(10, 2),
                         multa NUMERIC(10, 2) DEFAULT 0.00,
                         km_inicial INTEGER NOT NULL,
                         km_final INTEGER,
                         id_cliente INTEGER NOT NULL,
                         id_carro INTEGER NOT NULL,
                         id_funcionario_retirada INTEGER NOT NULL,
                         id_funcionario_devolucao INTEGER,
                         FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
                         FOREIGN KEY (id_carro) REFERENCES Carro(id_carro),
                         FOREIGN KEY (id_funcionario_retirada) REFERENCES Funcionario(id_funcionario),
                         FOREIGN KEY (id_funcionario_devolucao) REFERENCES Funcionario(id_funcionario),
                         CHECK (data_devolucao IS NULL OR data_devolucao >= data_retirada)
);

CREATE TABLE Pagamento (
                           id_pagamento SERIAL PRIMARY KEY,
                           data_pagamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                           valor_pago NUMERIC(10, 2) NOT NULL,
                           forma_pagamento VARCHAR(50) NOT NULL,
                           id_locacao INTEGER NOT NULL,
                           FOREIGN KEY (id_locacao) REFERENCES Locacao(id_locacao)
);

CREATE VIEW Locacoes_Ativas AS
SELECT
    L.id_locacao,
    C.nome AS cliente_nome,
    CR.modelo AS carro_modelo,
    CR.placa,
    L.data_retirada,
    L.data_prevista_devolucao
FROM
    Locacao L
        JOIN
    Cliente C ON L.id_cliente = C.id_cliente
        JOIN
    Carro CR ON L.id_carro = CR.id_carro
WHERE
    L.data_devolucao IS NULL;

INSERT INTO Categoria (nome, valor_diaria) VALUES
                                               ('Hatch', 80.00),
                                               ('SUV', 150.00),
                                               ('Luxo', 300.00);

INSERT INTO Carro (placa, modelo, ano, cor, status, id_categoria) VALUES
                                                                      ('ABC1234', 'Fiat Uno', 2020, 'Branco', 'Alugado', 1),
                                                                      ('XYZ5678', 'Jeep Compass', 2023, 'Preto', 'Disponível', 2);

INSERT INTO Cliente (cpf, nome, cnh, telefone, email) VALUES
                                                          ('11122233344', 'João da Silva', '12345678901', '551199998888', 'joao@email.com'),
                                                          ('99988877766', 'Maria Souza', '09876543210', '5521977776666', 'maria@email.com');

INSERT INTO Funcionario (cpf, nome, cargo) VALUES
                                               ('12312312300', 'Pedro Admin', 'Gerente'),
                                               ('45645645600', 'Ana Vendas', 'Atendente');

INSERT INTO Locacao (data_retirada, data_prevista_devolucao, valor_total, km_inicial, id_cliente, id_carro, id_funcionario_retirada) VALUES
    ('2025-11-20', '2025-11-25', 400.00, 10000, 1, 1, 1);

INSERT INTO Pagamento (valor_pago, forma_pagamento, id_locacao) VALUES
    (400.00, 'Pix', 1);

SELECT * FROM Categoria;
SELECT * FROM Carro;
SELECT * FROM Cliente;
SELECT * FROM Funcionario;
SELECT * FROM Locacao;
SELECT * FROM Pagamento;


SELECT * FROM Carro WHERE status = 'Disponível';
SELECT * FROM Locacoes_Ativas;

UPDATE Locacao SET
                   data_devolucao = '2025-11-26',
                   multa = 80.00,
                   km_final = 10500,
                   valor_total = 480.00,
                   id_funcionario_devolucao = 2
WHERE id_locacao = 1;

UPDATE Carro SET
    status = 'Disponível'
WHERE id_carro = 1;

INSERT INTO Cliente (cpf, nome, cnh, telefone, email) VALUES
    ('10000000000', 'Cliente Teste', '99999999999', '551100000000', 'teste@email.com');

DELETE FROM Cliente WHERE cpf = '10000000000';


CREATE FUNCTION calcular_multa(id_locacao_param INTEGER)
    RETURNS NUMERIC AS $$
DECLARE
diaria_carro NUMERIC;
    dias_atraso INTEGER := 0;
    multa_total NUMERIC := 0.00;
BEGIN
SELECT
    C.valor_diaria,
    (L.data_devolucao - L.data_prevista_devolucao)
INTO
    diaria_carro,
    dias_atraso
FROM
    Locacao L
        JOIN
    Carro CR ON L.id_carro = CR.id_carro
        JOIN
    Categoria C ON CR.id_categoria = C.id_categoria
WHERE
    L.id_locacao = id_locacao_param;

IF dias_atraso > 0 THEN
        multa_total := diaria_carro * dias_atraso;
END IF;

RETURN multa_total;

END;
$$ LANGUAGE plpgsql;

CREATE PROCEDURE finalizar_locacao_sql(
    id_locacao_p INTEGER,
    data_devolucao_p DATE,
    km_final_p INTEGER,
    multa_p NUMERIC,
    valor_total_p NUMERIC,
    id_func_dev_p INTEGER
)
    LANGUAGE sql
    AS $$
UPDATE Locacao
SET data_devolucao = data_devolucao_p,
    multa = multa_p,
    valor_total = valor_total_p,
    km_final = km_final_p,
    id_funcionario_devolucao = id_func_dev_p
WHERE id_locacao = id_locacao_p;

UPDATE Carro
SET status = 'Disponível'
WHERE id_carro = (SELECT id_carro FROM Locacao WHERE id_locacao = id_locacao_p);

INSERT INTO Pagamento (valor_pago, forma_pagamento, id_locacao)
VALUES (valor_total_p, 'Fechamento Procedure', id_locacao_p);
$$;