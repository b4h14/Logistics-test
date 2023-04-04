CREATE SCHEMA Logisticas;
USE Logisticas;

-- Criando tabela com as variáveis identificadas
	CREATE TABLE `entregas` ( 
  `id` INT(6) NOT NULL, 
  `status` VARCHAR(10) NULL, 
  `provider` VARCHAR(10) NULL, 
  `state` VARCHAR(2) NULL, 
  `city` VARCHAR(35) NULL, 
  `sales_order_created_at` DATETIME NULL, 
  `device_order_created_at` DATETIME NULL, 
  `processing_at` DATETIME NULL, 
  `in_transit_to_local_distribution_at` DATETIME NULL, 
  `local_distribution_at` DATETIME NULL, 
  `in_transit_to_deliver_at` DATETIME NULL, 
  `delivered_at` DATETIME NULL, 
  `delivery_estimate_date` DATE NULL, 
  `supply_name` VARCHAR(20) NULL, 
  `shipment_cost` FLOAT NULL, 
  PRIMARY KEY (`id`)); 

-- Fazendo a leitura do arquivo CSV localizado dentro do servidor local
	-- Para facilitar a leitura pelo MySQL, fiz uma transformacao dos dados no pandas
		-- Apliquei o comando fillna() pra preencher todos os campos nulos com NULL
		
	LOAD DATA INFILE 'C:\\Users\\Paulo\\Desktop\\CaseMariaDB\\logistic-case-v4-1.csv'
	INTO TABLE entregas CHARACTER SET utf8mb3
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n'
	IGNORE 1 ROWS; 

-- Criando uma coluna para visualizar estes dados por regiao administrativa
alter table entregas 
add column region 
varchar(12) after state;

update entregas set region = 
	CASE 
		WHEN state in ('SP', 'ES', 'MG', 'RJ') THEN 'Sudeste'
        WHEN state in ('RS', 'SC', 'PR') THEN 'Sul'
        WHEN state in ('DF', 'GO', 'MT', 'MS') THEN 'CentroOeste'
        WHEN state in ('AC', 'AM', 'AP', 'PA', 'RO', 'RR', 'TO') THEN 'Norte'
        ELSE 'Nordeste'
	END;
	
	-- Criando colunas para calcular o tempo de cada etapa
	-- Tempo de efetivacao do pedido
alter table entregas
add column tempoFinalizacaoVendaMinutos int after sales_order_created_at;

update entregas set tempoFinalizacaoVendaMinutos = timestampdiff(minute, sales_order_created_at, device_order_created_at);

	-- Tempo de processamento do pedido
alter table entregas
add column tempoProcessamentoMinutos int after device_order_created_at;

UPDATE entregas SET tempoProcessamentoMinutos = TIMESTAMPDIFF(MINUTE, device_order_created_at, processing_at);


	-- Tempo de saída do distribuidor central
alter table entregas
add column tempoPartidaCentralMinutos int after processing_at;

update entregas set tempoPartidaCentralMinutos = TIMESTAMPDIFF(MINUTE, processing_at,in_transit_to_local_distribution_at);

	-- Tempo de chegada no distribuidor local
alter table entregas
add column tempoChegadaLocalMinutos int after in_transit_to_local_distribution_at;

update entregas set tempoChegadaLocalMinutos = timestampdiff(MINUTE, in_transit_to_local_distribution_at, local_distribution_at);

	-- Tempo de saída para entrega
alter table entregas
add column tempoLiberacaoEntregaMinutos int after local_distribution_at;

update entregas set tempoLiberacaoEntregaMinutos = timestampdiff(MINUTE, local_distribution_at, in_transit_to_deliver_at);

	-- Tempo de entrega
alter table entregas
add column tempoEntregaMinutos int after in_transit_to_deliver_at;

update entregas set tempoEntregaMinutos = timestampdiff(MINUTE, in_transit_to_deliver_at, delivered_at);

-- Classificando as entregas como Em dia ou Atrasado
alter table entregas
add column statusEntrega varchar(10) after delivery_estimate_date;

update entregas set statusEntrega = CASE
 WHEN datediff(delivered_at, delivery_estimate_date) > 0 THEN "Atrasado"
 ELSE "EmDia"
 END;
 
 SELECT statusEntrega as statusEntrega, count(statusEntrega) as quantidade from entregas group by statusEntrega order by count(statusEntrega) DESC;
