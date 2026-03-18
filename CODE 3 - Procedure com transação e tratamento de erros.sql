-- ============================================
-- PROCEDURE COM TRANSAÇÃO E TRATAMENTO DE ERROS
-- Função: Processar pedido completo com validações e SAVEPOINT
-- ============================================
DELIMITER $$

CREATE PROCEDURE sp_ProcessarPedidoCompleto(
    IN p_NomeCliente VARCHAR(100),
    IN p_CPFCliente CHAR(11),
    IN p_TelefoneCliente VARCHAR(20),
    IN p_EnderecoCliente VARCHAR(100),
    IN p_CidadeCliente VARCHAR(45),
    IN p_ProdutosJSON JSON, -- Formato: [{"id":1, "qtd":2}, {"id":3, "qtd":1}]
    IN p_FormaPagamento VARCHAR(45),
    OUT p_Mensagem VARCHAR(200),
    OUT p_Sucesso BOOLEAN
)
BEGIN
    -- Declaração de variáveis
    DECLARE v_idCliente INT;
    DECLARE v_idPedido INT;
    DECLARE v_idPagamento INT;
    DECLARE v_totalPedido DECIMAL(10,2) DEFAULT 0;
    DECLARE v_indice INT DEFAULT 0;
    DECLARE v_qtdeProdutos INT;
    DECLARE v_idProduto INT;
    DECLARE v_quantidade INT;
    DECLARE v_precoProduto DECIMAL(10,2);
    DECLARE v_estoqueDisponivel INT;
    DECLARE v_erro BOOLEAN DEFAULT FALSE;
    DECLARE v_error_message VARCHAR(200);
    
    -- Declaração do handler para erro
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_message = MESSAGE_TEXT;
        
        ROLLBACK;
        SET p_Sucesso = FALSE;
        SET p_Mensagem = CONCAT('Erro ao processar pedido: ', v_error_message);
    END;
    
    -- Iniciar transação
    START TRANSACTION;
    
    -- Ponto de salvamento inicial
    SAVEPOINT inicio_transacao;
    
    -- 1. Verificar ou criar cliente
    SELECT idCliente INTO v_idCliente
    FROM Cliente
    WHERE CPF = p_CPFCliente
    LIMIT 1;
    
    IF v_idCliente IS NULL THEN
        -- Cliente não existe, criar novo
        INSERT INTO Cliente (Nome, CPF, Telefone, Endereco, Cidade)
        VALUES (p_NomeCliente, p_CPFCliente, p_TelefoneCliente, p_EnderecoCliente, p_CidadeCliente);
        
        SET v_idCliente = LAST_INSERT_ID();
        SELECT CONCAT('Novo cliente criado: ', v_idCliente) AS 'Log';
    ELSE
        SELECT CONCAT('Cliente existente encontrado: ', v_idCliente) AS 'Log';
    END IF;
    
    SAVEPOINT apos_cliente;
    
    -- 2. Criar o pedido
    INSERT INTO Pedido (Cliente_idCliente, Status, Descricao)
    VALUES (v_idCliente, 'Em processamento', 'Pedido processado via procedure');
    
    SET v_idPedido = LAST_INSERT_ID();
    SELECT CONCAT('Pedido criado: ', v_idPedido) AS 'Log';
    
    SAVEPOINT apos_pedido;
    
    -- 3. Processar produtos do JSON
    SET v_qtdeProdutos = JSON_LENGTH(p_ProdutosJSON);
    
    WHILE v_indice < v_qtdeProdutos AND NOT v_erro DO
        -- Extrair dados do produto do JSON
        SET v_idProduto = JSON_EXTRACT(p_ProdutosJSON, CONCAT('$[', v_indice, '].id'));
        SET v_quantidade = JSON_EXTRACT(p_ProdutosJSON, CONCAT('$[', v_indice, '].qtd'));
        
        -- Converter para inteiro
        SET v_idProduto = CAST(v_idProduto AS UNSIGNED);
        SET v_quantidade = CAST(v_quantidade AS UNSIGNED);
        
        -- Verificar se o produto existe
        IF NOT EXISTS (SELECT 1 FROM Produto WHERE idProduto = v_idProduto) THEN
            SET v_erro = TRUE;
            SET p_Mensagem = CONCAT('Produto ID ', v_idProduto, ' não encontrado!');
            ROLLBACK TO SAVEPOINT apos_cliente;
        ELSE
            -- Verificar estoque (simplificado - considera estoque 1 como principal)
            SELECT Quantidade INTO v_estoqueDisponivel
            FROM ProdutoEstoque
            WHERE Produto_idProduto = v_idProduto
            LIMIT 1;
            
            IF v_estoqueDisponivel < v_quantidade THEN
                SET v_erro = TRUE;
                SET p_Mensagem = CONCAT('Estoque insuficiente para o produto ', v_idProduto, 
                                       '. Disponível: ', v_estoqueDisponivel, ', Solicitado: ', v_quantidade);
                ROLLBACK TO SAVEPOINT apos_cliente;
            ELSE
                -- Buscar preço do produto
                SELECT Preco INTO v_precoProduto
                FROM Produto
                WHERE idProduto = v_idProduto;
                
                -- Inserir no pedido
                INSERT INTO PedidoProduto (Pedido_idPedido, Produto_idProduto, Quantidade, PrecoUnitario)
                VALUES (v_idPedido, v_idProduto, v_quantidade, v_precoProduto);
                
                -- Atualizar estoque
                UPDATE ProdutoEstoque
                SET Quantidade = Quantidade - v_quantidade
                WHERE Produto_idProduto = v_idProduto
                LIMIT 1;
                
                -- Calcular total
                SET v_totalPedido = v_totalPedido + (v_precoProduto * v_quantidade);
                
                SELECT CONCAT('Produto ', v_idProduto, ' adicionado: ', v_quantidade, ' unidades') AS 'Log';
            END IF;
        END IF;
        
        SET v_indice = v_indice + 1;
    END WHILE;
    
    -- Se houve erro, abortar
    IF v_erro THEN
        SET p_Sucesso = FALSE;
        IF p_Mensagem IS NULL THEN
            SET p_Mensagem = 'Erro desconhecido no processamento dos produtos';
        END IF;
        -- Não precisa de ROLLBACK aqui, já foi feito no SAVEPOINT
    ELSE
        SAVEPOINT apos_produtos;
        
        -- 4. Processar pagamento
        -- Buscar ID da forma de pagamento
        SELECT idFormaPagamento INTO v_idPagamento
        FROM FormaPagamento
        WHERE Nome = p_FormaPagamento
        LIMIT 1;
        
        IF v_idPagamento IS NULL THEN
            -- Se não existir, usar padrão (1 - Cartão de Crédito)
            SET v_idPagamento = 1;
        END IF;
        
        -- Registrar pagamento
        INSERT INTO PedidoFormaPagamento (Pedido_idPedido, FormaPagamento_idFormaPagamento, Valor)
        VALUES (v_idPedido, v_idPagamento, v_totalPedido);
        
        -- Atualizar status do pedido
        UPDATE Pedido
        SET Status = 'Pago'
        WHERE idPedido = v_idPedido;
        
        -- Se tudo deu certo, confirmar transação
        COMMIT;
        
        SET p_Sucesso = TRUE;
        SET p_Mensagem = CONCAT('Pedido ', v_idPedido, ' processado com sucesso! Valor total: R$ ', v_totalPedido);
    END IF;
    
END$$

DELIMITER ;

-- ============================================
-- TESTE DA PROCEDURE COM TRANSAÇÃO
-- ============================================

-- Teste 1: Pedido com produtos válidos
SET @json_produtos = '[{"id": 1, "qtd": 2}, {"id": 3, "qtd": 1}]';
CALL sp_ProcessarPedidoCompleto(
    'João Silva',
    '98765432100',
    '(11) 97777-1234',
    'Rua Augusta, 500',
    'São Paulo',
    @json_produtos,
    'Cartão de Crédito',
    @mensagem,
    @sucesso
);

SELECT @mensagem AS 'Resultado', @sucesso AS 'Sucesso';

-- Teste 2: Pedido com produto sem estoque (deve gerar ROLLBACK parcial)
SET @json_produtos_erro = '[{"id": 1, "qtd": 999}, {"id": 3, "qtd": 1}]';
CALL sp_ProcessarPedidoCompleto(
    'Maria Oliveira',
    '12312312300',
    '(11) 96666-4321',
    'Rua Oscar Freire, 300',
    'São Paulo',
    @json_produtos_erro,
    'Pix',
    @mensagem,
    @sucesso
);

SELECT @mensagem AS 'Resultado', @sucesso AS 'Sucesso';

-- Teste 3: Pedido com produto inexistente (deve gerar ROLLBACK parcial)
SET @json_produtos_erro2 = '[{"id": 999, "qtd": 1}]';
CALL sp_ProcessarPedidoCompleto(
    'Pedro Santos',
    '45645645600',
    '(11) 95555-6789',
    'Rua Haddock Lobo, 800',
    'São Paulo',
    @json_produtos_erro2,
    'Boleto',
    @mensagem,
    @sucesso
);

SELECT @mensagem AS 'Resultado', @sucesso AS 'Sucesso';

-- Verificar resultados
SELECT '=== PEDIDOS PROCESSADOS ===' AS '';
SELECT * FROM Pedido ORDER BY idPedido DESC LIMIT 5;
SELECT * FROM PedidoProduto ORDER BY Pedido_idPedido DESC LIMOT 10;