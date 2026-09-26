-- Projeto: Análise dos Drivers do Frete e da Experiência do Cliente (Olist)
-- Arquivo: Qualidade dos Dados
-- Objetivo: Avaliar consistência dos dados, identificando duplicidades e valores inválidos
-- SGBD: PostgreSQL

-- Identificação de duplicidade na chave (order_id, order_item_id):
SELECT order_id, order_item_id, COUNT(*)
from order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*)>1;

-- Verificação de preços/valores de frete negativos, nulos ou equivalentes a zero:
SELECT
  COUNT(*) FILTER (WHERE price <= 0) AS preco_invalido,
  COUNT(*) FILTER (WHERE freight_value < 0) AS frete_negativo,
  COUNT(*) FILTER (WHERE price IS NULL OR freight_value IS NULL) AS preco_frete_nulo
FROM order_items;

-- Análise de pedidos com múltiplos itens ou item único:
WITH contagem AS (
SELECT  order_id, COUNT (*) as conta
FROM order_items
GROUP BY order_id)
SELECT
SUM(CASE WHEN conta > 1 THEN 1 ELSE 0 END) as qtd_varios_itens,
SUM (CASE WHEN conta<=1 THEN 1 ELSE 0 END) as qtd_um_item
FROM contagem;

-- Análise de review scores fora do range 1-5:
SELECT COUNT(*)
FROM order_reviews_dataset
WHERE review_score < 1 OR review_score > 5;

-- Análise da existência de duplicidade de review_id:
WITH reviews_repetidos AS(
SELECT review_id,COUNT(*)
FROM order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*)>1)
SELECT COUNT (*)
FROM reviews_repetidos;

-- Analisando se os reviews id repetidos possuem diferença no score atribuído:
SELECT review_id, COUNT (DISTINCT review_score) 
FROM order_reviews_dataset
WHERE review_id IN (
				SELECT review_id
				FROM order_reviews_dataset
				GROUP BY review_id
				HAVING COUNT(*)>1)
GROUP BY review_id
HAVING COUNT (DISTINCT review_score) >1;

-- Analisando se os reviews id repetidos possuem diferença no order_id:
WITH order_distinto AS (SELECT review_id, COUNT (DISTINCT order_id) 
FROM order_reviews_dataset
WHERE review_id IN (
				SELECT review_id
				FROM order_reviews_dataset
				GROUP BY review_id
				HAVING COUNT(*)>1)
GROUP BY review_id
HAVING COUNT (DISTINCT order_id) >1)
SELECT COUNT (*) from order_distinto;

-- Verificando existência de Review_score nulo:
SELECT COUNT (*) 
FROM order_reviews_dataset
WHERE review_score IS NULL;

-- Comparação dos valores de frete entre itens de pedidos com mais de um item.
-- A consulta conta quantos pedidos têm valores de freight_value iguais ou diferentes nas linhas dos seus itens.
-- Essa comparação não determina, por si só, o frete total do pedido.

WITH ranking AS(
SELECT 
  order_id,
  freight_value,
  DENSE_RANK () OVER (PARTITION BY order_id ORDER BY freight_value) AS rn
FROM order_items
WHERE order_id IN 
	(SELECT order_id
	 FROM order_items
	 GROUP BY order_id
	 HAVING COUNT (*) >1
	)
), 
ordem AS(
SELECT order_id, max(rn) as maximo
FROM ranking
GROUP BY order_id
), titulacao AS (
SELECT order_id,
CASE
WHEN maximo = 1 THEN 'fretes iguais'
ELSE 'fretes diferentes'
END AS modelo
FROM ordem
)
SELECT
SUM(CASE WHEN modelo='fretes iguais' THEN 1 ELSE 0 END) AS pedidos_com_fretes_iguais,
SUM(CASE WHEN modelo='fretes diferentes' THEN 1 ELSE 0 END) AS pedidos_com_fretes_diferentes
FROM titulacao;


-- Foram identificados pedidos com múltiplos itens em que freight_value varia entre as linhas.
-- Segundo o dicionário de dados da Olist (Seção 'Data Card' do dataset), freight_value representa o frete atribuído a cada item. Em pedidos com múltiplos itens, o
-- frete é dividido entre eles. Por isso, o frete total do pedido
-- é calculado com SUM(freight_value) por order_id.
-- Assim, freight_value não foi interpretado como um único valor de frete do pedido repetido em todas as linhas. 
-- Nas análises por pedido, o frete total foi calculado pela soma de freight_value das linhas de cada order_id (SUM).
