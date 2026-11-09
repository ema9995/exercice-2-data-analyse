-- =====================================================================
-- 30 - Clés étrangères
-- À lancer sur la branche dev, APRÈS la fusion des deux branches
-- de nettoyage (les 4 tables propres doivent exister).
-- =====================================================================

USE produits_frais;

ALTER TABLE loss_rate
  ADD CONSTRAINT fk_loss_rate_product
  FOREIGN KEY (`item_code`) REFERENCES product(`item_code`);

ALTER TABLE price
  ADD CONSTRAINT fk_price_product
  FOREIGN KEY (`item_code`) REFERENCES product(`item_code`);

ALTER TABLE `transaction`
  ADD CONSTRAINT fk_transaction_product
  FOREIGN KEY (`item_code`) REFERENCES product(`item_code`);

-- Contrôle : chaque vente doit avoir un prix d'achat le même jour (attendu : 0)
SELECT COUNT(*) AS ventes_sans_prix_achat
FROM `transaction` t
LEFT JOIN price p ON p.`date` = t.`date` AND p.`item_code` = t.`item_code`
WHERE p.`item_code` IS NULL;
