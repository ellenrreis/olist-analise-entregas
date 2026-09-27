-- Projeto: Análise dos Drivers do Frete e da Experiência do Cliente (Olist)
-- Arquivo: Insights de Negócios
-- Objetivo: Avaliar a relação entre o frete total do pedido
-- e a experiência do cliente, além de características associadas
-- a pedidos com fretes mais elevados.
-- SGBD: PostgreSQL

-- 1. Relação entre faixas de frete e avaliação do cliente

-- a. visualização de pedidos não avaliados por status
			SELECT pedidos.order_status, COUNT(*)  
			FROM vw_frete as frete
			LEFT JOIN order_reviews_dataset as avaliacoes
			ON frete.order_id = avaliacoes.order_id
			LEFT JOIN orders as pedidos
			ON frete.order_id = pedidos.order_id
			WHERE avaliacoes.review_score IS NULL
			GROUP BY pedidos.order_status;
		
-- b. Quantidade de pedidos avaliados por status
SELECT
pedidos.order_status,
COUNT(DISTINCT frete.order_id) AS qtd_pedidos_avaliados
FROM vw_frete AS frete
JOIN order_reviews_dataset AS avaliacoes
ON frete.order_id = avaliacoes.order_id
JOIN orders AS pedidos
ON frete.order_id = pedidos.order_id
WHERE avaliacoes.review_score IS NOT NULL
GROUP BY pedidos.order_status;

-- c. Nota dos pedidos por decil de frete
WITH nota_por_pedido AS (
SELECT
order_id,
AVG(review_score) AS nota
FROM order_reviews_dataset
WHERE review_score IS NOT NULL
GROUP BY order_id
)
SELECT
    frete.decil,
    ROUND(AVG(avaliacoes.nota), 2) AS nota_media,
    ROUND(STDDEV_POP(avaliacoes.nota), 2) AS desvio_nota,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avaliacoes.nota)
    AS mediana_nota
FROM vw_frete AS frete
LEFT JOIN nota_por_pedido AS avaliacoes
    ON frete.order_id = avaliacoes.order_id
GROUP BY frete.decil
ORDER BY frete.decil;

-- d. Correlação entre frete total e nota do pedido
WITH nota_por_pedido AS (
SELECT
order_id,AVG(review_score) AS nota
    FROM order_reviews_dataset
    WHERE review_score IS NOT NULL
    GROUP BY order_id
)
SELECT
    ROUND(CORR(frete.frete, avaliacoes.nota)::NUMERIC, 3)
        AS corr_frete_nota
FROM vw_frete AS frete
JOIN nota_por_pedido AS avaliacoes
    ON frete.order_id = avaliacoes.order_id;

-- 2. Relação entre faixas de frete e tempo de entrega
	WITH tempo_entrega_unit AS
	(SELECT pedidos.order_id as pedido,frete.decil as decil, 
	(pedidos.order_delivered_customer_date::DATE)-(pedidos.order_approved_at::DATE)
	as tempo_entrega
	FROM vw_frete as frete
	LEFT JOIN orders as pedidos
	ON frete.order_id = pedidos.order_id
	WHERE pedidos.order_status = 'delivered')
	SELECT decil,ROUND(AVG(tempo_entrega),2) as tempo_medio_entrega,
	PERCENTILE_CONT(0.5)WITHIN GROUP(ORDER BY tempo_entrega) as mediana_tempo,
	ROUND(STDDEV_POP(tempo_entrega),2) as desvio_tempo
	FROM tempo_entrega_unit
	GROUP BY decil
	ORDER BY decil;

	-- Correlação entre frete e tempo de entrega
	WITH tempo_entrega_unit AS(
	SELECT frete.decil, frete.frete,
	(pedidos.order_delivered_customer_date::DATE) - (pedidos.order_approved_at::DATE) AS tempo_entrega
	FROM vw_frete AS frete
	LEFT JOIN orders AS pedidos
	ON frete.order_id = pedidos.order_id
	WHERE pedidos.order_status = 'delivered'
	)
	SELECT ROUND(CORR(frete, tempo_entrega)::NUMERIC, 3) AS corr_frete_tempo
	FROM tempo_entrega_unit;

-- 3. Relação entre faixas de frete e atraso na entrega
	WITH datas AS (
	SELECT decil,
	CASE 
	WHEN order_delivered_customer_date::DATE >
	     order_estimated_delivery_date::DATE
	THEN order_delivered_customer_date::DATE 
	     - order_estimated_delivery_date::DATE
	ELSE 0
	END AS dias_atraso,
	CASE 
	WHEN order_estimated_delivery_date::DATE < order_delivered_customer_date::DATE
	THEN 1 ELSE 0 END AS atraso
	FROM vw_frete as frete 
	LEFT JOIN orders as pedidos
	ON frete.order_id = pedidos.order_id
	WHERE pedidos.order_status = 'delivered'
		  AND pedidos.order_delivered_customer_date IS NOT NULL
          AND pedidos.order_estimated_delivery_date IS NOT NULL)
	SELECT decil, SUM(atraso) as atrasos, 
	ROUND(AVG(atraso)::NUMERIC * 100,2) as percentual_atraso,
	ROUND(AVG(dias_atraso),2) AS media_dias_atraso,
	PERCENTILE_CONT(0.5)WITHIN GROUP(ORDER BY dias_atraso) as mediana_dias_atraso
	FROM datas
	GROUP BY decil
	ORDER BY decil;
	
		--Correlação entre frete e atraso (dias)
		WITH frete_atraso AS(
		SELECT frete.order_id, frete.frete,
		CASE 
		WHEN pedidos.order_delivered_customer_date::DATE > pedidos.order_estimated_delivery_date::DATE
		THEN pedidos.order_delivered_customer_date::DATE - pedidos.order_estimated_delivery_date::DATE
		ELSE 0
		END AS dias_atraso
		FROM vw_frete AS frete
		LEFT JOIN orders AS pedidos ON frete.order_id = pedidos.order_id
		WHERE pedidos.order_status = 'delivered'
			AND pedidos.order_delivered_customer_date IS NOT NULL
            AND pedidos.order_estimated_delivery_date IS NOT NULL)
		SELECT ROUND(CORR(frete,dias_atraso)::NUMERIC,3)
		FROM frete_atraso;

-- A associação linear entre o valor total do frete e a nota do pedido foi fraca (-0,089).
-- A seguir, investigam-se características dos pedidos com valores de frete mais elevados.

-- 4. Participação dos itens de cada categoria por decil de frete do pedido
	WITH tab1 AS(
	SELECT 
		frete.decil,
		produtos.product_category_name as cat_prod,
		COUNT (*) as qtd_prod
	FROM vw_frete as frete
	LEFT JOIN order_items as itens
	ON frete.order_id =  itens.order_id
	LEFT JOIN products as produtos
	ON itens.product_id = produtos.product_id 
	GROUP BY frete.decil, produtos.product_category_name
	), 
	ranking AS(
	SELECT decil,cat_prod, ROUND (100.0* qtd_prod/ SUM (qtd_prod) OVER (PARTITION BY decil),2) as porcent_cat,
	ROW_NUMBER () OVER (PARTITION BY decil ORDER BY qtd_prod DESC) as rn FROM tab1)
	SELECT * FROM ranking WHERE rn<=5;

-- 5. Concentração de Vendedores por Decil
-- Cada pedido pode aparecer para mais de um vendedor.
-- O percentual usa como denominador as associações pedido-vendedor do decil
			--a. Avaliando possibilidade de redução do código dos vendedores
			SELECT LEFT (seller_id, 6) AS vendedor_prefixo, COUNT (DISTINCT seller_id) as conta
			FROM order_items
			GROUP BY LEFT (seller_id, 6)
			ORDER BY conta DESC;
		
	-- Definindo concentração:
	WITH qtd_vendor AS (
	SELECT frete.decil as decil, LEFT(itens.seller_id,6) as vendedor,
	COUNT(DISTINCT frete.order_id) as qtd_decil
	FROM vw_frete as frete
	LEFT JOIN order_items as itens
	ON frete.order_id = itens.order_id
	GROUP BY frete.decil, LEFT(itens.seller_id,6)
	), porcentagens AS(
	SELECT * ,
	ROUND(100.0*qtd_decil/SUM(qtd_decil) OVER (PARTITION BY decil),2) as porcent_vendedor,
	row_number () OVER (PARTITION BY decil ORDER BY qtd_decil DESC) as rn
	FROM qtd_vendor)
	SELECT * 
	FROM porcentagens
	WHERE rn <=5;

-- 6. Investigação do peso do produto como driver do frete
-- O peso está ausente em 18 linhas de itens (16 pedidos).
-- As análises de peso consideram apenas os valores disponíveis.
	--a. Correlação
	WITH peso_pedido AS (
	SELECT  oi.order_id,
	SUM(p.product_weight_g) AS peso_total,
	SUM(oi.freight_value) AS frete
	FROM order_items oi
	JOIN products p
	ON oi.product_id = p.product_id
	GROUP BY oi.order_id)
	SELECT ROUND(CORR(peso_total, frete)::NUMERIC, 3) AS corr_peso_frete
	FROM peso_pedido;

	-- Correlação entre peso total e frete total do pedido: 0,639.
	-- A relação positiva é explorada por decis de peso abaixo

	WITH frete_peso AS (
    SELECT
    fretes.order_id,
    SUM(produtos.product_weight_g) AS peso_total,
    fretes.frete
    FROM vw_frete AS fretes
    JOIN order_items AS itens
    ON fretes.order_id = itens.order_id
    JOIN products AS produtos
    ON itens.product_id = produtos.product_id
    GROUP BY fretes.order_id, fretes.frete),
	decis AS (
    SELECT *,
    NTILE(10) OVER (ORDER BY peso_total) AS decil_peso
    FROM frete_peso)
	SELECT decil_peso,
    ROUND(AVG(frete),2) AS frete_medio,
    ROUND(STDDEV(frete),2) AS desvio_frete
	FROM decis
	GROUP BY decil_peso
	ORDER BY decil_peso;
