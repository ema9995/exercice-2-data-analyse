-- =====================================================================
-- 00 - Base et tables brutes
-- Les tables "raw_" reçoivent les CSV tels quels, tout en texte :
-- aucune ligne n'est rejetée au chargement, le typage se fait au nettoyage.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS produits_frais
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE produits_frais;

DROP TABLE IF EXISTS raw_transaction;
CREATE TABLE raw_transaction (
  `date`            VARCHAR(255),
  `time`            VARCHAR(255),
  `item_code`       VARCHAR(255),
  `quantity_sold`   VARCHAR(255),
  `unit_price`      VARCHAR(255),
  `sale_or_return`  VARCHAR(255),
  `discount`        VARCHAR(255)
);

DROP TABLE IF EXISTS raw_price;
CREATE TABLE raw_price (
  `date`             VARCHAR(255),
  `item_code`        VARCHAR(255),
  `wholesale_price`  VARCHAR(255)
);

DROP TABLE IF EXISTS raw_product;
CREATE TABLE raw_product (
  `item_code`      VARCHAR(255),
  `item_name`      VARCHAR(255),
  `category_code`  VARCHAR(255),
  `category_name`  VARCHAR(255)
);

DROP TABLE IF EXISTS raw_loss_rate;
CREATE TABLE raw_loss_rate (
  `item_code`  VARCHAR(255),
  `item_name`  VARCHAR(255),
  `loss_rate`  VARCHAR(255)
);
