-- =========================================================
-- PROJETO: E-commerce Sales Analytics
-- ARQUIVO: analise_ecommerce.sql
-- OBJETIVO: Realizar análises de negócio utilizando SQL
-- BANCO: SQLite (criado no notebook 01_etl.ipynb)
--
-- CRITÉRIO DE PRAZO: a data estimada de entrega não tem horário
-- (sempre 00:00). Por isso, o pedido é considerado "No Prazo"
-- quando a DATA de entrega é menor ou igual à DATA estimada,
-- comparando apenas o dia, sem a hora: DATE(entrega) <= DATE(estimada).
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
-- Observação: apenas estados com pelo menos 500 pedidos,
-- para evitar que estados com poucos pedidos distorçam o ranking.
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
HAVING COUNT(DISTINCT o.order_id) >= 500
ORDER BY ticket_medio DESC;


-- =========================================================
-- 8. TOP 10 CATEGORIAS POR FATURAMENTO
-- Objetivo: identificar as categorias de produtos que
-- geraram maior faturamento no período analisado.
-- Observação: considera o preço dos itens (sem frete).
-- =========================================================

SELECT
    pr.product_category_name AS categoria,
    ROUND(SUM(i.price), 2) AS faturamento_total
FROM olist_order_items AS i
INNER JOIN olist_products AS pr
    ON i.product_id = pr.product_id
WHERE pr.product_category_name IS NOT NULL
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
WHERE pr.product_category_name IS NOT NULL
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
        WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date)
            THEN 'No Prazo'
        ELSE 'Atrasada'
    END AS status_entrega,

    COUNT(r.review_score) AS quantidade_avaliacoes,

    ROUND(AVG(r.review_score), 2) AS nota_media,

    ROUND(
        100.0 * SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) / COUNT(r.review_score),
        2
    ) AS percentual_nota_1

FROM olist_orders AS o

INNER JOIN olist_order_reviews AS r
    ON o.order_id = r.order_id

WHERE
    o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
    AND r.review_score IS NOT NULL

GROUP BY status_entrega

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
                WHEN DATE(order_delivered_customer_date) <= DATE(order_estimated_delivery_date)
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
    COUNT(*) AS pedidos_atrasados,

    ROUND(
        AVG(
            JULIANDAY(DATE(order_delivered_customer_date)) -
            JULIANDAY(DATE(order_estimated_delivery_date))
        ),
        2
    ) AS atraso_medio_dias

FROM olist_orders

WHERE
    order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
    AND DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date);


-- =========================================================
-- 13. EVOLUÇÃO MENSAL DO FATURAMENTO
-- Objetivo: analisar a evolução do faturamento ao longo
-- dos meses do período analisado.
-- Observação: considera de jan/2017 a ago/2018. Os meses de 2016
-- e set/out de 2018 têm poucos pedidos na base e criariam
-- quedas artificiais.
-- =========================================================

SELECT
    STRFTIME('%Y-%m', o.order_purchase_timestamp) AS periodo,

    COUNT(DISTINCT o.order_id) AS quantidade_pedidos,

    ROUND(SUM(p.payment_value), 2) AS faturamento_total

FROM olist_orders AS o

INNER JOIN olist_order_payments AS p
    ON o.order_id = p.order_id

WHERE
    STRFTIME('%Y-%m', o.order_purchase_timestamp) BETWEEN '2017-01' AND '2018-08'

GROUP BY periodo

ORDER BY periodo;


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
-- e o valor médio das transações, agrupado nas mesmas
-- faixas usadas no dashboard.
-- =========================================================

SELECT
    CASE
        WHEN payment_installments <= 1 THEN '1x'
        WHEN payment_installments <= 5 THEN '2x a 5x'
        WHEN payment_installments <= 10 THEN '6x a 10x'
        ELSE 'Mais de 10x'
    END AS faixa_parcelas,

    COUNT(*) AS quantidade_transacoes,

    ROUND(
        100.0 * COUNT(*) / (SELECT COUNT(*) FROM olist_order_payments),
        2
    ) AS percentual_transacoes,

    ROUND(AVG(payment_value), 2) AS valor_medio

FROM olist_order_payments

GROUP BY faixa_parcelas

ORDER BY MIN(payment_installments);


-- =========================================================
-- 16. TOP 10 CATEGORIAS POR VALOR MÉDIO DO ITEM
-- Objetivo: identificar as categorias que apresentam
-- maior valor médio por item vendido.
-- Observação: apenas categorias com pelo menos 100 itens
-- vendidos, para evitar médias baseadas em poucas vendas.
-- =========================================================

SELECT
    pr.product_category_name AS categoria,

    COUNT(i.order_item_id) AS quantidade_itens,

    ROUND(AVG(i.price), 2) AS valor_medio_item

FROM olist_order_items AS i

INNER JOIN olist_products AS pr
    ON i.product_id = pr.product_id

WHERE
    pr.product_category_name IS NOT NULL

GROUP BY
    pr.product_category_name

HAVING
    COUNT(i.order_item_id) >= 100

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

GROUP BY classificacao_avaliacao

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

        JULIANDAY(DATE(order_delivered_customer_date)) -
        JULIANDAY(DATE(order_estimated_delivery_date)) AS dias_atraso

    FROM olist_orders

    WHERE
        order_delivered_customer_date IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
        AND DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)
)

SELECT
    CASE
        WHEN dias_atraso <= 3 THEN 'Até 3 dias'
        WHEN dias_atraso <= 7 THEN '4 a 7 dias'
        WHEN dias_atraso <= 14 THEN '8 a 14 dias'
        WHEN dias_atraso <= 30 THEN '15 a 30 dias'
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

GROUP BY faixa_atraso

ORDER BY
    MIN(dias_atraso);


-- =========================================================
-- 20. NOTA MÉDIA POR TEMPO DE ATRASO
-- Objetivo: medir como a satisfação cai à medida que o
-- atraso aumenta (base do gráfico nota_por_atraso.png).
-- =========================================================

WITH entregas AS (
    SELECT
        o.order_id,
        r.review_score,
        JULIANDAY(DATE(o.order_delivered_customer_date)) -
        JULIANDAY(DATE(o.order_estimated_delivery_date)) AS dias_atraso
    FROM olist_orders AS o
    INNER JOIN olist_order_reviews AS r
        ON o.order_id = r.order_id
    WHERE
        o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
    CASE
        WHEN dias_atraso <= 0 THEN '0. No prazo'
        WHEN dias_atraso <= 3 THEN '1. Até 3 dias'
        WHEN dias_atraso <= 7 THEN '2. 4 a 7 dias'
        WHEN dias_atraso <= 14 THEN '3. 8 a 14 dias'
        ELSE '4. 15 dias ou mais'
    END AS faixa_atraso,

    COUNT(*) AS quantidade_avaliacoes,

    ROUND(AVG(review_score), 2) AS nota_media

FROM entregas

GROUP BY faixa_atraso

ORDER BY faixa_atraso;


-- =========================================================
-- 21. PERCENTUAL DE PEDIDOS ATRASADOS POR ESTADO
-- Objetivo: identificar os estados com maior taxa de atraso.
-- Observação: apenas estados com mais de 500 pedidos entregues.
-- =========================================================

SELECT
    c.customer_state AS estado,

    COUNT(*) AS pedidos_entregues,

    SUM(
        CASE
            WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
                THEN 1
            ELSE 0
        END
    ) AS pedidos_atrasados,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS percentual_atraso

FROM olist_orders AS o

INNER JOIN olist_customers AS c
    ON o.customer_id = c.customer_id

WHERE
    o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY c.customer_state

HAVING COUNT(*) > 500

ORDER BY percentual_atraso DESC;


-- =========================================================
-- 22. PARTICIPAÇÃO DE CADA ESTADO NO FATURAMENTO
-- Objetivo: calcular o percentual do faturamento total
-- de cada estado e o percentual acumulado (window functions).
-- =========================================================

WITH faturamento_estado AS (
    SELECT
        c.customer_state AS estado,
        SUM(p.payment_value) AS faturamento
    FROM olist_orders AS o
    INNER JOIN olist_customers AS c
        ON o.customer_id = c.customer_id
    INNER JOIN olist_order_payments AS p
        ON o.order_id = p.order_id
    GROUP BY c.customer_state
)

SELECT
    estado,

    ROUND(faturamento, 2) AS faturamento,

    ROUND(
        100.0 * faturamento / SUM(faturamento) OVER (),
        2
    ) AS participacao_percentual,

    ROUND(
        100.0 * SUM(faturamento) OVER (ORDER BY faturamento DESC)
        / SUM(faturamento) OVER (),
        2
    ) AS participacao_acumulada

FROM faturamento_estado

ORDER BY faturamento DESC;


-- =========================================================
-- 23. CRESCIMENTO MENSAL DO FATURAMENTO
-- Objetivo: calcular a variação percentual do faturamento
-- em relação ao mês anterior (window function LAG).
-- =========================================================

WITH faturamento_mensal AS (
    SELECT
        STRFTIME('%Y-%m', o.order_purchase_timestamp) AS periodo,
        SUM(p.payment_value) AS faturamento
    FROM olist_orders AS o
    INNER JOIN olist_order_payments AS p
        ON o.order_id = p.order_id
    WHERE
        STRFTIME('%Y-%m', o.order_purchase_timestamp) BETWEEN '2017-01' AND '2018-08'
    GROUP BY periodo
)

SELECT
    periodo,

    ROUND(faturamento, 2) AS faturamento,

    ROUND(LAG(faturamento) OVER (ORDER BY periodo), 2) AS faturamento_mes_anterior,

    ROUND(
        100.0 * (faturamento - LAG(faturamento) OVER (ORDER BY periodo))
        / LAG(faturamento) OVER (ORDER BY periodo),
        2
    ) AS variacao_percentual

FROM faturamento_mensal

ORDER BY periodo;


-- =========================================================
-- 24. CATEGORIA MAIS VENDIDA EM CADA ESTADO
-- Objetivo: identificar a categoria líder em faturamento
-- em cada estado (window function ROW_NUMBER).
-- =========================================================

WITH vendas_estado_categoria AS (
    SELECT
        c.customer_state AS estado,
        pr.product_category_name AS categoria,
        SUM(i.price) AS faturamento
    FROM olist_order_items AS i
    INNER JOIN olist_orders AS o
        ON i.order_id = o.order_id
    INNER JOIN olist_customers AS c
        ON o.customer_id = c.customer_id
    INNER JOIN olist_products AS pr
        ON i.product_id = pr.product_id
    WHERE pr.product_category_name IS NOT NULL
    GROUP BY c.customer_state, pr.product_category_name
),

ranking AS (
    SELECT
        estado,
        categoria,
        faturamento,
        ROW_NUMBER() OVER (
            PARTITION BY estado
            ORDER BY faturamento DESC
        ) AS posicao
    FROM vendas_estado_categoria
)

SELECT
    estado,
    categoria AS categoria_lider,
    ROUND(faturamento, 2) AS faturamento
FROM ranking
WHERE posicao = 1
ORDER BY faturamento DESC;


-- =========================================================
-- 25. RESUMO EXECUTIVO DE KPIs
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
                WHEN DATE(order_delivered_customer_date) <= DATE(order_estimated_delivery_date)
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS percentual_entregas_no_prazo,

        AVG(
            CASE
                WHEN DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)
                    THEN JULIANDAY(DATE(order_delivered_customer_date))
                       - JULIANDAY(DATE(order_estimated_delivery_date))
            END
        ) AS atraso_medio_dias
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
    ROUND(avaliacoes_kpi.nota_media_satisfacao, 2) AS nota_media_satisfacao,
    ROUND(entregas_kpi.percentual_entregas_no_prazo, 2) AS percentual_entregas_no_prazo,
    ROUND(entregas_kpi.atraso_medio_dias, 1) AS atraso_medio_dias

FROM pedidos_kpi
CROSS JOIN clientes_kpi
CROSS JOIN pagamentos_kpi
CROSS JOIN avaliacoes_kpi
CROSS JOIN entregas_kpi;


-- =========================================================
-- INVESTIGAÇÃO: POR QUE OS PEDIDOS ATRASAM OU NÃO CHEGAM
-- (detalhada no notebook 03_investigacao_atrasos.ipynb)
-- =========================================================

-- =========================================================
-- 26. PEDIDOS NÃO ENTREGUES POR STATUS
-- Objetivo: entender em que situação estão os pedidos
-- que não chegaram ao cliente.
-- =========================================================

SELECT
    order_status AS status,
    COUNT(*) AS pedidos,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentual
FROM olist_orders
WHERE order_status <> 'delivered'
GROUP BY order_status
ORDER BY pedidos DESC;


-- =========================================================
-- 27. DADOS INCOMPLETOS E INCONSISTENTES NOS PEDIDOS
-- Objetivo: medir a qualidade das datas registradas.
-- =========================================================

SELECT
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS sem_data_entrega,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS sem_data_postagem,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS sem_data_aprovacao,
    SUM(CASE WHEN order_delivered_carrier_date < order_purchase_timestamp THEN 1 ELSE 0 END) AS postado_antes_da_compra,
    SUM(CASE WHEN order_delivered_customer_date < order_delivered_carrier_date THEN 1 ELSE 0 END) AS entregue_antes_de_postado,
    SUM(CASE WHEN order_status = 'delivered' AND order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS entregue_sem_data
FROM olist_orders;


-- =========================================================
-- 28. DURAÇÃO MÉDIA DE CADA ETAPA: NO PRAZO × ATRASADOS
-- Objetivo: identificar em qual etapa o tempo se perde.
-- Observação: o SQLite não tem função de mediana; o notebook 03
-- mostra as medianas, que são menos afetadas por casos extremos.
-- =========================================================

WITH etapas AS (
    SELECT
        CASE
            WHEN DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)
                THEN 'Atrasados'
            ELSE 'No prazo'
        END AS grupo,
        JULIANDAY(order_approved_at) - JULIANDAY(order_purchase_timestamp) AS aprovacao,
        JULIANDAY(order_delivered_carrier_date) - JULIANDAY(order_approved_at) AS postagem,
        JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_delivered_carrier_date) AS transporte
    FROM olist_orders
    WHERE
        order_approved_at IS NOT NULL
        AND order_delivered_carrier_date IS NOT NULL
        AND order_delivered_customer_date IS NOT NULL
)

SELECT
    grupo,
    COUNT(*) AS pedidos,
    ROUND(AVG(aprovacao), 2) AS media_dias_aprovacao,
    ROUND(AVG(postagem), 2) AS media_dias_postagem,
    ROUND(AVG(transporte), 2) AS media_dias_transporte
FROM etapas
WHERE aprovacao >= 0 AND postagem >= 0 AND transporte >= 0
GROUP BY grupo;


-- =========================================================
-- 29. TAXA DE ATRASO QUANDO O VENDEDOR POSTA FORA DO PRAZO
-- Objetivo: medir o peso do vendedor no atraso.
-- =========================================================

WITH limite AS (
    SELECT order_id, MAX(shipping_limit_date) AS limite_postagem
    FROM olist_order_items
    GROUP BY order_id
)

SELECT
    CASE
        WHEN o.order_delivered_carrier_date > l.limite_postagem
            THEN 'Vendedor postou atrasado'
        ELSE 'Vendedor postou no prazo'
    END AS postagem,
    COUNT(*) AS pedidos,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS taxa_de_atraso
FROM olist_orders AS o
INNER JOIN limite AS l
    ON o.order_id = l.order_id
WHERE
    o.order_approved_at IS NOT NULL
    AND o.order_delivered_carrier_date IS NOT NULL
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_approved_at >= o.order_purchase_timestamp
    AND o.order_delivered_carrier_date >= o.order_approved_at
    AND o.order_delivered_customer_date >= o.order_delivered_carrier_date
GROUP BY postagem;


-- =========================================================
-- 30. TAXA DE ATRASO: MESMO ESTADO × OUTRO ESTADO
-- Objetivo: medir o efeito da distância entre vendedor e cliente.
-- Observação: considera o primeiro item de cada pedido.
-- =========================================================

WITH vendedor_pedido AS (
    SELECT i.order_id, s.seller_state
    FROM olist_order_items AS i
    INNER JOIN olist_sellers AS s
        ON i.seller_id = s.seller_id
    WHERE i.order_item_id = 1
)

SELECT
    CASE
        WHEN v.seller_state = c.customer_state THEN 'Mesmo estado'
        ELSE 'Outro estado'
    END AS rota,
    COUNT(*) AS pedidos,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS taxa_de_atraso
FROM olist_orders AS o
INNER JOIN olist_customers AS c
    ON o.customer_id = c.customer_id
INNER JOIN vendedor_pedido AS v
    ON o.order_id = v.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY rota;


-- =========================================================
-- 31. TAXA DE ATRASO POR MÊS DA COMPRA
-- Objetivo: identificar períodos críticos (sazonalidade).
-- =========================================================

SELECT
    STRFTIME('%Y-%m', order_purchase_timestamp) AS periodo,
    COUNT(*) AS pedidos_entregues,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS taxa_de_atraso
FROM olist_orders
WHERE
    order_delivered_customer_date IS NOT NULL
    AND STRFTIME('%Y-%m', order_purchase_timestamp) BETWEEN '2017-01' AND '2018-08'
GROUP BY periodo
ORDER BY taxa_de_atraso DESC;


-- =========================================================
-- 32. PAGAMENTO: TEMPO ATÉ A APROVAÇÃO E CANCELAMENTOS
-- Objetivo: comparar as formas de pagamento.
-- Observação: a base não registra tentativas recusadas nem o
-- motivo da recusa (sem limite, cartão bloqueado, antifraude).
-- Para pedidos com mais de uma forma de pagamento, considera
-- a forma do primeiro pagamento.
-- =========================================================

WITH forma AS (
    SELECT order_id, payment_type
    FROM olist_order_payments
    WHERE payment_sequential = 1
)

SELECT
    f.payment_type AS forma_pagamento,
    COUNT(*) AS pedidos,
    SUM(CASE WHEN o.order_approved_at IS NULL THEN 1 ELSE 0 END) AS sem_aprovacao,
    ROUND(
        AVG((JULIANDAY(o.order_approved_at) - JULIANDAY(o.order_purchase_timestamp)) * 24),
        1
    ) AS media_horas_ate_aprovacao,
    ROUND(
        100.0 * SUM(CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS taxa_cancelamento
FROM olist_orders AS o
INNER JOIN forma AS f
    ON o.order_id = f.order_id
GROUP BY f.payment_type
ORDER BY pedidos DESC;
