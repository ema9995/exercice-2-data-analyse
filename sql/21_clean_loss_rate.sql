-- =====================================================================
-- 21 - Nettoyage de la table loss_rate  (branche Lamyaa)
-- Source : raw_loss_rate  ->  Cible : loss_rate
-- =====================================================================

USE produits_frais;

-- ---------------------------------------------------------------------
-- 1. Diagnostic avant nettoyage
-- ---------------------------------------------------------------------

-- Le taux est stocké avec un espace en fin de valeur ("4.39 ")
SELECT COUNT(*) AS taux_avec_espace
FROM raw_loss_rate
WHERE `loss_rate` <> TRIM(`loss_rate`);

-- Taux hors de [0 ; 100]
SELECT `item_code`, `loss_rate`
FROM raw_loss_rate
WHERE CAST(TRIM(`loss_rate`) AS DECIMAL(5,2)) NOT BETWEEN 0 AND 100;

-- Valeurs suspectes : 9,43 % répété (valeur par défaut ?) et 0 %
SELECT CAST(TRIM(`loss_rate`) AS DECIMAL(5,2)) AS taux, COUNT(*) AS nb_articles
FROM raw_loss_rate
GROUP BY taux
HAVING COUNT(*) > 5
ORDER BY nb_articles DESC;

-- Articles à plus de 15 % de perte (seuil donné par le métier)
SELECT TRIM(`item_name`) AS article, CAST(TRIM(`loss_rate`) AS DECIMAL(5,2)) AS taux
FROM raw_loss_rate
WHERE CAST(TRIM(`loss_rate`) AS DECIMAL(5,2)) > 15
ORDER BY taux DESC;

-- Codes absents du référentiel produit
SELECT COUNT(*) AS article_inconnu
FROM raw_loss_rate
WHERE TRIM(`item_code`) NOT IN (SELECT TRIM(`item_code`) FROM raw_product);

-- Nom différent entre loss_rate et product pour un même code
SELECT l.`item_code`, TRIM(l.`item_name`) AS nom_loss_rate, TRIM(p.`item_name`) AS nom_product
FROM raw_loss_rate l
JOIN raw_product p ON TRIM(p.`item_code`) = TRIM(l.`item_code`)
WHERE TRIM(l.`item_name`) <> TRIM(p.`item_name`);

-- ---------------------------------------------------------------------
-- 2. Table propre
-- ---------------------------------------------------------------------

DROP TABLE IF EXISTS loss_rate;
CREATE TABLE loss_rate (
  `item_code`      VARCHAR(15)   NOT NULL,
  `item_name`      VARCHAR(100)  NOT NULL,
  `loss_rate_pct`  FLOAT         NOT NULL,
  PRIMARY KEY (`item_code`)
) ENGINE=InnoDB;

INSERT INTO loss_rate
SELECT
  TRIM(`item_code`),
  REGEXP_REPLACE(TRIM(`item_name`), ' {2,}', ' '),
  CAST(TRIM(`loss_rate`) AS DECIMAL(5,2))          -- "4.39 " -> 4.39
FROM raw_loss_rate
WHERE TRIM(`item_code`) IN (SELECT TRIM(`item_code`) FROM raw_product)
  AND CAST(TRIM(`loss_rate`) AS DECIMAL(5,2)) BETWEEN 0 AND 100;

-- Choix assumés :
-- * Les taux à 9,43 % (85 articles) et à 0 % (22 articles) sont GARDÉS :
--   rien ne permet de les corriger, mais ils sont peu fiables (à signaler).
-- * Un seul taux par article, sans date : il est appliqué à toute la période.

-- ---------------------------------------------------------------------
-- 3. Contrôles après nettoyage
-- ---------------------------------------------------------------------

SELECT
  (SELECT COUNT(*) FROM raw_loss_rate)  AS lignes_brutes,
  (SELECT COUNT(*) FROM loss_rate)      AS lignes_propres,
  (SELECT COUNT(*) FROM loss_rate WHERE `loss_rate_pct` > 15) AS articles_plus_de_15_pct;
