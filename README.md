# Exercice 1 : Produits frais, nettoyage des données en SQL

Lamyaa Marzouq et Ema Fernandes

## Les données

4 fichiers CSV, à placer dans le dossier `data/` (ils ne sont pas versionnés) :

| Fichier | Contenu |
|---|---|
| `transaction.csv` | Une ligne par vente ou retour en caisse |
| `price.csv` | Prix d'achat (grossiste) par article et par jour |
| `product.csv` | Article et sa catégorie |
| `loss_rate.csv` | Taux de perte par article |

## Organisation des branches

| Branche | Rôle | Qui |
|---|---|---|
| `main` | Version finale, validée | les deux |
| `dev` | Intégration : on y fusionne les deux branches de nettoyage | les deux |
| `feature/nettoyage-transaction-price` | Nettoyage des tables `transaction` et `price` | Ema |
| `feature/nettoyage-product-loss-rate` | Nettoyage des tables `product` et `loss_rate` | Lamyaa |

Chacune travaille sur sa branche, puis ouvre une pull request vers `dev`. Une fois `dev` vérifiée, on fusionne `dev` dans `main`.

## Ordre d'exécution (MySQL 8)

1. `sql/00_create_raw_tables.sql` : crée la base et les tables brutes (tout en texte)
2. `sql/01_load_raw_data.sql` : charge les CSV dans les tables brutes
3. `sql/20_clean_product.sql` puis `sql/21_clean_loss_rate.sql` (branche Lamyaa)
4. `sql/10_clean_transaction.sql` puis `sql/11_clean_price.sql` (branche Ema)
5. `sql/30_add_foreign_keys.sql` : ajoute les liens entre tables, une fois les deux branches fusionnées dans `dev`

Pour le chargement des CSV, MySQL doit autoriser `LOCAL INFILE` :
`mysql --local-infile=1 -u root -p < sql/01_load_raw_data.sql` (lancé depuis la racine du dépôt).
