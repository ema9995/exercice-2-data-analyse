# Exercice 1 : Produits frais, nettoyage des données en SQL

Lamyaa Marzouq et Ema Fernandes

## Contexte

Le Comex trouve que les ventes de produits frais ne performent pas assez sur certaines catégories. Il veut le chiffre d'affaires, le volume et la marge brute par catégorie, en magasin physique, comparés à la même période un an plus tôt, avec une attention particulière aux articles dont le taux de perte dépasse 15 %.

Avant de calculer ces indicateurs, il faut des données propres. Ce dépôt contient tout le nettoyage, fait en SQL (MySQL 8).

## Les données

4 fichiers CSV, à placer dans le dossier `data/` (ils ne sont pas versionnés) :

| Fichier | Contenu | Lignes |
|---|---|---|
| `transaction.csv` | Une ligne par vente ou retour en caisse (juillet 2020 – juin 2023) | 878 503 |
| `price.csv` | Prix d'achat (grossiste) par article et par jour | 55 982 |
| `product.csv` | Article et sa catégorie (6 catégories) | 251 |
| `loss_rate.csv` | Taux de perte par article | 251 |

## Modèle de données

| Table | Clé primaire | Clé étrangère |
|---|---|---|
| `product` | `item_code` | aucune |
| `loss_rate` | `item_code` | `item_code` → `product` |
| `price` | (`date`, `item_code`) | `item_code` → `product` |
| `transaction` | aucune (aucune colonne n'identifie une vente de façon unique) | `item_code` → `product` |

Pour calculer la marge, une vente est reliée au prix d'achat du même article le même jour (`date` + `item_code`).

## Ce qui a été fait

### 1. Chargement (branche `dev`)

- `00_create_raw_tables.sql` : crée la base `produits_frais` et 4 tables brutes `raw_...`, avec toutes les colonnes en texte. Aucune ligne n'est rejetée au chargement : le typage se fait au nettoyage, ce qui permet de voir les erreurs au lieu de les perdre.
- `01_load_raw_data.sql` : charge les CSV. Les fichiers ont des fins de ligne Windows (`\r\n`), prises en compte pour éviter un caractère invisible en fin de ligne.

### 2. Nettoyage de `transaction` et `price` (branche `feature/nettoyage-transaction-price`, Ema)

**`10_clean_transaction.sql`**
- Conversion des types : texte → date, heure (avec millisecondes), nombres.
- Suppression des espaces parasites et harmonisation des valeurs (`sale` / `return`, `Yes` / `No`).
- Suppression des doublons exacts.
- Lignes exclues : article absent du référentiel, prix nul ou négatif, quantité nulle, signe incohérent (vente négative ou retour positif).
- Retours gardés (461 lignes à quantité négative) : ils viennent en déduction du chiffre d'affaires.
- Grosses quantités gardées mais signalées : 35 lignes de plus de 10 kg, dont une à 160 kg, à valider avec le métier.

**`11_clean_price.sql`**
- Conversion des types et suppression des espaces.
- Un seul prix par article et par jour (moyenne en cas de doublon).
- Exclusion des prix nuls ou négatifs et des articles inconnus.

### 3. Nettoyage de `product` et `loss_rate` (branche `feature/nettoyage-product-loss-rate`, Lamyaa)

**`20_clean_product.sql`**
- Suppression des espaces en trop dans les noms (en début, en fin ou en double).
- Contrôle de cohérence : un code catégorie correspond toujours au même nom de catégorie.
- Noms en double repérés mais gardés : ce sont des codes différents (« Chinese Cabbage » existe sur 2 codes, « Broccoli » dans 2 catégories). On travaille toujours sur le code article, jamais sur le nom.

**`21_clean_loss_rate.sql`**
- Le taux était stocké avec un espace en fin de valeur (« 4.39 ») : nettoyé et converti en nombre.
- Contrôle que chaque taux est entre 0 et 100 et que chaque article existe dans `product`.
- Repérage des articles à plus de 15 % de perte (29 articles).
- Valeurs suspectes gardées mais signalées : 85 articles ont exactement 9,43 % (valeur par défaut probable) et 22 ont 0 %.

### 4. Liens entre tables (branche `dev`, après fusion)

`30_add_foreign_keys.sql` ajoute les clés étrangères et vérifie que chaque vente a bien un prix d'achat le même jour.

Chaque script de nettoyage suit la même structure : **diagnostic** des problèmes, création de la **table propre**, puis **contrôles** (lignes avant / après, dates min / max).

## Points d'attention pour l'analyse

- Les données s'arrêtent au 30 juin 2023.
- Aucune colonne ne permet de distinguer magasin physique et vente en ligne : on considère que toutes les ventes sont en magasin.
- Le taux de perte est un taux fixe par article, sans date : il est appliqué à toute la période.

## Organisation des branches

| Branche | Rôle | Qui |
|---|---|---|
| `main` | Version finale, validée | les deux |
| `dev` | Intégration : on y fusionne les deux branches de nettoyage | les deux |
| `feature/nettoyage-transaction-price` | Nettoyage des tables `transaction` et `price` | Ema |
| `feature/nettoyage-product-loss-rate` | Nettoyage des tables `product` et `loss_rate` | Lamyaa |

Chacune a travaillé sur sa branche puis ouvert une pull request vers `dev`. Une fois `dev` vérifiée, `dev` a été fusionnée dans `main`.

## Ordre d'exécution (MySQL 8)

1. `sql/00_create_raw_tables.sql`
2. `sql/01_load_raw_data.sql`
3. `sql/20_clean_product.sql` puis `sql/21_clean_loss_rate.sql`
4. `sql/10_clean_transaction.sql` puis `sql/11_clean_price.sql`
5. `sql/30_add_foreign_keys.sql`

Le chargement des CSV demande que MySQL autorise `LOCAL INFILE`. Depuis la racine du dépôt :
`mysql --local-infile=1 -u root -p < sql/01_load_raw_data.sql`
