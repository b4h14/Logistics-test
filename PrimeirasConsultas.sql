-- Fazendo as primeiras categorizacoes para obter mais dados
	-- Status dos pedidos
SELECT status, count(status) as pedidos from entregas group by status;

	-- Pedidos por transportadora
SELECT provider as transportadora, count(provider) as quantidadePedidos from entregas group by provider;

	-- Pedidos por estado
SELECT state as estado, count(state) as pedidosEstado from entregas group by state order by count(state) DESC;

	-- Pedidos por produto
SELECT supply_name as Produto, count(supply_name) as nomeProduto from entregas group by supply_name order by count(supply_name) DESC;

	-- Pedidos por regiao
SELECT region as regiao, count(region) as quantidadePorRegiao from entregas group by region order by count(region) DESC;
	
	-- Pedidos por situacao de entrega
SELECT statusEntrega as statusEntrega, count(statusEntrega) as quantidadePorRegiao from entregas group by statusEntrega order by count(statusEntrega) DESC;
    
    -- Status dos pedidos por regiao e por transportadora
SELECT status, count(status), region, provider as pedidos from entregas group by status, region, provider order by status;

	-- Porcentagem dos pedidos entregues por regiao e por transportadora
SELECT region, provider, 
count(*) as pedidosTotais,
sum(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) as pedidosEntregues,
(sum(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END)/count(*) * 100) as porcentagemPedidosEntregues
from entregas group by region, provider order by region;

	-- Média dos ciclos de logística e custo de entrega por regiao e por transportadora
select region, provider , avg(ordercreationtimeminutes), avg(processingtimeminutes), avg(leavingcentraldistributionminutes), avg(arrivalLocalDistributionMinutes), 
avg(departureLocalDistributionMinutes), avg(deliveryTimeMinutes), avg(shipment_cost)
 from entregas group by region, provider order by region;

	-- Ao fazer a consulta de pedidos cancelados por transportadora, é possível ver que só há pedidos cancelados na transportadora 2
select count(*), provider from entregas where status = 'cancelled' group by provider;

	-- Rastreio dos 2 pedidos infiniteblack s920
select * from entregas where city = 'Goiás' or city = 'Paraguaçu' order by sales_order_created_at;
select * from entregas where supply_name != 'infiniteblack p2';

	-- Para criar as medidas de medianas e quadrantes, criei uma coluna para fazer a PARTITION em uma categoria única
	alter table entregas
add column pedidoPronto int after shipment_cost;
update entregas set pedidoPronto = 1;

 -- Preenchimento de prazos totais
 	-- Fiz uma iteracao procurando as colunas com valores nulos e calculando o intervalo dos valores exatos

SELECT * FROM entregas WHERE local_distribution_at IS NOT NULL AND tempoLiberacaoEntregaMinutos IS null;

SELECT * FROM entregas WHERE tempoChegadaLocalMinutos IS NULL AND in_transit_to_local_distribution_at IS NOT NULL;

UPDATE entregas SET tempoLiberacaoEntregaMinutos = (TIMESTAMPDIFF(MINUTE, local_distribution_at , delivered_at)) WHERE local_distribution_at IS NOT NULL AND tempoLiberacaoEntregaMinutos IS NULL;

	-- Calculando o total do ciclo de entrega em dias
UPDATE entregas SET tempoTotalEntregaDias = (COALESCE(tempoPartidaCentralMinutos, 0) + COALESCE(tempoChegadaLocalMinutos, 0) + 
COALESCE(tempoLiberacaoEntregaMinutos, 0) + COALESCE(tempoEntregaMinutos, 0)) / 1440;

	-- Calculando mediana e outras medidas estatísticas de uma coluna por regiao
		-- Substituir shipment_cost pelo nome da coluna
	
SELECT UNIQUE region, PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY CustoEnvioDiario) OVER (PARTITION BY region) AS 'PrimeiroQuadrante',
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CustoEnvioDiario) OVER (PARTITION BY region) AS 'Mediana',
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY CustoEnvioDiario) OVER (PARTITION BY region) AS 'TerceiroQuadrante',
(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY CustoEnvioDiario) OVER (PARTITION BY region)) - 
(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY CustoEnvioDiario) OVER (PARTITION BY region)) AS 'Intervalo Interquartil',
(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY CustoEnvioDiario) OVER (PARTITION BY region)) + 
1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY CustoEnvioDiario) OVER (PARTITION BY region)) - 
(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY CustoEnvioDiario) OVER (PARTITION BY region)) AS 'Limite dos Outliers'
FROM entregas;

	-- Identificando outliers de uma coluna por regiao
		-- Substituir shipment_cost pelo nome da coluna

SELECT * FROM entregas WHERE region = 'sudeste' and shipment_cost > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY shipment_cost) OVER (PARTITION BY region) FROM entregas WHERE region = 'sudeste') + 
1.5 * (select unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY shipment_cost) OVER (PARTITION BY region)  FROM entregas WHERE region = 'sudeste') - 
(select unique PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY shipment_cost) OVER (PARTITION BY region) FROM entregas WHERE region = 'sudeste') ORDER BY shipment_cost;

	-- Identificando percentual de uma categoria em relacao ao todo no quarto quadrante

SELECT (SELECT COUNT(*) FROM entregas WHERE region = 'sudeste'  AND state = 'RJ' and shipment_cost > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY shipment_cost) OVER (PARTITION BY region) FROM entregas WHERE region = 'sudeste'))
/ (Select COUNT(*) FROM entregas WHERE region = 'sudeste' and shipment_cost > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY shipment_cost) OVER (PARTITION BY region) FROM entregas WHERE region = 'sudeste')) * 100
AS '% outliers no RJ / outliers Sudeste shipment_cost';

	-- Criando coluna definindo a meta de 3 dias

ALTER TABLE entregas ADD Meta3Dias VARCHAR(50);

UPDATE entregas SET Meta3Dias = 
  CASE
    WHEN delivered_at IS NULL or STATUS != 'delivered' THEN 'EntregaNaoFinalizada'
    WHEN tempoTotalEntregaDias <= 3 AND delivered_at IS NOT NULL THEN 'DentroMeta3Dias'
    ELSE 'AcimaMeta3Dias'
  END;

	--   
ALTER TABLE entregas ADD COLUMN CustoEnvioDiario float;
UPDATE entregas SET CustoEnviodiario = shipment_cost /  tempoTotalEntregaDias WHERE tempoTotalEntregaDias != 0;
  
  -- % das entregas em menos de 3 dias
  
SELECT (select COUNT(*) from entregas WHERE Meta3Dias = 'DentroMeta3Dias') / (select COUNT(*) FROM entregas) * 100;

	-- Visualizando medianas do tempo total de entrega por regiao separado por provider
	
SELECT UNIQUE region, PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region) AS 'PrimeiroQuadrante',
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region) AS 'Mediana',
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region) AS 'TerceiroQuadrante',
(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) - 
(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) AS 'Intervalo Interquartil',
(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) + 
1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) - 
(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) AS 'Limite dos Outliers'
FROM entregas WHERE provider = 'provider 1';

SELECT UNIQUE region, PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region) AS 'PrimeiroQuadrante',
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region) AS 'Mediana',
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region) AS 'TerceiroQuadrante',
(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) - 
(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) AS 'Intervalo Interquartil',
(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) + 
1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) - 
(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoTotalEntregaDias) OVER (PARTITION BY region)) AS 'Limite dos Outliers'
FROM entregas WHERE provider = 'provider 2';

SELECT COUNT(*), provider FROM entregas GROUP BY provider;