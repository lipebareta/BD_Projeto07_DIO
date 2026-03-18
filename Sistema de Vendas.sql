-- ============================================
-- BANCO DE DADOS: SistemaVendas
-- PROCEDURES PARA MANIPULAÇÃO DE DADOS
-- ============================================

USE SistemaVendas;

-- ============================================
-- PROCEDURE 1: Gerenciar Clientes
-- ============================================
DELIMITER $$

CREATE PROCEDURE sp_GerenciarCliente(
    -- Variável de controle (1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar)
    IN p_opcao INT,
    -- Parâmetros para as operações
    IN p_idCliente INT,
    IN p_Nome VARCHAR(100),
    IN p_CPF CHAR(11),
    IN p_CNPJ CHAR(14),
    IN p_CEP CHAR(8),
    IN p_Endereco VARCHAR(100),
    IN p_Cidade VARCHAR(45),
    IN p_Telefone VARCHAR(20)
)
BEGIN
    -- Tratamento de erro
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Erro na operação com cliente' AS Mensagem;
    END;
    
    -- Iniciar transação
    START TRANSACTION;
    
    -- Estrutura condicional para escolher a operação
    CASE p_opcao
        -- INSERIR
        WHEN 1 THEN
            INSERT INTO Cliente (Nome, CPF, CNPJ, CEP, Endereco, Cidade, Telefone)
            VALUES (p_Nome, p_CPF, p_CNPJ, p_CEP, p_Endereco, p_Cidade, p_Telefone);
            
            SELECT CONCAT('Cliente ', p_Nome, ' inserido com sucesso! ID: ', LAST_INSERT_ID()) AS Mensagem;
        
        -- ATUALIZAR
        WHEN 2 THEN
            -- Verificar se o cliente existe
            IF EXISTS (SELECT 1 FROM Cliente WHERE idCliente = p_idCliente) THEN
                UPDATE Cliente 
                SET Nome = COALESCE(p_Nome, Nome),
                    CPF = COALESCE(p_CPF, CPF),
                    CNPJ = COALESCE(p_CNPJ, CNPJ),
                    CEP = COALESCE(p_CEP, CEP),
                    Endereco = COALESCE(p_Endereco, Endereco),
                    Cidade = COALESCE(p_Cidade, Cidade),
                    Telefone = COALESCE(p_Telefone, Telefone)
                WHERE idCliente = p_idCliente;
                
                SELECT CONCAT('Cliente ID ', p_idCliente, ' atualizado com sucesso!') AS Mensagem;
            ELSE
                SELECT CONCAT('Cliente ID ', p_idCliente, ' não encontrado!') AS Mensagem;
            END IF;
        
        -- DELETAR
        WHEN 3 THEN
            -- Verificar se o cliente existe
            IF EXISTS (SELECT 1 FROM Cliente WHERE idCliente = p_idCliente) THEN
                -- Verificar se existem pedidos para este cliente
                IF EXISTS (SELECT 1 FROM Pedido WHERE Cliente_idCliente = p_idCliente) THEN
                    SELECT 'Não é possível deletar cliente com pedidos vinculados!' AS Mensagem;
                ELSE
                    DELETE FROM Cliente WHERE idCliente = p_idCliente;
                    SELECT CONCAT('Cliente ID ', p_idCliente, ' deletado com sucesso!') AS Mensagem;
                END IF;
            ELSE
                SELECT CONCAT('Cliente ID ', p_idCliente, ' não encontrado!') AS Mensagem;
            END IF;
        
        -- SELECIONAR
        WHEN 4 THEN
            IF p_idCliente IS NOT NULL THEN
                SELECT * FROM Cliente WHERE idCliente = p_idCliente;
            ELSE
                SELECT * FROM Cliente;
            END IF;
        
        -- OPÇÃO INVÁLIDA
        ELSE
            SELECT 'Opção inválida! Use 1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar' AS Mensagem;
    END CASE;
    
    -- Confirmar transação (exceto para SELECT)
    IF p_opcao IN (1,2,3) THEN
        COMMIT;
    END IF;
    
END$$

DELIMITER ;

-- ============================================
-- PROCEDURE 2: Gerenciar Produtos
-- ============================================
DELIMITER $$

CREATE PROCEDURE sp_GerenciarProduto(
    -- Variável de controle (1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar)
    IN p_opcao INT,
    -- Parâmetros para as operações
    IN p_idProduto INT,
    IN p_Nome VARCHAR(100),
    IN p_Categoria VARCHAR(45),
    IN p_Preco DECIMAL(10,2),
    IN p_Descricao TEXT
)
BEGIN
    -- Tratamento de erro
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Erro na operação com produto' AS Mensagem;
    END;
    
    START TRANSACTION;
    
    CASE p_opcao
        -- INSERIR
        WHEN 1 THEN
            INSERT INTO Produto (Nome, Categoria, Preco, Descricao)
            VALUES (p_Nome, p_Categoria, p_Preco, p_Descricao);
            
            SELECT CONCAT('Produto ', p_Nome, ' inserido com sucesso! ID: ', LAST_INSERT_ID()) AS Mensagem;
        
        -- ATUALIZAR
        WHEN 2 THEN
            IF EXISTS (SELECT 1 FROM Produto WHERE idProduto = p_idProduto) THEN
                UPDATE Produto 
                SET Nome = COALESCE(p_Nome, Nome),
                    Categoria = COALESCE(p_Categoria, Categoria),
                    Preco = COALESCE(p_Preco, Preco),
                    Descricao = COALESCE(p_Descricao, Descricao)
                WHERE idProduto = p_idProduto;
                
                SELECT CONCAT('Produto ID ', p_idProduto, ' atualizado com sucesso!') AS Mensagem;
            ELSE
                SELECT CONCAT('Produto ID ', p_idProduto, ' não encontrado!') AS Mensagem;
            END IF;
        
        -- DELETAR
        WHEN 3 THEN
            IF EXISTS (SELECT 1 FROM Produto WHERE idProduto = p_idProduto) THEN
                -- Verificar se existem pedidos ou estoque para este produto
                IF EXISTS (SELECT 1 FROM PedidoProduto WHERE Produto_idProduto = p_idProduto) OR
                   EXISTS (SELECT 1 FROM ProdutoEstoque WHERE Produto_idProduto = p_idProduto) THEN
                    SELECT 'Não é possível deletar produto com pedidos ou estoque vinculados!' AS Mensagem;
                ELSE
                    DELETE FROM Produto WHERE idProduto = p_idProduto;
                    SELECT CONCAT('Produto ID ', p_idProduto, ' deletado com sucesso!') AS Mensagem;
                END IF;
            ELSE
                SELECT CONCAT('Produto ID ', p_idProduto, ' não encontrado!') AS Mensagem;
            END IF;
        
        -- SELECIONAR
        WHEN 4 THEN
            IF p_idProduto IS NOT NULL THEN
                SELECT * FROM Produto WHERE idProduto = p_idProduto;
            ELSE
                SELECT * FROM Produto;
            END IF;
        
        ELSE
            SELECT 'Opção inválida! Use 1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar' AS Mensagem;
    END CASE;
    
    IF p_opcao IN (1,2,3) THEN
        COMMIT;
    END IF;
    
END$$

DELIMITER ;

-- ============================================
-- PROCEDURE 3: Gerenciar Pedidos
-- ============================================
DELIMITER $$

CREATE PROCEDURE sp_GerenciarPedido(
    -- Variável de controle (1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar)
    IN p_opcao INT,
    -- Parâmetros para as operações
    IN p_idPedido INT,
    IN p_Cliente_idCliente INT,
    IN p_Status VARCHAR(45),
    IN p_Descricao TEXT
)
BEGIN
    -- Tratamento de erro
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Erro na operação com pedido' AS Mensagem;
    END;
    
    START TRANSACTION;
    
    CASE p_opcao
        -- INSERIR
        WHEN 1 THEN
            -- Verificar se o cliente existe
            IF EXISTS (SELECT 1 FROM Cliente WHERE idCliente = p_Cliente_idCliente) THEN
                INSERT INTO Pedido (Cliente_idCliente, Status, Descricao)
                VALUES (p_Cliente_idCliente, COALESCE(p_Status, 'Pendente'), p_Descricao);
                
                SELECT CONCAT('Pedido inserido com sucesso! ID: ', LAST_INSERT_ID()) AS Mensagem;
            ELSE
                SELECT 'Cliente não encontrado!' AS Mensagem;
            END IF;
        
        -- ATUALIZAR
        WHEN 2 THEN
            IF EXISTS (SELECT 1 FROM Pedido WHERE idPedido = p_idPedido) THEN
                UPDATE Pedido 
                SET Status = COALESCE(p_Status, Status),
                    Descricao = COALESCE(p_Descricao, Descricao)
                WHERE idPedido = p_idPedido;
                
                SELECT CONCAT('Pedido ID ', p_idPedido, ' atualizado com sucesso!') AS Mensagem;
            ELSE
                SELECT CONCAT('Pedido ID ', p_idPedido, ' não encontrado!') AS Mensagem;
            END IF;
        
        -- DELETAR
        WHEN 3 THEN
            IF EXISTS (SELECT 1 FROM Pedido WHERE idPedido = p_idPedido) THEN
                -- Verificar status do pedido
                IF (SELECT Status FROM Pedido WHERE idPedido = p_idPedido) IN ('Entregue', 'Enviado') THEN
                    SELECT 'Não é possível deletar pedido entregue ou enviado!' AS Mensagem;
                ELSE
                    DELETE FROM Pedido WHERE idPedido = p_idPedido;
                    SELECT CONCAT('Pedido ID ', p_idPedido, ' deletado com sucesso!') AS Mensagem;
                END IF;
            ELSE
                SELECT CONCAT('Pedido ID ', p_idPedido, ' não encontrado!') AS Mensagem;
            END IF;
        
        -- SELECIONAR
        WHEN 4 THEN
            IF p_idPedido IS NOT NULL THEN
                SELECT 
                    p.*,
                    c.Nome AS NomeCliente,
                    COUNT(pp.Produto_idProduto) AS TotalProdutos,
                    SUM(pp.Quantidade * pp.PrecoUnitario) AS ValorTotal
                FROM Pedido p
                JOIN Cliente c ON p.Cliente_idCliente = c.idCliente
                LEFT JOIN PedidoProduto pp ON p.idPedido = pp.Pedido_idPedido
                WHERE p.idPedido = p_idPedido
                GROUP BY p.idPedido;
            ELSE
                SELECT 
                    p.*,
                    c.Nome AS NomeCliente,
                    COUNT(pp.Produto_idProduto) AS TotalProdutos,
                    SUM(pp.Quantidade * pp.PrecoUnitario) AS ValorTotal
                FROM Pedido p
                JOIN Cliente c ON p.Cliente_idCliente = c.idCliente
                LEFT JOIN PedidoProduto pp ON p.idPedido = pp.Pedido_idPedido
                GROUP BY p.idPedido
                ORDER BY p.DataPedido DESC;
            END IF;
        
        ELSE
            SELECT 'Opção inválida! Use 1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar' AS Mensagem;
    END CASE;
    
    IF p_opcao IN (1,2,3) THEN
        COMMIT;
    END IF;
    
END$$

DELIMITER ;

-- ============================================
-- PROCEDURE 4: Gerenciar Vendedores Terceiros
-- ============================================
DELIMITER $$

CREATE PROCEDURE sp_GerenciarVendedorTerceiro(
    -- Variável de controle (1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar)
    IN p_opcao INT,
    -- Parâmetros para as operações
    IN p_idVendedor INT,
    IN p_RazaoSocial VARCHAR(100),
    IN p_CNPJ CHAR(14),
    IN p_Email VARCHAR(100),
    IN p_Telefone VARCHAR(20),
    IN p_Contato VARCHAR(45),
    IN p_Endereco VARCHAR(100),
    IN p_Cidade VARCHAR(45)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Erro na operação com vendedor terceiro' AS Mensagem;
    END;
    
    START TRANSACTION;
    
    CASE p_opcao
        WHEN 1 THEN
            INSERT INTO VendedorTerceiro (RazaoSocial, CNPJ, Email, Telefone, Contato, Endereco, Cidade)
            VALUES (p_RazaoSocial, p_CNPJ, p_Email, p_Telefone, p_Contato, p_Endereco, p_Cidade);
            
            SELECT CONCAT('Vendedor ', p_RazaoSocial, ' inserido com sucesso! ID: ', LAST_INSERT_ID()) AS Mensagem;
        
        WHEN 2 THEN
            IF EXISTS (SELECT 1 FROM VendedorTerceiro WHERE idVendedorTerceiro = p_idVendedor) THEN
                UPDATE VendedorTerceiro 
                SET RazaoSocial = COALESCE(p_RazaoSocial, RazaoSocial),
                    CNPJ = COALESCE(p_CNPJ, CNPJ),
                    Email = COALESCE(p_Email, Email),
                    Telefone = COALESCE(p_Telefone, Telefone),
                    Contato = COALESCE(p_Contato, Contato),
                    Endereco = COALESCE(p_Endereco, Endereco),
                    Cidade = COALESCE(p_Cidade, Cidade)
                WHERE idVendedorTerceiro = p_idVendedor;
                
                SELECT CONCAT('Vendedor ID ', p_idVendedor, ' atualizado com sucesso!') AS Mensagem;
            ELSE
                SELECT CONCAT('Vendedor ID ', p_idVendedor, ' não encontrado!') AS Mensagem;
            END IF;
        
        WHEN 3 THEN
            IF EXISTS (SELECT 1 FROM VendedorTerceiro WHERE idVendedorTerceiro = p_idVendedor) THEN
                -- Verificar se existem produtos vinculados
                IF EXISTS (SELECT 1 FROM ProdutoVendedorTerceiro WHERE VendedorTerceiro_idVendedorTerceiro = p_idVendedor) THEN
                    SELECT 'Não é possível deletar vendedor com produtos vinculados!' AS Mensagem;
                ELSE
                    DELETE FROM VendedorTerceiro WHERE idVendedorTerceiro = p_idVendedor;
                    SELECT CONCAT('Vendedor ID ', p_idVendedor, ' deletado com sucesso!') AS Mensagem;
                END IF;
            ELSE
                SELECT CONCAT('Vendedor ID ', p_idVendedor, ' não encontrado!') AS Mensagem;
            END IF;
        
        WHEN 4 THEN
            IF p_idVendedor IS NOT NULL THEN
                SELECT * FROM VendedorTerceiro WHERE idVendedorTerceiro = p_idVendedor;
            ELSE
                SELECT * FROM VendedorTerceiro;
            END IF;
        
        ELSE
            SELECT 'Opção inválida! Use 1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar' AS Mensagem;
    END CASE;
    
    IF p_opcao IN (1,2,3) THEN
        COMMIT;
    END IF;
    
END$$

DELIMITER ;

-- ============================================
-- PROCEDURE 5: Gerenciar Estoque
-- ============================================
DELIMITER $$

CREATE PROCEDURE sp_GerenciarEstoque(
    -- Variável de controle (1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar, 5=Transferir)
    IN p_opcao INT,
    -- Parâmetros para as operações
    IN p_idEstoque INT,
    IN p_Localizacao VARCHAR(100),
    IN p_Responsavel VARCHAR(45),
    -- Parâmetros para transferência
    IN p_idProduto INT,
    IN p_EstoqueOrigem INT,
    IN p_EstoqueDestino INT,
    IN p_Quantidade INT
)
BEGIN
    DECLARE v_quantidade_atual INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Erro na operação com estoque' AS Mensagem;
    END;
    
    START TRANSACTION;
    
    CASE p_opcao
        WHEN 1 THEN
            INSERT INTO Estoque (Localizacao, Responsavel)
            VALUES (p_Localizacao, p_Responsavel);
            
            SELECT CONCAT('Estoque em ', p_Localizacao, ' inserido com sucesso! ID: ', LAST_INSERT_ID()) AS Mensagem;
        
        WHEN 2 THEN
            IF EXISTS (SELECT 1 FROM Estoque WHERE idEstoque = p_idEstoque) THEN
                UPDATE Estoque 
                SET Localizacao = COALESCE(p_Localizacao, Localizacao),
                    Responsavel = COALESCE(p_Responsavel, Responsavel)
                WHERE idEstoque = p_idEstoque;
                
                SELECT CONCAT('Estoque ID ', p_idEstoque, ' atualizado com sucesso!') AS Mensagem;
            ELSE
                SELECT CONCAT('Estoque ID ', p_idEstoque, ' não encontrado!') AS Mensagem;
            END IF;
        
        WHEN 3 THEN
            IF EXISTS (SELECT 1 FROM Estoque WHERE idEstoque = p_idEstoque) THEN
                -- Verificar se existem produtos no estoque
                IF EXISTS (SELECT 1 FROM ProdutoEstoque WHERE Estoque_idEstoque = p_idEstoque) THEN
                    SELECT 'Não é possível deletar estoque com produtos armazenados!' AS Mensagem;
                ELSE
                    DELETE FROM Estoque WHERE idEstoque = p_idEstoque;
                    SELECT CONCAT('Estoque ID ', p_idEstoque, ' deletado com sucesso!') AS Mensagem;
                END IF;
            ELSE
                SELECT CONCAT('Estoque ID ', p_idEstoque, ' não encontrado!') AS Mensagem;
            END IF;
        
        WHEN 4 THEN
            IF p_idEstoque IS NOT NULL THEN
                SELECT 
                    e.*,
                    COUNT(pe.Produto_idProduto) AS TotalProdutos,
                    SUM(pe.Quantidade) AS TotalItens
                FROM Estoque e
                LEFT JOIN ProdutoEstoque pe ON e.idEstoque = pe.Estoque_idEstoque
                WHERE e.idEstoque = p_idEstoque
                GROUP BY e.idEstoque;
            ELSE
                SELECT 
                    e.*,
                    COUNT(pe.Produto_idProduto) AS TotalProdutos,
                    SUM(pe.Quantidade) AS TotalItens
                FROM Estoque e
                LEFT JOIN ProdutoEstoque pe ON e.idEstoque = pe.Estoque_idEstoque
                GROUP BY e.idEstoque;
            END IF;
        
        WHEN 5 THEN
            -- Transferir produtos entre estoques
            IF p_EstoqueOrigem IS NOT NULL AND p_EstoqueDestino IS NOT NULL 
               AND p_idProduto IS NOT NULL AND p_Quantidade > 0 THEN
                
                -- Verificar quantidade disponível no estoque de origem
                SELECT Quantidade INTO v_quantidade_atual
                FROM ProdutoEstoque
                WHERE Produto_idProduto = p_idProduto 
                  AND Estoque_idEstoque = p_EstoqueOrigem;
                
                IF v_quantidade_atual >= p_Quantidade THEN
                    -- Remover do estoque de origem
                    UPDATE ProdutoEstoque 
                    SET Quantidade = Quantidade - p_Quantidade
                    WHERE Produto_idProduto = p_idProduto 
                      AND Estoque_idEstoque = p_EstoqueOrigem;
                    
                    -- Adicionar ao estoque de destino
                    INSERT INTO ProdutoEstoque (Produto_idProduto, Estoque_idEstoque, Quantidade)
                    VALUES (p_idProduto, p_EstoqueDestino, p_Quantidade)
                    ON DUPLICATE KEY UPDATE Quantidade = Quantidade + p_Quantidade;
                    
                    SELECT CONCAT('Transferência de ', p_Quantidade, ' unidades do produto ', 
                                 p_idProduto, ' realizada com sucesso!') AS Mensagem;
                ELSE
                    SELECT 'Quantidade insuficiente no estoque de origem!' AS Mensagem;
                END IF;
            ELSE
                SELECT 'Parâmetros inválidos para transferência!' AS Mensagem;
            END IF;
        
        ELSE
            SELECT 'Opção inválida! Use 1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar, 5=Transferir' AS Mensagem;
    END CASE;
    
    IF p_opcao IN (1,2,3,5) THEN
        COMMIT;
    END IF;
    
END$$

DELIMITER ;

-- ============================================
-- PROCEDURE 6: Gerenciar Entregas
-- ============================================
DELIMITER $$

CREATE PROCEDURE sp_GerenciarEntrega(
    -- Variável de controle (1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar)
    IN p_opcao INT,
    -- Parâmetros para as operações
    IN p_idEntrega INT,
    IN p_CodigoRastreio VARCHAR(50),
    IN p_StatusEntrega VARCHAR(45),
    IN p_Pedido_idPedido INT,
    IN p_DataEnvio DATE,
    IN p_PrevisaoEntrega DATE
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Erro na operação com entrega' AS Mensagem;
    END;
    
    START TRANSACTION;
    
    CASE p_opcao
        WHEN 1 THEN
            -- Verificar se o pedido existe
            IF EXISTS (SELECT 1 FROM Pedido WHERE idPedido = p_Pedido_idPedido) THEN
                INSERT INTO Entrega (CodigoRastreio, StatusEntrega, Pedido_idPedido, DataEnvio, PrevisaoEntrega)
                VALUES (p_CodigoRastreio, COALESCE(p_StatusEntrega, 'Processando'), 
                        p_Pedido_idPedido, p_DataEnvio, p_PrevisaoEntrega);
                
                SELECT CONCAT('Entrega inserida com sucesso! ID: ', LAST_INSERT_ID()) AS Mensagem;
            ELSE
                SELECT 'Pedido não encontrado!' AS Mensagem;
            END IF;
        
        WHEN 2 THEN
            IF EXISTS (SELECT 1 FROM Entrega WHERE idEntrega = p_idEntrega) THEN
                UPDATE Entrega 
                SET CodigoRastreio = COALESCE(p_CodigoRastreio, CodigoRastreio),
                    StatusEntrega = COALESCE(p_StatusEntrega, StatusEntrega),
                    DataEnvio = COALESCE(p_DataEnvio, DataEnvio),
                    PrevisaoEntrega = COALESCE(p_PrevisaoEntrega, PrevisaoEntrega)
                WHERE idEntrega = p_idEntrega;
                
                SELECT CONCAT('Entrega ID ', p_idEntrega, ' atualizada com sucesso!') AS Mensagem;
            ELSE
                SELECT CONCAT('Entrega ID ', p_idEntrega, ' não encontrada!') AS Mensagem;
            END IF;
        
        WHEN 3 THEN
            IF EXISTS (SELECT 1 FROM Entrega WHERE idEntrega = p_idEntrega) THEN
                DELETE FROM Entrega WHERE idEntrega = p_idEntrega;
                SELECT CONCAT('Entrega ID ', p_idEntrega, ' deletada com sucesso!') AS Mensagem;
            ELSE
                SELECT CONCAT('Entrega ID ', p_idEntrega, ' não encontrada!') AS Mensagem;
            END IF;
        
        WHEN 4 THEN
            IF p_idEntrega IS NOT NULL THEN
                SELECT 
                    e.*,
                    p.idPedido,
                    c.Nome AS Cliente
                FROM Entrega e
                JOIN Pedido p ON e.Pedido_idPedido = p.idPedido
                JOIN Cliente c ON p.Cliente_idCliente = c.idCliente
                WHERE e.idEntrega = p_idEntrega;
            ELSE
                SELECT 
                    e.*,
                    p.idPedido,
                    c.Nome AS Cliente
                FROM Entrega e
                JOIN Pedido p ON e.Pedido_idPedido = p.idPedido
                JOIN Cliente c ON p.Cliente_idCliente = c.idCliente
                ORDER BY e.StatusEntrega, e.PrevisaoEntrega;
            END IF;
        
        ELSE
            SELECT 'Opção inválida! Use 1=Inserir, 2=Atualizar, 3=Deletar, 4=Selecionar' AS Mensagem;
    END CASE;
    
    IF p_opcao IN (1,2,3) THEN
        COMMIT;
    END IF;
    
END$$

DELIMITER ;

-- ============================================
-- PROCEDURE 7: Relatórios Gerenciais
-- ============================================
DELIMITER $$

CREATE PROCEDURE sp_RelatoriosGerenciais(
    -- Variável de controle (1=Vendas por período, 2=Produtos mais vendidos, 
    -- 3=Clientes top, 4=Estoque baixo, 5=Pagamentos por forma)
    IN p_opcao INT,
    -- Parâmetros para filtros
    IN p_dataInicio DATE,
    IN p_dataFim DATE,
    IN p_quantidadeMinima INT
)
BEGIN
    
    CASE p_opcao
        WHEN 1 THEN
            -- Vendas por período
            SELECT 
                DATE(p.DataPedido) AS Data,
                COUNT(DISTINCT p.idPedido) AS TotalPedidos,
                COUNT(pp.Produto_idProduto) AS TotalItens,
                SUM(pp.Quantidade * pp.PrecoUnitario) AS ValorTotal,
                AVG(pp.Quantidade * pp.PrecoUnitario) AS TicketMedio
            FROM Pedido p
            JOIN PedidoProduto pp ON p.idPedido = pp.Pedido_idPedido
            WHERE DATE(p.DataPedido) BETWEEN p_dataInicio AND p_dataFim
            GROUP BY DATE(p.DataPedido)
            ORDER BY Data;
        
        WHEN 2 THEN
            -- Produtos mais vendidos
            SELECT 
                pr.idProduto,
                pr.Nome AS Produto,
                pr.Categoria,
                COUNT(DISTINCT pp.Pedido_idPedido) AS QuantidadePedidos,
                SUM(pp.Quantidade) AS UnidadesVendidas,
                SUM(pp.Quantidade * pp.PrecoUnitario) AS ValorTotal
            FROM Produto pr
            JOIN PedidoProduto pp ON pr.idProduto = pp.Produto_idProduto
            JOIN Pedido p ON pp.Pedido_idPedido = p.idPedido
            GROUP BY pr.idProduto, pr.Nome, pr.Categoria
            ORDER BY UnidadesVendidas DESC
            LIMIT 10;
        
        WHEN 3 THEN
            -- Clientes top
            SELECT 
                c.idCliente,
                c.Nome AS Cliente,
                c.Cidade,
                COUNT(DISTINCT p.idPedido) AS TotalPedidos,
                SUM(pp.Quantidade * pp.PrecoUnitario) AS ValorTotalGasto
            FROM Cliente c
            JOIN Pedido p ON c.idCliente = p.Cliente_idCliente
            JOIN PedidoProduto pp ON p.idPedido = pp.Pedido_idPedido
            GROUP BY c.idCliente, c.Nome, c.Cidade
            ORDER BY ValorTotalGasto DESC
            LIMIT 10;
        
        WHEN 4 THEN
            -- Estoque baixo (produtos com quantidade abaixo do mínimo)
            SELECT 
                pr.idProduto,
                pr.Nome AS Produto,
                pr.Categoria,
                e.Localizacao,
                pe.Quantidade,
                CASE 
                    WHEN pe.Quantidade <= 5 THEN 'CRÍTICO'
                    WHEN pe.Quantidade <= 10 THEN 'BAIXO'
                    ELSE 'NORMAL'
                END AS NivelEstoque
            FROM ProdutoEstoque pe
            JOIN Produto pr ON pe.Produto_idProduto = pr.idProduto
            JOIN Estoque e ON pe.Estoque_idEstoque = e.idEstoque
            WHERE pe.Quantidade <= COALESCE(p_quantidadeMinima, 10)
            ORDER BY pe.Quantidade;
        
        WHEN 5 THEN
            -- Pagamentos por forma
            SELECT 
                fp.Nome AS FormaPagamento,
                COUNT(DISTINCT pfp.Pedido_idPedido) AS QuantidadePedidos,
                COUNT(pfp.Valor) AS QuantidadePagamentos,
                SUM(pfp.Valor) AS ValorTotal,
                AVG(pfp.Valor) AS ValorMedio
            FROM FormaPagamento fp
            LEFT JOIN PedidoFormaPagamento pfp ON fp.idFormaPagamento = pfp.FormaPagamento_idFormaPagamento
            LEFT JOIN Pedido p ON pfp.Pedido_idPedido = p.idPedido
            GROUP BY fp.idFormaPagamento, fp.Nome
            ORDER BY ValorTotal DESC;
        
        ELSE
            SELECT 'Opção inválida! Use: 1=Vendas por período, 2=Produtos mais vendidos, 3=Clientes top, 4=Estoque baixo, 5=Pagamentos por forma' AS Mensagem;
    END CASE;
    
END$$

DELIMITER ;

-- ============================================
-- TESTES DAS PROCEDURES
-- ============================================

-- 1. Teste Inserção de Cliente
CALL sp_GerenciarCliente(1, NULL, 'Ana Pereira', '11122233344', NULL, '12345000', 
                         'Rua das Flores, 200', 'São Paulo', '(11) 99999-8888');

-- 2. Teste Selecionar Clientes
CALL sp_GerenciarCliente(4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- 3. Teste Selecionar Cliente Específico
CALL sp_GerenciarCliente(4, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- 4. Teste Atualizar Cliente
CALL sp_GerenciarCliente(2, 5, 'Ana Pereira Santos', '11122233344', NULL, '12345000', 
                         'Rua das Flores, 250', 'São Paulo', '(11) 99999-8888');

-- 5. Teste Inserção de Produto
CALL sp_GerenciarProduto(1, NULL, 'Smartwatch Pro', 'Eletrônicos', 899.90, 'Smartwatch com GPS e monitor cardíaco');

-- 6. Teste Relatório de Vendas (últimos 7 dias)
CALL sp_RelatoriosGerenciais(1, DATE_SUB(CURDATE(), INTERVAL 7 DAY), CURDATE(), NULL);

-- 7. Teste Relatório de Produtos Mais Vendidos
CALL sp_RelatoriosGerenciais(2, NULL, NULL, NULL);

-- 8. Teste Relatório de Clientes Top
CALL sp_RelatoriosGerenciais(3, NULL, NULL, NULL);

-- 9. Teste Relatório de Estoque Baixo
CALL sp_RelatoriosGerenciais(4, NULL, NULL, 15);

-- 10. Teste Transferência de Estoque
CALL sp_GerenciarEstoque(5, NULL, NULL, NULL, 1, 1, 2, 5);

-- 11. Teste Inserção de Pedido
CALL sp_GerenciarPedido(1, NULL, 1, 'Processando', 'Pedido de teste via procedure');

-- 12. Teste Selecionar Pedidos
CALL sp_GerenciarPedido(4, NULL, NULL, NULL, NULL);

-- ============================================
-- PROCEDURE EXTRA: Gerenciar Produtos em Pedidos
-- ============================================
DELIMITER $$

CREATE PROCEDURE sp_GerenciarItemPedido(
    -- Variável de controle (1=Adicionar, 2=Remover, 3=Atualizar quantidade)
    IN p_opcao INT,
    IN p_Pedido_idPedido INT,
    IN p_Produto_idProduto INT,
    IN p_Quantidade INT,
    IN p_PrecoUnitario DECIMAL(10,2)
)
BEGIN
    DECLARE v_preco_atual DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Erro na operação com item do pedido' AS Mensagem;
    END;
    
    START TRANSACTION;
    
    CASE p_opcao
        -- ADICIONAR ITEM
        WHEN 1 THEN
            -- Verificar se produto existe
            IF EXISTS (SELECT 1 FROM Produto WHERE idProduto = p_Produto_idProduto) THEN
                -- Buscar preço do produto se não foi informado
                IF p_PrecoUnitario IS NULL THEN
                    SELECT Preco INTO v_preco_atual
                    FROM Produto WHERE idProduto = p_Produto_idProduto;
                ELSE
                    SET v_preco_atual = p_PrecoUnitario;
                END IF;
                
                -- Inserir item no pedido
                INSERT INTO PedidoProduto (Pedido_idPedido, Produto_idProduto, Quantidade, PrecoUnitario)
                VALUES (p_Pedido_idPedido, p_Produto_idProduto, p_Quantidade, v_preco_atual)
                ON DUPLICATE KEY UPDATE 
                    Quantidade = Quantidade + p_Quantidade,
                    PrecoUnitario = v_preco_atual;
                
                SELECT CONCAT('Item adicionado ao pedido ', p_Pedido_idPedido) AS Mensagem;
            ELSE
                SELECT 'Produto não encontrado!' AS Mensagem;
            END IF;
        
        -- REMOVER ITEM
        WHEN 2 THEN
            DELETE FROM PedidoProduto 
            WHERE Pedido_idPedido = p_Pedido_idPedido 
              AND Produto_idProduto = p_Produto_idProduto;
            
            SELECT CONCAT('Item removido do pedido ', p_Pedido_idPedido) AS Mensagem;
        
        -- ATUALIZAR QUANTIDADE
        WHEN 3 THEN
            UPDATE PedidoProduto 
            SET Quantidade = p_Quantidade
            WHERE Pedido_idPedido = p_Pedido_idPedido 
              AND Produto_idProduto = p_Produto_idProduto;
            
            SELECT CONCAT('Quantidade atualizada no pedido ', p_Pedido_idPedido) AS Mensagem;
        
        ELSE
            SELECT 'Opção inválida!' AS Mensagem;
    END CASE;
    
    COMMIT;
    
END$$

DELIMITER ;

-- Teste da procedure de item de pedido
CALL sp_GerenciarItemPedido(1, 4, 2, 2, NULL);