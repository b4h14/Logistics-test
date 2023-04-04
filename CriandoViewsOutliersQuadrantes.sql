	-- Criando uma view com os outliers do ciclo de processamento (sales_order_created_at -> processing_at)
		--Calculando Outliers = 'Quadrante 3 + 1,5 * Intervalo Interquartil' 

CREATE VIEW outliersCicloProcessamento as
SELECT * FROM entregas WHERE tempoFinalizacaoVendaMinutos > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoFinalizacaoVendaMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) + 
1.5 * (select unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoFinalizacaoVendaMinutos) OVER (PARTITION BY pedidoPronto)  FROM entregas) - 
(select unique PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoFinalizacaoVendaMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas)
OR tempoProcessamentoMinutos > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoProcessamentoMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) + 
1.5 * (select unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoProcessamentoMinutos) OVER (PARTITION BY pedidoPronto)  FROM entregas) - 
(select unique PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoProcessamentoMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) ORDER BY tempoFinalizacaoVendaMinutos;

	-- Criando uma view com os outliers do ciclo de entrega (processing_at -> delivered_at)
	
CREATE VIEW outliersCicloEntrega as
SELECT * FROM entregas WHERE tempoPartidaCentralMinutos > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoPartidaCentralMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) + 
1.5 * (select unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoPartidaCentralMinutos) OVER (PARTITION BY pedidoPronto)  FROM entregas) - 
(select unique PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoPartidaCentralMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas)
OR tempoChegadaLocalMinutos > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoChegadaLocalMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) + 
1.5 * (select unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoChegadaLocalMinutos) OVER (PARTITION BY pedidoPronto)  FROM entregas) - 
(select unique PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoChegadaLocalMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas)
OR tempoLiberacaoEntregaMinutos > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoLiberacaoEntregaMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) + 
1.5 * (select unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoLiberacaoEntregaMinutos) OVER (PARTITION BY pedidoPronto)  FROM entregas) - 
(select unique PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoLiberacaoEntregaMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas)
OR tempoEntregaMinutos > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoEntregaMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) + 
1.5 * (select unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tempoEntregaMinutos) OVER (PARTITION BY pedidoPronto)  FROM entregas) - 
(select unique PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tempoEntregaMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas);

CREATE VIEW outliersShipmentCost AS
SELECT * FROM entregas WHERE Shipment_cost > 
(SELECT unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Shipment_cost) OVER (PARTITION BY pedidoPronto) FROM entregas) + 
1.5 * (select unique PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Shipment_cost) OVER (PARTITION BY pedidoPronto)  FROM entregas) - 
(select unique PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Shipment_cost) OVER (PARTITION BY pedidoPronto) FROM entregas) ORDER BY shipment_cost;

	-- Criando uma View com as 10% dos valores mais altos para criar estatísticas sem os números excessivos
		-- Selecionando só os 90% dos valores mais baixos

CREATE VIEW cicloProcessamento90 AS
SELECT * FROM entregas WHERE tempoFinalizacaoVendaMinutos > 
(SELECT unique PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY tempoFinalizacaoVendaMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas)
OR tempoProcessamentoMinutos > 
(SELECT unique PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY tempoProcessamentoMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) ORDER BY tempoFinalizacaoVendaMinutos;

	-- Ciclo de Entrega
CREATE VIEW cicloEntrega90 AS
SELECT * FROM entregas WHERE tempoPartidaCentralMinutos > 
(SELECT unique PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY tempoPartidaCentralMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas)
OR tempoChegadaLocalMinutos > 
(SELECT unique PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY tempoChegadaLocalMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas) 
OR tempoLiberacaoEntregaMinutos > 
(SELECT unique PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY tempoLiberacaoEntregaMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas)
OR tempoEntregaMinutos > 
(SELECT unique PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY tempoEntregaMinutos) OVER (PARTITION BY pedidoPronto) FROM entregas)ORDER BY tempoFinalizacaoVendaMinutos;

	-- Envios 10% mais caros
CREATE VIEW ShipmentCost90 AS
SELECT * FROM entregas WHERE shipment_cost > 
(SELECT unique PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY shipment_cost) OVER (PARTITION BY pedidoPronto) FROM entregas) ORDER BY shipment_cost;
;
;
;
;
;
;