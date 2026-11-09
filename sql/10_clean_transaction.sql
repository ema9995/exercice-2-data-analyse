-- =====================================================================
-- 10 - Nettoyage de la table transaction  (branche Ema)
-- Source : raw_transaction  ->  Cible : `transaction`
-- =====================================================================

USE produits_frais;

-- ---------------------------------------------------------------------
-- 1. Diagnostic avant nettoyage
-- ---------------------------------------------------------------------

-- Valeurs vides
SELECT
  SUM(TRIM(`date`) = '')            AS date_vide,
  SUM(TRIM(`item_code`) = '')       AS code_vide,
  SUM(TRIM(`quantity_sold`) = '')   AS quantite_vide,
  SUM(TRIM(`unit_price`) = '')      AS prix_vide
FROM raw_transaction;

-- Valeurs possibles des colonnes texte
SELECT `sale_or_return`, `discount`, COUNT(*) AS nb
FROM raw_transaction
GROUP BY `sale_or_return`, `discount`;

-- Lignes en double exact
SELECT COUNT(*) - COUNT(DISTINCT `date`, `time`, `item_code`, `quantity_sold`,
                        `unit_price`, `sale_or_return`, `discount`) AS doublons_exacts
FROM raw_transaction;

-- Incohérences de signe : une vente doit être > 0, un retour < 0
SELECT `sale_or_return`,
       SUM(CAST(`quantity_sold` AS DECIMAL(10,3)) < 0)  AS quantite_negative,
       SUM(CAST(`quantity_sold` AS DECIMAL(10,3)) = 0)  AS quantite_nulle
FROM raw_transaction
GROUP BY `sale_or_return`;

-- Quantités anormalement fortes (plus de 10 kg sur un ticket)
SELECT `date`, `item_code`, `quantity_sold`
FROM raw_transaction
WHERE ABS(CAST(`quantity_sold` AS DECIMAL(10,3))) > 10
ORDER BY ABS(CAST(`quantity_sold` AS DECIMAL(10,3))) DESC;

-- Articles absents du référentiel produit
SELECT COUNT(*) AS lignes_article_inconnu
FROM raw_transaction t
WHERE TRIM(t.`item_code`) NOT IN (SELECT TRIM(`item_code`) FROM raw_product);

-- ---------------------------------------------------------------------
-- 2. Table propre
-- ---------------------------------------------------------------------

DROP TABLE IF EXISTS `transaction`;
CREATE TABLE `transaction` (
  `date`                    DATE         NOT NULL,
  `time`                    TIME(3)      NOT NULL,
  `item_code`               VARCHAR(15)  NOT NULL,
  `quantity_sold_kg`        FLOAT        NOT NULL,
  `unit_selling_price_rmb`  FLOAT        NOT NULL,
  `sale_or_return`          VARCHAR(10)  NOT NULL,
  `discount`                VARCHAR(3)   NOT NULL
) ENGINE=InnoDB;

INSERT INTO `transaction`
SELECT DISTINCT                                            -- supprime les doublons exacts
  STR_TO_DATE(TRIM(`date`), '%Y-%m-%d'),                   -- texte -> date
  CAST(TRIM(`time`) AS TIME(3)),                           -- garde les millisecondes
  TRIM(`item_code`),                                       -- espaces parasites
  CAST(TRIM(`quantity_sold`) AS DECIMAL(10,3)),
  CAST(TRIM(`unit_price`) AS DECIMAL(10,2)),
  LOWER(TRIM(`sale_or_return`)),                           -- 'sale' / 'return'
  CASE WHEN LOWER(TRIM(`discount`)) = 'yes' THEN 'Yes' ELSE 'No' END
FROM raw_transaction
WHERE TRIM(`date`) <> ''
  AND TRIM(`item_code`) IN (SELECT TRIM(`item_code`) FROM raw_product)   -- article connu
  AND CAST(TRIM(`unit_price`) AS DECIMAL(10,2)) > 0                     -- prix positif
  AND CAST(TRIM(`quantity_sold`) AS DECIMAL(10,3)) <> 0                 -- quantité non nulle
  AND NOT (LOWER(TRIM(`sale_or_return`)) = 'sale'                       -- signe cohérent
           AND CAST(TRIM(`quantity_sold`) AS DECIMAL(10,3)) < 0)
  AND NOT (LOWER(TRIM(`sale_or_return`)) = 'return'
           AND CAST(TRIM(`quantity_sold`) AS DECIMAL(10,3)) > 0);

-- Choix assumés :
-- * Les retours sont GARDÉS (quantité négative) : ils viennent en déduction du CA.
-- * Les grosses quantités (> 10 kg, 35 lignes dont une à 160 kg) sont GARDÉES
--   mais repérées ci-dessous : à valider avec le métier avant analyse.
-- * Pas de clé primaire : aucune colonne n'identifie une vente de façon unique
--   (date + heure + article apparaît deux fois).

-- ---------------------------------------------------------------------
-- 3. Contrôles après nettoyage
-- ---------------------------------------------------------------------

SELECT
  (SELECT COUNT(*) FROM raw_transaction)  AS lignes_brutes,
  (SELECT COUNT(*) FROM `transaction`)    AS lignes_propres,
  (SELECT MIN(`date`) FROM `transaction`) AS premiere_date,
  (SELECT MAX(`date`) FROM `transaction`) AS derniere_date;

SELECT COUNT(*) AS lignes_plus_de_10_kg
FROM `transaction`
WHERE ABS(`quantity_sold_kg`) > 10;
