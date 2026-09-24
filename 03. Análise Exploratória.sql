-- Projeto: Análise dos Drivers do Frete e da Experiência do Cliente (Olist)
-- Arquivo: Análise Exploratória
-- Objetivo: Explorar a distribuição dos dados e identificar padrões, dispersões 
-- SGBD: PostgreSQL

-- Discretização (binning) dos dados:
WITH classificacao AS
(SELECT order_id, SUM(price) as preço, SUM(freight_value) as frete
FROM order_items 
GROUP BY order_id), segregacao AS(
SELECT *,
CONCAT('P', NTILE(5) OVER (ORDER BY frete, order_id)) AS faixas
    FROM classificacao
)
SELECT
faixas, min(frete), max(frete),
ROUND(avg(frete),2) as media,
ROUND(stddev(frete),2) as desvio
FROM segregacao
GROUP BY faixas
ORDER BY faixas;

-- Após a divisão em quintis (P20), observou-se que o último quintil reuniu os pedidos com maiores valores de frete.
-- Foi realizada uma análise mais detalhada utilizando decis (P10).
WITH classificacao AS
(SELECT order_id, SUM(freight_value) as frete 
FROM order_items 
GROUP BY order_id), 
segregacao AS(
SELECT *,
NTILE(10) OVER (ORDER BY frete, order_id) AS decil
FROM classificacao),
nomeacao AS(
SELECT *,
    CONCAT('P', decil) AS faixas
FROM segregacao
)
SELECT
faixas, min(frete), max(frete),
ROUND(avg(frete),2) as media,
ROUND(stddev(frete),2) as desvio
FROM nomeacao
GROUP BY faixas
ORDER BY faixas;
-- Observação: o décimo decil reúne os pedidos com os maiores valores de frete; mínimo, máximo, média e desvio padrão descrevem esse grupo.

-- View consolidada: segmentação de pedidos por decil de frete
-- Utilizada nas análises de negócio (04__Insights_de_Negócios.sql)
CREATE VIEW vw_frete AS
WITH classificacao AS(
SELECT order_id, SUM(freight_value) as frete 
FROM order_items 
GROUP BY order_id)
SELECT *,
NTILE(10) OVER (ORDER BY frete, order_id) AS decil
FROM classificacao;
