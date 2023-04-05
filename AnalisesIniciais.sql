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

	-- Calculando os medias de cada etapa na entrega retirando os 10% dos pedidos mais demorados
SELECT provider, region, avg(tempopartidacentralMinutos) AS Etapa1Minutos, AVG(tempoChegadaLocalMinutos) AS Etapa2Minutos,
AVG(tempoLiberacaoEntregaMinutos) AS Etapa3Minutos, AVG(tempoEntregaMinutos) AS Etapa4Minutos, AVG(tempoTotalEntregaDias) AS TotalDias
 FROM entregas WHERE id NOT IN (SELECT id FROM cicloentrega90) 
GROUP BY region, provider;