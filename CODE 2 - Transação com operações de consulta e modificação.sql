-- ============================================
-- TRANSAÇÃO SEM PROCEDURE
-- Operações: Inserir cliente, inserir produto e criar pedido
-- ============================================

-- Iniciar a transação
START TRANSACTION;

-- 1. Inserir um novo cliente
INSERT INTO Cliente (Nome, CPF, CEP, Endereco, Cidade, Telefone)
VALUES ('Carlos Eduardo', '12345678901', '04567000', 'Av. Paulista, 1500', 'São Paulo', '(11) 91234-5678');

-- Variável para armazenar o ID do cliente inserido
SET @idCliente = LAST_INSERT_ID();
SELECT CONCAT('Cliente inserido com ID: ', @idCliente) AS 'Status';

-- 2. Inserir um novo produto
INSERT INTO Produto (Nome, Categoria, Preco, Descricao)
VALUES ('Notebook Ultra', 'Informática', 4500.00, 'Notebook 16GB RAM, SSD 512GB');

-- Variável para armazenar o ID do produto inserido
SET @idProduto = LAST_INSERT_ID();
SELECT CONCAT('Produto inserido com ID: ', @idProduto) AS 'Status';

-- 3. Criar um pedido para o cliente
INSERT INTO Pedido (Cliente_idCliente, Status, Descricao)
VALUES (@idCliente, 'Pendente', 'Pedido via transação manual');

-- Variável para armazenar o ID do pedido
SET @idPedido = LAST_INSERT_ID();
SELECT CONCAT('Pedido criado com ID: ', @idPedido) AS 'Status';

-- 4. Adicionar o produto ao pedido
INSERT INTO PedidoProduto (Pedido_idPedido, Produto_idProduto, Quantidade, PrecoUnitario)
VALUES (@idPedido, @idProduto, 2, 4500.00);

-- 5. Verificar se os dados foram inseridos corretamente
SELECT '=== DADOS INSERIDOS ===' AS '';
SELECT * FROM Cliente WHERE idCliente = @idCliente;
SELECT * FROM Produto WHERE idProduto = @idProduto;
SELECT p.*, c.Nome AS NomeCliente 
FROM Pedido p
JOIN Cliente c ON p.Cliente_idCliente = c.idCliente
WHERE p.idPedido = @idPedido;

SELECT pp.*, pr.Nome AS NomeProduto
FROM PedidoProduto pp
JOIN Produto pr ON pp.Produto_idProduto = pr.idProduto
WHERE pp.Pedido_idPedido = @idPedido;

-- 6. Confirmar a transação (COMMIT)
COMMIT;
SELECT 'TRANSAÇÃO CONFIRMADA COM SUCESSO!' AS 'Resultado';

-- 7. Teste com ROLLBACK (opcional - descomente para testar)
-- START TRANSACTION;
-- INSERT INTO Cliente (Nome, CPF) VALUES ('Teste Rollback', '99999999999');
-- SELECT 'Cliente de teste inserido, mas será desfeito' AS 'Status';
-- ROLLBACK;
-- SELECT 'ROLLBACK executado - cliente não persistiu' AS 'Status';
-- SELECT * FROM Cliente WHERE CPF = '99999999999';

-- Reabilitar autocommit (opcional)
SET autocommit = 1;