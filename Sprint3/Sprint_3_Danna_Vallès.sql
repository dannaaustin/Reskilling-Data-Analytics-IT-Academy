/* ============================================================================
   PROJECTE: sprint3-analytics-danna-id
   SPRINT 3 — Introducció a BigQuery i SQL al Núvol
   ============================================================================ */

/* ============================================================================
   NIVELL 1 — ENTORN I INGESTA HÍBRIDA (CODE-FIRST)
   ============================================================================ */

/* N1.e1. Exercici 1: Arquitectura de Dades (Lògica vs. Física) ----------------------------------------

   Implementar físicament l'arquitectura lògica creant tres Datasets dins d'un mateix projecte per centralitzar la facturació i els permisos.

   » Dataset sprint3_bronze (Capa Bronze - Dades Crudes)    -> Metode: UI (clics)
   » Dataset sprint3_silver (Capa Silver - Dades Netes)     -> Metode: SQL (CREATE SCHEMA)
   » Dataset sprint3_gold   (Capa Gold - Dades de Negoci)   -> Metode: Cloud Shell (bq)

   Regió pipeline: EU (coincideix amb el bucket origen)         */

# 							……………………………………………………………………………………………………………….
-- BRONZE: creat via UI (sense codi)

-- SILVER: creat via SQL
CREATE SCHEMA `sprint3-analytics-danna-id.sprint3_silver`
OPTIONS (location = 'EU');

-- GOLD: creat via Cloud Shell (bq CLI)
-- bq mk --dataset --location=EU sprint3-analytics-danna-id:sprint3_gold

/* N1.e2. Exercici 2: Ingesta en Capa Bronze (Connexió DDL) -----------------------------------

   CREATE EXTERNAL TABLE per connectar els fitxers del Data Lake (GCS)
   al dataset sprint3_bronze sense moure les dades originals.            */

-- transactions_raw (ERP) -> delimitador ; (Punt i coma) …………………….
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-danna-id.sprint3_bronze.transactions_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  field_delimiter = ';',
  skip_leading_rows = 1
);

-- companies_raw (ERP) -> esquema manual, tot text, ignora 1a fila
-- ‼! CORREGIT: es va crear primer amb "id" en lloc de "company_id" real (verificat al CSV)

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-danna-id.sprint3_bronze.companies_raw` (
  company_id   STRING,
  company_name STRING,
  phone        STRING,
  email        STRING,
  country      STRING,
  website      STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1
);

-- american_users_raw (CRM) -> estandard ………………………………………………………………………………………………………………………
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-danna-id.sprint3_bronze.american_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
  skip_leading_rows = 1
);

-- european_users_raw (CRM) -> estandard ………………………………………………………………………………………………………………………
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-danna-id.sprint3_bronze.european_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
  skip_leading_rows = 1
);

-- credit_cards_raw (CRM) -> estandard ………………………………………………………………………………………………………………………
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-danna-id.sprint3_bronze.credit_cards_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
  skip_leading_rows = 1
);

/* N1.e3. Exercici 3: Carrega de Dades Locals (Upload) --------------------------------

   products.csv (de l'Sprint 2) no es al Data Lake.
   Carregat manualment ("Upload") -> sprint3_bronze.products_raw
   Única Taula Nativa de la capa Bronze.                                  */

-- Sense codi: carrega feta via UI (Upload local -> Native Table)


/* N1.e4. Exercici 4: Arquitectura i Rendiment. Materialització de Dades ---------------------------------------------------------------- */


/* N1.e4a. Materialització de Dades (Assistit per IA) .............................
   Prompt usat: "Write a SQL query to create a new table called transactions_raw_native in the sprint3_bronze dataset. 
   It should contain all data from the transactions_raw table. 
Please use CREATE OR REPLACE TABLE so I don't get errors if I run it more than once."             */

CREATE OR REPLACE TABLE `sprint3-analytics-danna-id.sprint3_bronze.transactions_raw_native` AS
SELECT *
FROM `sprint3-analytics-danna-id.sprint3_bronze.transactions_raw`;


-- N1.e4b. Auditoria de Costos ………………………………………………………………………………………………………………………………………..
-- NO executar. "Dry Run" -> quants Bytes processara:

-- Consulta 1 (Externa)
SELECT id FROM `sprint3_bronze.transactions_raw`; -- 0 MB

-- Consulta 2 (Nativa)
SELECT id FROM `sprint3_bronze.transactions_raw_native`; -- 3.62 MB

-- N1.e4c. El perill del LIMIT ………………………………………………………………………………………………………………………………
-- validador (Dry Run)                              Taula Nativa

SELECT * FROM `sprint3_bronze.transactions_raw_native`
LIMIT 10; -- 10.87 MB
-- Conclusió: LIMIT NO redueix el cost. BigQuery escaneja totes les columnas demanades de TOTES les files abans d'aplicar el LIMIT al final.



/* N1.e5. Exercici 5: Adaptació de Sintaxi (Reporting) ----------------------------------------------------------------
   Top 5 dies amb mes ingressos de l'any 2021                              */

SELECT
  DATE(timestamp) AS dia,                    -- "Netejar" l'hora
  ROUND(SUM(amount), 2) AS ingresos_totales  -- ja es FLOAT (SAFE_CAST(amount AS FLOAT64))
FROM `sprint3-analytics-danna-id.sprint3_bronze.transactions_raw_native`
WHERE EXTRACT(YEAR FROM timestamp) = 2021    -- EXTRACT retorna INT64
GROUP BY dia
ORDER BY ingresos_totales DESC
LIMIT 5;

/* N1.e6. Exercici 6: Consultes Complexes ------------------------------------------------------

   Nom, país i data de les transaccions d'empreses que van fer operacions
   entre 100 i 200 euros en alguna d'aquestes dates: 29-04-2015, 20-07-2018
   o 13-03-2024.                                                          */

SELECT
  c.company_name,
  c.country,
  DATE(t.timestamp) AS data_transaccio
FROM `sprint3-analytics-danna-id.sprint3_bronze.transactions_raw_native` AS t
INNER JOIN `sprint3-analytics-danna-id.sprint3_bronze.companies_raw` AS c
  ON t.business_id = c.company_id  -- 
WHERE t.amount BETWEEN 100 AND 200
  AND FORMAT_DATE('%d-%m-%Y', DATE(t.timestamp)) IN ('29-04-2015', '20-07-2018', '13-03-2024');
  -- Converteix data a STRING amb format dd-mm-yyyy -> fer match amb format de l'enunciat


/* ============================================================================
   NIVELL 2 — NETEJA I TRANSFORMACIÓ (ELT)
   ============================================================================ */

/* N2.e1. Exercici 1: Neteja de Productes (Data Quality) -------------------------------

   » id -> product_id | product_name -> name
   » warehouse_id: elimina prefix "WH-" i converteix a INT64
   » price: garantir FLOAT64 sense símbols de moneda
   » weight: es conserva tal qual                                          */

CREATE OR REPLACE TABLE `sprint3-analytics-danna-id.sprint3_silver.products_clean` AS
SELECT
  id AS product_id,
  product_name AS name,
  SAFE_CAST(price AS FLOAT64) AS price,
  colour,
  weight,
  SAFE_CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
  category,
  brand,
  cost,
  launch_date
FROM `sprint3-analytics-danna-id.sprint3_bronze.products_raw`;
-- Correcció Posterior: Bronze -> Silver no ha de perdre informació, nomes netejar.


/* N2.e2. Exercici 2: Creació de Transaccions Netes (Capa Silver) -----------------------------------------------------------------------------

   » id -> transaction_id
   » amount: SAFE_CAST + IFNULL(...,0) per robustesa
   » timestamp: STRING -> TIMESTAMP real -- ASUMIDO: format origen no ….aaaaah !!
     confirmat amb SELECT LIMIT 1 (es va aplicar SAFE_CAST directe)
   » lat / longitude: SAFE_CAST a FLOAT64
   » product_ids: text "1, 2, 3" -> ARRAY<INT64> [1,2,3]
   » Resta de camps: es mantenen igual                                     */

CREATE OR REPLACE TABLE `sprint3-analytics-danna-id.sprint3_silver.transactions_clean` AS
SELECT
  id AS transaction_id,
  card_id,
  business_id,
  SAFE_CAST(timestamp AS TIMESTAMP) AS transaction_timestamp,  -- format Data i Hora
  IFNULL(SAFE_CAST(amount AS FLOAT64), 0.0) AS amount,         -- Gestió errors
  declined,

  ARRAY(
    SELECT SAFE_CAST(TRIM(p_id) AS INT64)        -- Borra espais en blanc, text a Enter
    FROM UNNEST(SPLIT(product_ids, ',')) AS p_id -- Divideix, crea Array, Desenrolla
  ) AS product_ids,

  user_id,
  SAFE_CAST(lat AS FLOAT64) AS lat,
  SAFE_CAST(longitude AS FLOAT64) AS longitude

FROM `sprint3-analytics-danna-id.sprint3_bronze.transactions_raw`;

/* N2.e3. Exercici 3: Unificació d'Usuaris (UNION) ---------------------------------------------------------------------

   Crea sprint3_silver.users_combined. UNION ALL per unificar usuaris dels EUA i Europa en una única llista mestra + columna calculada origin.
   » id -> user_id                                                         */

CREATE OR REPLACE TABLE `sprint3-analytics-danna-id.sprint3_silver.users_combined` AS
SELECT
  id AS user_id,
  * EXCEPT(id),  -- totes excepte la nom canviat; Nova
  'USA' AS origin
FROM `sprint3-analytics-danna-id.sprint3_bronze.american_users_raw`  -- No vull EUA

UNION ALL

SELECT
  id AS user_id,
  * EXCEPT(id),
  'EU' AS origin
FROM `sprint3-analytics-danna-id.sprint3_bronze.european_users_raw`;
-- conserva duplicats

/* N2.e4. Exercici 4: Materialització de Companyies i Targetes de Credit ----------------------------------------------------------------------

   » companies_clean i credit_cards_clean: còpia íntegra a taula NATIVA
   » Reanomenar id segons correspongui                                     */

CREATE OR REPLACE TABLE `sprint3-analytics-danna-id.sprint3_silver.companies_clean` AS
SELECT
  id AS company_id,
  * EXCEPT(id)
FROM `sprint3-analytics-danna-id.sprint3_bronze.companies_raw`;

CREATE OR REPLACE TABLE `sprint3-analytics-danna-id.sprint3_silver.credit_cards_clean` AS
SELECT
  id AS card_id,
  * EXCEPT(id)
FROM `sprint3-analytics-danna-id.sprint3_bronze.credit_cards_raw`;


/* ============================================================================
   NIVELL 3 — PRESENTACIÓ DE DADES I CREACIÓ DE VISTES
   ============================================================================ */

/* N3.e1. Exercici 1: La Vista de Marqueting (Lògica de Negoci) ---------------

   sprint3_gold.v_marketing_kpis amb: nom, telefon, país (companies_clean),
   mitjana de compra (AVG(amount)) i client_tier:
     > 260€ -> "Premium" | <= 260€ -> "Standard"                           */

CREATE OR REPLACE VIEW `sprint3-analytics-danna-id.sprint3_gold.v_marketing_kpis` AS
SELECT
  c.company_name,
  c.phone,
  c.country,
  ROUND(AVG(t.amount), 2) AS avg_purchase,
  CASE
    WHEN AVG(t.amount) > 260 THEN 'Premium'
    ELSE 'Standard'
  END AS client_tier
FROM `sprint3-analytics-danna-id.sprint3_silver.companies_clean` AS c
JOIN `sprint3-analytics-danna-id.sprint3_silver.transactions_clean` AS t
  ON c.company_id = t.business_id  --  
GROUP BY c.company_name, c.phone, c.country;

-- Consulta d'entrega -> VISTA (Premium primer, ordenat per mitjana descendent)
SELECT *
FROM `sprint3-analytics-danna-id.sprint3_gold.v_marketing_kpis`
ORDER BY
  client_tier ASC,
  avg_purchase DESC;

/* N3.e2. Exercici 2: Ranquing de Productes (La Potencia dels Arrays) -------------------------------------------------------------------------

   sprint3_gold.product_sales_ranking: product_id, name, price, colour
   (de products_clean) + total_sold (vendes comptades). 
   Tots els productes
   han d'apareixer, fins i tot amb 0 vendes (LEFT JOIN des de products).    */

CREATE OR REPLACE TABLE `sprint3-analytics-danna-id.sprint3_gold.product_sales_ranking` AS

WITH ventes_trans AS (
  SELECT product_id
  FROM `sprint3-analytics-danna-id.sprint3_silver.transactions_clean`,
  UNNEST(product_ids) AS product_id
)
SELECT
  p.product_id,
  p.name,
  p.price,
  p.colour,
  COUNT(v.product_id) AS total_sold
FROM `sprint3-analytics-danna-id.sprint3_silver.products_clean` AS p
LEFT JOIN ventes_trans AS v ON p.product_id = v.product_id
GROUP BY p.product_id, p.name, p.price, p.colour  -- count
ORDER BY total_sold DESC;

/* N3.e3. Exercici 3: Exportació de Resultats -----------------------------------------

   Exporta product_sales_ranking a Google Sheets o CSV local.              */

-- Això NO es SQL. Passos a la UI:
-- 1. Executa:
SELECT * FROM `sprint3-analytics-danna-id.sprint3_gold.product_sales_ranking`;
-- 2. A "Resultats de la consulta" -> botó "Guardar els resultats" / "Export".
-- 3. Tria "Google Sheets" (full nou automatic) o "CSV" (fitxer local).
-- 4. Captura de pantalla d Excel/Sheets.

