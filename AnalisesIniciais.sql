	-- Ao analisar os cálculo somente das 90% das entregas mais rápidas, a transportadora 2 obtém um tempo médio de entrega de 4,4 dias
SELECT AVG(tempoTotalEntregaDias) FROM entregas where id not IN (select id from cicloentrega90) and STATUS = 'delivered' and provider = 'provider 2';

	-- Verificando o % das entregas igual ou menor de 3 dias por provider
SELECT (select count(tempoTotalEntregaDias) FROM entregas WHERE Meta3Dias = 'DentroMeta3Dias' AND provider = 'provider 2') /
(select count(tempoTotalEntregaDias) FROM entregas WHERE provider = 'provider 2') * 100;
SELECT (select count(tempoTotalEntregaDias) FROM entregas WHERE Meta3Dias = 'DentroMeta3Dias' AND provider = 'provider 1') /
(select count(tempoTotalEntregaDias) FROM entregas WHERE provider = 'provider 1') * 100;

		-- Fazendo o cálculo com os 90% pedidos mais baratos
SELECT (select count(tempoTotalEntregaDias) FROM entregas WHERE Meta3Dias = 'DentroMeta3Dias' and provider = 'provider 2' AND id NOT IN (SELECT id FROM cicloentrega90)) /
(select count(tempoTotalEntregaDias) FROM entregas WHERE provider = 'provider 2' AND id NOT IN (SELECT id FROM cicloentrega90)) * 100;
SELECT (select count(tempoTotalEntregaDias) FROM entregas WHERE Meta3Dias = 'DentroMeta3Dias' and provider = 'provider 1' AND id NOT IN (SELECT id FROM cicloentrega90)) /
(select count(tempoTotalEntregaDias) FROM entregas WHERE provider = 'provider 1' AND id NOT IN (SELECT id FROM cicloentrega90)) * 100;	

		-- É possível observar que, excluindo os 10% dos pedidos mais irregulares, a Provider 2 tem 27,74% das entregas abaixo de 3 dias,
		-- enquanto a provider 1 tem 10,95%. Para chegar ao tempo médio de entrega em 3 dias, podemos aumentar os pedidos através do provider 2

	-- Calculando os medias de cada etapa na entrega retirando os 10% dos pedidos mais demorados
SELECT provider, region, avg(tempopartidacentralMinutos) AS Etapa1Minutos, AVG(tempoChegadaLocalMinutos) AS Etapa2Minutos,
AVG(tempoLiberacaoEntregaMinutos) AS Etapa3Minutos, AVG(tempoEntregaMinutos) AS Etapa4Minutos, AVG(tempoTotalEntregaDias) AS TotalDias
 FROM entregas WHERE id NOT IN (SELECT id FROM cicloentrega90) 
GROUP BY region, provider;

		-- Outra alteracao na operacao para diminuir o tempo médio de entrega seria especializar certas etapas na provider que tem o menor
		-- tempo. Embora a provider 2 tenha as melhores médias em geral, as etapas tempopartidacentralMinutos e tempoLiberacaoEntregaMinutos
		-- sejam mais eficientes na provider 1.

	-- Visualizando anomalias
			-- Observando o 1% dos pedidos mais demorados na coluna tempoProcessamentoMinutos, é possível visualizar que tem um grupo
			-- de 22 pedidos que está com tempo acima de 10 dias para processar.
			 
SELECT * FROM entregas WHERE tempoProcessamentoMinutos > (SELECT unique PERCENTILE_CONT(0.99) 
WITHIN GROUP (ORDER BY tempoProcessamentoMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) ORDER BY  tempoProcessamentoMinutos DESC;

	-- Dentre os pedidos com tempoProcessamentoMinutos outliers, podemos analisar que todos foram da provider 2.
		-- Houve 1 pedido da provider 1, mas foi devolvida.
SELECT provider, region, STATUS, COUNT(*) FROM entregas WHERE tempoProcessamentoMinutos > 12000 
GROUP BY provider, region, status ORDER BY tempoProcessamentoMinutos DESC ;