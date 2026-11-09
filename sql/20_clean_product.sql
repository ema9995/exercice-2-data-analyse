-- =====================================================================
-- 20 - Nettoyage de la table product  (branche Lamyaa)
-- Source : raw_product  ->  Cible : product
-- =====================================================================

USE produits_frais;

-- ---------------------------------------------------------------------
-- 1. Diagnostic avant nettoyage
-- ---------------------------------------------------------------------

-- Codes article en double
SELECT TRIM(`item_code`) AS article, COUNT(*) AS nb
FROM raw_product
GROUP BY TRIM(`item_code`)
HAVING COUNT(*) > 1;

-- Noms avec des espaces en trop (début, fin ou espaces doubles)
SELECT `item_code`, CONCAT('[', `item_name`, ']') AS nom_brut
FROM raw_product
WHERE `item_name` <> TRIM(`item_name`)
   OR `item_name` LIKE '%  %';

-- Un même nom porté par plusieurs codes (ex. "Chinese Cabbage")
SELECT TRIM(`item_name`) AS nom, COUNT(*) AS nb_codes,
       GROUP_CONCAT(TRIM(`item_code`)) AS codes,
       COUNT(DISTINCT TRIM(`category_name`)) AS nb_categories
FROM raw_product
GROUP BY TRIM(`item_name`)
HAVING COUNT(*) > 1;

-- Cohérence code catégorie <-> nom catégorie (1 code = 1 nom attendu)
SELECT TRIM(`category_code`) AS code_categorie,
       COUNT(DISTINCT TRIM(`category_name`)) AS nb_noms
FROM raw_product
GROUP BY TRIM(`category_code`);

-- ---------------------------------------------------------------------
-- 2. Table propre
-- ---------------------------------------------------------------------

DROP TABLE IF EXISTS product;
CREATE TABLE product (
  `item_code`      VARCHAR(15)   NOT NULL,
  `item_name`      VARCHAR(100)  NOT NULL,
  `category_code`  VARCHAR(10)   NOT NULL,
  `category_name`  VARCHAR(50)   NOT NULL,
  PRIMARY KEY (`item_code`)
) ENGINE=InnoDB;

INSERT INTO product
SELECT
  TRIM(`item_code`),
  REGEXP_REPLACE(TRIM(`item_name`), ' {2,}', ' '),   -- espaces en trop
  TRIM(`category_code`),
  TRIM(`category_name`)
FROM raw_product
WHERE TRIM(`item_code`) <> '';

-- Choix assumés :
-- * Les noms en double ne sont PAS fusionnés : ce sont des codes différents
--   (formats ou fournisseurs différents). On travaille toujours sur le code.
-- * "Broccoli" existe dans 2 catégories (Flower/Leaf Vegetables et Cabbage)
--   avec 2 codes : gardé tel quel, à signaler au métier.

-- ---------------------------------------------------------------------
-- 3. Contrôles après nettoyage
-- ---------------------------------------------------------------------

SELECT `category_name`, COUNT(*) AS nb_articles
FROM product
GROUP BY `category_name`
ORDER BY nb_articles DESC;

SELECT
  (SELECT COUNT(*) FROM raw_product) AS lignes_brutes,
  (SELECT COUNT(*) FROM product)     AS lignes_propres;
