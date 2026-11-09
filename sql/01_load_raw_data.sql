-- =====================================================================
-- 01 - Chargement des CSV dans les tables brutes
-- Attention : les fichiers ont des fins de ligne Windows (\r\n).
-- Avec '\n' seul, la dernière colonne garderait un '\r' invisible.
-- Lancer depuis la racine du dépôt : mysql --local-infile=1 ...
-- =====================================================================

USE produits_frais;

LOAD DATA LOCAL INFILE 'data/transaction.csv'
INTO TABLE raw_transaction
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/price.csv'
INTO TABLE raw_price
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/product.csv'
INTO TABLE raw_product
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/loss_rate.csv'
INTO TABLE raw_loss_rate
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Contrôle : nombre de lignes chargées
-- attendu : transaction 878 503 / price 55 982 / product 251 / loss_rate 251
SELECT 'raw_transaction' AS table_brute, COUNT(*) AS nb_lignes FROM raw_transaction
UNION ALL SELECT 'raw_price', COUNT(*) FROM raw_price
UNION ALL SELECT 'raw_product', COUNT(*) FROM raw_product
UNION ALL SELECT 'raw_loss_rate', COUNT(*) FROM raw_loss_rate;
