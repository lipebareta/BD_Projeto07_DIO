-- Desabilitar o autocommit para controlar manualmente as transações
SET autocommit = 0;

-- Verificar se o autocommit foi desabilitado
SELECT @@autocommit;