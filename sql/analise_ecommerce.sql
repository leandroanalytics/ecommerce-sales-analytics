-- =========================================================
-- PROJETO: E-commerce Sales Analytics
-- ARQUIVO: analise_ecommerce.sql
-- OBJETIVO: Realizar análises de negócio utilizando SQL
-- =========================================================

-- =========================================================
-- 1. TOTAL DE PEDIDOS
-- Objetivo: identificar a quantidade total de pedidos
-- realizados no período analisado.
-- =========================================================

SELECT 
    COUNT(DISTINCT order_id) AS total_pedidos
FROM olist_orders;


-- =========================================================
-- 2. FATURAMENTO TOTAL
-- Objetivo: calcular o valor total movimentado em pagamentos
-- durante o período analisado.
-- =========================================================

SELECT
    SUM(payment_value) AS faturamento_total
FROM olist_order_payments;

-- =========================================================
-- 3. TICKET MÉDIO
-- Objetivo: calcular o valor médio movimentado por pedido
-- durante o período analisado.
-- =========================================================

SELECT
    ROUND(
        SUM(payment_value) / COUNT(DISTINCT order_id),
        2
    ) AS ticket_medio
FROM olist_order_payments;

-- =========================================================
-- 4. QUANTIDADE DE PEDIDOS POR STATUS
-- Objetivo: identificar a distribuição dos pedidos
-- de acordo com o status da entrega.
-- =========================================================

SELECT
    order_status,
    COUNT(DISTINCT order_id) AS quantidade_pedidos
FROM olist_orders
GROUP BY order_status
ORDER BY quantidade_pedidos DESC;




-- =========================================================
-- 5. QUANTIDADE DE PEDIDOS POR ESTADO
-- Objetivo: identificar os estados com maior volume
-- de pedidos realizados.
-- =========================================================

SELECT
    c.customer_state AS estado,
    COUNT(DISTINCT o.order_id) AS quantidade_pedidos
FROM olist_orders AS o
INNER JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY quantidade_pedidos DESC;

-- =========================================================
-- 6. FATURAMENTO POR ESTADO
-- Objetivo: identificar os estados que geraram maior
-- faturamento durante o período analisado.
-- =========================================================

SELECT
    c.customer_state AS estado,
    ROUND(SUM(p.payment_value), 2) AS faturamento_total
FROM olist_orders AS o
INNER JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
INNER JOIN olist_order_payments AS p
    ON o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY faturamento_total DESC;

-- =========================================================
-- 7. TICKET MÉDIO POR ESTADO
-- Objetivo: calcular o valor médio movimentado por pedido
-- em cada estado.
-- =========================================================

SELECT
    c.customer_state AS estado,
    COUNT(DISTINCT o.order_id) AS quantidade_pedidos,
    ROUND(SUM(p.payment_value), 2) AS faturamento_total,
    ROUND(
        SUM(p.payment_value) / COUNT(DISTINCT o.order_id),
        2
    ) AS ticket_medio
FROM olist_orders AS o
INNER JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
INNER JOIN olist_order_payments AS p
    ON o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY ticket_medio DESC;

-- =========================================================
-- 8. TOP 10 CATEGORIAS POR FATURAMENTO
-- Objetivo: identificar as categorias de produtos que
-- geraram maior faturamento no período analisado.
-- =========================================================

SELECT
    pr.product_category_name AS categoria,
    ROUND(SUM(i.price), 2) AS faturamento_total
FROM olist_order_items AS i
INNER JOIN olist_products AS pr
    ON i.product_id = pr.product_id
GROUP BY pr.product_category_name
ORDER BY faturamento_total DESC
LIMIT 10;


-- =========================================================
-- 9. TOP 10 CATEGORIAS POR VOLUME VENDIDO
-- Objetivo: identificar as categorias com maior quantidade
-- de itens vendidos no período analisado.
-- =========================================================

SELECT
    pr.product_category_name AS categoria,
    COUNT(i.order_item_id) AS quantidade_vendida
FROM olist_order_items AS i
INNER JOIN olist_products AS pr
    ON i.product_id = pr.product_id
GROUP BY pr.product_category_name
ORDER BY quantidade_vendida DESC
LIMIT 10;


-- =========================================================
-- 10. NOTA MÉDIA POR STATUS DA ENTREGA
-- Objetivo: comparar a satisfação dos clientes entre
-- pedidos entregues no prazo e pedidos entregues com atraso.
-- =========================================================

SELECT
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 'No Prazo'
        ELSE 'Atrasada'
    END AS status_entrega,

    COUNT(r.review_score) AS quantidade_avaliacoes,

    ROUND(
        AVG(r.review_score),
        2
    ) AS nota_media

FROM olist_orders AS o

INNER JOIN olist_order_reviews AS r
    ON o.order_id = r.order_id

WHERE
    o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
    AND r.review_score IS NOT NULL

GROUP BY
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 'No Prazo'
        ELSE 'Atrasada'
    END

ORDER BY nota_media DESC;

-- =========================================================
-- 11. PERCENTUAL DE ENTREGAS NO PRAZO
-- Objetivo: calcular o percentual de pedidos entregues
-- dentro do prazo previsto.
-- =========================================================

SELECT
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN order_delivered_customer_date <= order_estimated_delivery_date
                    THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS percentual_entregas_no_prazo

FROM olist_orders

WHERE
    order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL;

    -- =========================================================
-- 12. ATRASO MÉDIO EM DIAS
-- Objetivo: calcular a quantidade média de dias de atraso
-- entre os pedidos entregues após a data prevista.
-- =========================================================

SELECT
    ROUND(
        AVG(
            JULIANDAY(order_delivered_customer_date) -
            JULIANDAY(order_estimated_delivery_date)
        ),
        2
    ) AS atraso_medio_dias

FROM olist_orders

WHERE
    order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
    AND order_delivered_customer_date > order_estimated_delivery_date;

    -- =========================================================
-- 13. EVOLUÇÃO MENSAL DO FATURAMENTO
-- Objetivo: analisar a evolução do faturamento ao longo
-- dos meses do período analisado.
-- =========================================================

SELECT
    STRFTIME('%Y-%m', o.order_purchase_timestamp) AS periodo,

    COUNT(DISTINCT o.order_id) AS quantidade_pedidos,

    ROUND(
        SUM(p.payment_value),
        2
    ) AS faturamento_total

FROM olist_orders AS o

INNER JOIN olist_order_payments AS p
    ON o.order_id = p.order_id

WHERE
    o.order_purchase_timestamp IS NOT NULL

GROUP BY
    STRFTIME('%Y-%m', o.order_purchase_timestamp)

ORDER BY
    periodo;

-- =========================================================
-- 14. FORMAS DE PAGAMENTO
-- Objetivo: analisar a utilização dos diferentes meios
-- de pagamento e o valor movimentado por cada modalidade.
-- =========================================================

SELECT
    payment_type AS forma_pagamento,
    COUNT(*) AS quantidade_transacoes,
    ROUND(SUM(payment_value), 2) AS valor_total
FROM olist_order_payments
GROUP BY payment_type
ORDER BY valor_total DESC;

-- =========================================================
-- 15. PARCELAMENTO E TICKET MÉDIO
-- Objetivo: analisar a relação entre o número de parcelas
-- e o valor médio das transações.
-- =========================================================

SELECT
    payment_installments AS numero_parcelas,

    COUNT(*) AS quantidade_transacoes,

    ROUND(
        AVG(payment_value),
        2
    ) AS ticket_medio

FROM olist_order_payments

WHERE
    payment_installments > 0

GROUP BY payment_installments

ORDER BY numero_parcelas;

-- =========================================================
-- 16. TOP 10 CATEGORIAS POR VALOR MÉDIO DO ITEM
-- Objetivo: identificar as categorias que apresentam
-- maior valor médio por item vendido.
-- =========================================================

SELECT
    pr.product_category_name AS categoria,

    COUNT(i.order_item_id) AS quantidade_itens,

    ROUND(
        AVG(i.price),
        2
    ) AS valor_medio_item

FROM olist_order_items AS i

INNER JOIN olist_products AS pr
    ON i.product_id = pr.product_id

WHERE
    pr.product_category_name IS NOT NULL

GROUP BY
    pr.product_category_name

ORDER BY
    valor_medio_item DESC

LIMIT 10;


-- =========================================================
-- 17. DISTRIBUIÇÃO DAS AVALIAÇÕES DOS CLIENTES
-- Objetivo: analisar a quantidade e o percentual de
-- avaliações para cada nota de 1 a 5.
-- =========================================================

SELECT
    review_score AS nota,

    COUNT(*) AS quantidade_avaliacoes,

    ROUND(
        100.0 * COUNT(*) /
        (
            SELECT COUNT(*)
            FROM olist_order_reviews
            WHERE review_score IS NOT NULL
        ),
        2
    ) AS percentual

FROM olist_order_reviews

WHERE
    review_score IS NOT NULL

GROUP BY
    review_score

ORDER BY
    review_score;


-- =========================================================
-- 18. CLASSIFICAÇÃO DAS AVALIAÇÕES DOS CLIENTES
-- Objetivo: classificar as avaliações em positivas,
-- neutras e negativas para facilitar a análise de satisfação.
-- =========================================================

SELECT
    CASE
        WHEN review_score >= 4 THEN 'Positiva'
        WHEN review_score = 3 THEN 'Neutra'
        ELSE 'Negativa'
    END AS classificacao_avaliacao,

    COUNT(*) AS quantidade_avaliacoes,

    ROUND(
        100.0 * COUNT(*) /
        (
            SELECT COUNT(*)
            FROM olist_order_reviews
            WHERE review_score IS NOT NULL
        ),
        2
    ) AS percentual

FROM olist_order_reviews

WHERE
    review_score IS NOT NULL

GROUP BY
    CASE
        WHEN review_score >= 4 THEN 'Positiva'
        WHEN review_score = 3 THEN 'Neutra'
        ELSE 'Negativa'
    END

ORDER BY
    percentual DESC;

    -- =========================================================
-- 19. DISTRIBUIÇÃO DOS ATRASOS POR FAIXA DE DIAS
-- Objetivo: analisar a distribuição dos pedidos atrasados
-- de acordo com a quantidade de dias de atraso.
-- =========================================================

WITH pedidos_atrasados AS (
    SELECT
        order_id,

        JULIANDAY(order_delivered_customer_date) -
        JULIANDAY(order_estimated_delivery_date) AS dias_atraso

    FROM olist_orders

    WHERE
        order_delivered_customer_date IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
        AND order_delivered_customer_date > order_estimated_delivery_date
)

SELECT
    CASE
        WHEN dias_atraso <= 3 THEN 'Até 3 dias'
        WHEN dias_atraso <= 7 THEN '4 a 7 dias'
        WHEN dias_atraso <= 15 THEN '8 a 15 dias'
        WHEN dias_atraso <= 30 THEN '16 a 30 dias'
        ELSE 'Acima de 30 dias'
    END AS faixa_atraso,

    COUNT(*) AS quantidade_pedidos,

    ROUND(
        100.0 * COUNT(*) /
        (
            SELECT COUNT(*)
            FROM pedidos_atrasados
        ),
        2
    ) AS percentual

FROM pedidos_atrasados

GROUP BY
    CASE
        WHEN dias_atraso <= 3 THEN 'Até 3 dias'
        WHEN dias_atraso <= 7 THEN '4 a 7 dias'
        WHEN dias_atraso <= 15 THEN '8 a 15 dias'
        WHEN dias_atraso <= 30 THEN '16 a 30 dias'
        ELSE 'Acima de 30 dias'
    END

ORDER BY
    MIN(dias_atraso);

-- =========================================================
-- 20. RESUMO EXECUTIVO DE KPIs
-- Objetivo: consolidar os principais indicadores
-- do projeto em uma única consulta.
-- =========================================================

WITH
pedidos_kpi AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_pedidos
    FROM olist_orders
),

clientes_kpi AS (
    SELECT
        COUNT(DISTINCT customer_unique_id) AS total_clientes
    FROM olist_customers
),

pagamentos_kpi AS (
    SELECT
        SUM(payment_value) AS faturamento_total
    FROM olist_order_payments
),

avaliacoes_kpi AS (
    SELECT
        AVG(review_score) AS nota_media_satisfacao
    FROM olist_order_reviews
    WHERE review_score IS NOT NULL
),

entregas_kpi AS (
    SELECT
        100.0 *
        SUM(
            CASE
                WHEN order_delivered_customer_date <= order_estimated_delivery_date
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS percentual_entregas_no_prazo
    FROM olist_orders
    WHERE
        order_delivered_customer_date IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    pedidos_kpi.total_pedidos,
    clientes_kpi.total_clientes,
    ROUND(pagamentos_kpi.faturamento_total, 2) AS faturamento_total,
    ROUND(
        pagamentos_kpi.faturamento_total / pedidos_kpi.total_pedidos,
        2
    ) AS ticket_medio,
    ROUND(
        avaliacoes_kpi.nota_media_satisfacao,
        2
    ) AS nota_media_satisfacao,
    ROUND(
        entregas_kpi.percentual_entregas_no_prazo,
        2
    ) AS percentual_entregas_no_prazo

FROM pedidos_kpi
CROSS JOIN clientes_kpi
CROSS JOIN pagamentos_kpi
CROSS JOIN avaliacoes_kpi
CROSS JOIN entregas_kpi;

