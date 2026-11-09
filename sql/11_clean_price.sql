-- =====================================================================
-- 11 - Nettoyage de la table price  (branche Ema)
-- Source : raw_price  ->  Cible : price
-- =====================================================================

USE produits_frais;

-- ---------------------------------------------------------------------
-- 1. Diagnostic avant nettoyage
-- ---------------------------------------------------------------------

-- Valeurs vides
SELECT
  SUM(TRIM(`date`) = '')             AS date_vide,
  SUM(TRIM(`item_code`) = '')        AS code_vide,
  SUM(TRIM(`wholesale_price`) = '')  AS prix_vide
FROM raw_price;

-- Plusieurs prix pour un même article le même jour ?
SELECT TRIM(`date`) AS jour, TRIM(`item_code`) AS article, COUNT(*) AS nb
FROM raw_price
GROUP BY TRIM(`date`), TRIM(`item_code`)
HAVING COUNT(*) > 1;

-- Prix nuls ou négatifs
SELECT COUNT(*) AS prix_non_positif
FROM raw_price
WHERE CAST(TRIM(`wholesale_price`) AS DECIMAL(10,2)) <= 0;

-- Articles absents du référentiel produit
SELECT COUNT(*) AS lignes_article_inconnu
FROM raw_price
WHERE TRIM(`item_code`) NOT IN (SELECT TRIM(`item_code`) FROM raw_product);

-- ---------------------------------------------------------------------
-- 2. Table propre
-- ---------------------------------------------------------------------

DROP TABLE IF EXISTS price;
CREATE TABLE price (
  `date`                    DATE         NOT NULL,
  `item_code`               VARCHAR(15)  NOT NULL,
  `wholesale_price_rmb_kg`  FLOAT        NOT NULL,
  PRIMARY KEY (`date`, `item_code`)
) ENGINE=InnoDB;

INSERT INTO price
SELECT
  STR_TO_DATE(TRIM(`date`), '%Y-%m-%d'),
  TRIM(`item_code`),
  AVG(CAST(TRIM(`wholesale_price`) AS DECIMAL(10,2)))   -- si doublon : moyenne du jour
FROM raw_price
WHERE TRIM(`date`) <> ''
  AND TRIM(`item_code`) IN (SELECT TRIM(`item_code`) FROM raw_product)
  AND CAST(TRIM(`wholesale_price`) AS DECIMAL(10,2)) > 0
GROUP BY STR_TO_DATE(TRIM(`date`), '%Y-%m-%d'), TRIM(`item_code`);

-- ---------------------------------------------------------------------
-- 3. Contrôles après nettoyage
-- ---------------------------------------------------------------------

SELECT
  (SELECT COUNT(*) FROM raw_price)   AS lignes_brutes,
  (SELECT COUNT(*) FROM price)       AS lignes_propres,
  (SELECT MIN(`date`) FROM price)    AS premiere_date,
  (SELECT MAX(`date`) FROM price)    AS derniere_date;
