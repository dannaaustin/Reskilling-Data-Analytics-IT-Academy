/* ============================================================
Danna Vallès
-- ESPECIALITZACIÓ DATA ANALYTICS · IT Academy
-- Sprint 2 · S2.01 · Nocions bàsiques SQL
-- Base de dades (BBDD): transactions
-- ============================================================*/

USE transactions;

/* EXERCICI 2 ==============================================================================================================================
   Utilitzant JOIN realitzaràs les següents consultes */

-- 🟣 e2.1 — Llista de PAÏSOS que estan generant VENDES
SELECT DISTINCT c.country
FROM transaction t
JOIN company c ON t.company_id = c.id
WHERE t.declined = 0
ORDER BY c.country;
-- R. Llista dels 15 països		 (noms)																							


-- 🟣 e2.2 — Des de QUANTS PAÏSOS es generen les VENDES
-- Nota: GROUP BY ja elimina duplicats, no cal DISTINCT
SELECT COUNT(DISTINCT c.country) AS num_paisos_amb_vendes
FROM transaction t
JOIN company c ON t.company_id = c.id
WHERE t.declined = 0;
-- R. Numero, 15 paisos

# Per mi, per si vull veure quins paisos ¿? :
SELECT c.country, ROUND(AVG(t.amount), 3) AS promedio_ventas --
FROM transaction t
JOIN company c ON t.company_id = c.id
WHERE t.declined = 0
GROUP BY country ORDER BY promedio_ventas DESC; 

-- 🟣 e2.3 — Empresa amb la MITJANA més GRAN de vendes
SELECT    c.company_name,    c.country,    ROUND(AVG(t.amount), 2) AS mitjana_vendes,    COUNT(t.id)             AS num_transaccions
FROM transaction t
JOIN company c ON t.company_id = c.id WHERE t.declined = 0
GROUP BY c.id, c.company_name, c.country ORDER BY mitjana_vendes DESC LIMIT 1;
-- R. 'Ac Fermentum Incorporated', 284.91


/* EXERCICI 3 ==============================================================================================================================
	Utilitzant NOMÉS subconsultes (sense JOIN)*/


-- 🟣 e3.1 — Totes les TRANSACCIONS d'empreses d'ALEMANYA
SELECT    t.company_id,
    (SELECT c.company_name FROM company c WHERE c.id = t.company_id) AS empresa,
    t.amount,    t.declined
FROM transaction t
WHERE t.company_id IN (    SELECT c.id FROM company c WHERE c.country = 'Germany') ORDER BY amount DESC;
    
-- R. 10.000 transaccions Alemanes ( No especificava si Transacció acceptada o no ).
# 8 Empreses Alemanas
/*('b-2222','Ac Fermentum Incorporated' 'b-2234','Convallis In Incorporated' 'b-2302','Nunc Interdum Incorporated' 
'b-2306','Augue Foundation' 'b-2358','Ac Industries' 'b-2550','Auctor Mauris Corp.' 'b-2566','Aliquam PC' 'b-2614','Rutrum Non Inc.' )

SELECT id, company_name 
FROM company 
WHERE country = "Germany"; #--> ID+Noms ................................................

SELECT DISTINCT t.company_id
FROM transaction AS t
WHERE t.company_id IN 
( SELECT c.id FROM company AS c WHERE c.country = "Germany"); # id.empresa NOMES*/


-- 🟣 e3.1.1 — Noms de les empreses d'ALEMANYA i el seu resum de transaccions (Agrupat) ...  ...  ... ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...
SELECT     t.company_id AS id_empresa,
    (SELECT c.company_name FROM company c WHERE c.id = t.company_id) AS empresa, 
    COUNT(t.id) AS total_transaccions,     SUM(t.amount) AS suma_total_amount 
FROM transaction t 
WHERE t.company_id IN (     SELECT c.id FROM company c WHERE c.country = 'Germany')  GROUP BY t.company_id; # 13.291

-- 🟣 e3.2 — Empreses amb transaccions superiors a la MITJANA Amount (SUBQUERIES) ...  ...  ... ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...
#LA MITJANA de totes les Transaccions:
			SELECT ROUND(AVG(amount), 2) AS mitjana_global FROM transaction  WHERE declined = 0; # R. 258.92
-- 																			...
SELECT     c.id,    c.company_name,
    (SELECT ROUND(AVG(t.amount), 2)     FROM transaction t     WHERE t.company_id = c.id       AND t.declined = 0) AS mitjana_vendes
FROM company c
WHERE (    SELECT AVG(t.amount)
    FROM transaction t    WHERE t.company_id = c.id AND t.declined = 0) > (SELECT AVG(t2.amount) FROM transaction t2 WHERE t2.declined = 0)
ORDER BY mitjana_vendes DESC; # 48 empresas amb Valor Transacció PER SOBRE Average


--  e3.2 Amount > Media
SELECT     c.id,     c.company_name,
    (SELECT SUM(t.amount)      FROM transaction t      WHERE t.company_id = c.id AND t.declined = 0) AS total_vendes
FROM company c
WHERE c.id IN (
    SELECT company_id     FROM transaction     WHERE declined = 0 AND amount > (SELECT AVG(amount) FROM transaction WHERE declined = 0) ) -- Mitjana
ORDER BY c.company_name; # R. 100 rows 


-- AMB JOIN (per mi):
SELECT     c.id,    c.company_name,    ROUND(AVG(t.amount), 2) AS Jmitja_vendes
FROM transaction t 				JOIN company c ON t.company_id = c.id WHERE t.declined = 0
GROUP BY c.id, c.company_name
HAVING AVG(t.amount) > (    SELECT AVG(amount) FROM transaction WHERE declined = 0)
ORDER BY Jmitja_vendes DESC; # 48 rows


/*SELECT    c.id,    c.company_name,
    (SELECT SUM(t.amount)
     FROM transaction t
     WHERE t.company_id = c.id       AND t.declined = 0) AS total_vendes
FROM company c
WHERE c.id IN (    SELECT t.company_id    FROM transaction t
						WHERE t.declined = 0 AND t.amount > (
										  SELECT AVG(t2.amount)
										  FROM transaction t2 WHERE t2.declined = 0)
)
ORDER BY c.company_name; -- R. 100 rows*/


-- 🟣 e3.3 — Empreses SENSE transaccions registrades			 ...... 			......			......
SELECT    c.id,    c.company_name
FROM company c 
WHERE c.id NOT IN (
    SELECT DISTINCT t.company_id
    FROM transaction t
     WHERE t.company_id IS NOT NULL) # no hi NULLS han BUT 
ORDER BY c.company_name;
# SELECT COUNT(*) FROM transaction WHERE company_id IS NULL;

# R. 0 rows -> totes les empreses tenen almenys una transacció registrada. No cal eliminar cap empresa del sistema.


/*  EXERCICI 4 ==============================================================================================================================
   Crear taula "credit_card".
   establir una relació adequada amb les altres 2 taules ("transaction" i "company").*/


/* Tbt :-- Insertamos datos de credit_card :
-- INSERT INTO credit_card (id, iban, pan, pin, cvv, expiring_date) VALUES ('CcU-2938', 'TR301950312213576817638661', '5424465566813633', '3257', '984', '10/30/22');
(id, 					iban, 					pan, 			pin, 	cvv, 	expiring_date) VALUES (
'CcU-2945', 'DO26854763748537475216568689', '5142423821948828', '9080', '887', '08/24/23'); */


CREATE TABLE IF NOT EXISTS credit_card (
    id            VARCHAR(15) PRIMARY KEY,
    iban          VARCHAR(35),
    pan           VARCHAR(20),
    pin           VARCHAR(4),
    cvv           VARCHAR(4),
    expiring_date VARCHAR(14));

-- Carregar dades: SOURCE N1-Ex.4__datos_introducir_credit.sql
# doc @S2_Estructura
 
-- Veure noms exactes 
SELECT CONSTRAINT_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'transactions'
AND TABLE_NAME = 'transaction'
AND REFERENCED_TABLE_NAME IS NOT NULL;


/*-- FK: transaction -> credit_card
ALTER TABLE transaction
ADD FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);

-- FK: transaction -> company
ALTER TABLE transaction
ADD FOREIGN KEY (company_id) REFERENCES company(id); */

-- Verificar las 2 relaciones
SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'transactions'
AND TABLE_NAME = 'transaction'
AND REFERENCED_TABLE_NAME IS NOT NULL;


/* EXERCICI 5 ==============================================================================================================================
--  error en el número de compte associat a la targeta de crèdit amb ID CcU-2938. 
-- 🟣 5.2 MODIFICAR registre (iban): TR323456312213576817699999.  Mostra el canvi fet. */

UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

-- 🟣 e5.2 Mostrar CANVI.  Verificació
SELECT id, iban, expiring_date
FROM credit_card
WHERE id = 'CcU-2938';

/*
  id        | iban                        | expiring_date
  CcU-2938  | TR323456312213576817699999  | ...
*/

/* EXERCICI 6 ==============================================================================================================================
   e.6 Inserir nova transacció 
id :108B1D1D-5B23-A76C-55EF-C568E49A99DD 
credit_card_id :CcU-9999 
company_id :b-9999 
user_id :9999 
lat :829.999 
longitude :-117.999 
X timestamp X
amount :111.11 
declined :0  */


-- 1.  empresa b-9999 - Pares per FK
INSERT IGNORE INTO company (id, company_name) 
VALUES ('b-9999', 'Random');

-- 2. targeta CcU-9999 
INSERT IGNORE INTO credit_card (id, iban) VALUES ('CcU-9999', 'ES0000000000000000000000');


/* INSERT INTO transaction (
    id,     credit_card_id,     company_id, user_id, lat,     longitude, timestamp, amount,     declined)
VALUES (
    '108B1D1D-5B23-A76C-55EF-C568E49A99DD', 
    'CcU-9999', 
    'b-9999', 
    9999, 
    829.999, 
    -117.999, 
    CURRENT_TIMESTAMP, -- la fecha y hora exacta de este segundo vs /NOW(), -- Inserta la fecha/hora actual. 
    111.11, 
    0); # Primero se ha de haber creado Registro en la Tabla Padre */


-- 🟣 Verificació
SELECT * FROM transaction 
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


/* EXERCICI 7 ==============================================================================================================================
-- e7.1 BORRAR COLUMNA "PAN" de la taula credit_card. 
-- e7.2 Mostrar el canvi. */

ALTER TABLE credit_card DROP COLUMN pan;

-- 🟣e7.2  Verificació del canvi
DESCRIBE credit_card; # ID = Key
/*
  id            varchar(15)  NO   PRI
  iban          varchar(35)  YES
  pin           varchar(4)   YES
  cvv           varchar(4)   YES
  expiring_date varchar(14)  YES */

# o 
SHOW COLUMNS FROM credit_card;
									/*'id','varchar(15)','NO','PRI',NULL,''
									'iban','varchar(35)','YES','',NULL,''
									'pin','varchar(4)','YES','',NULL,''
									'cvv','varchar(5)','YES','',NULL,''
									'expiring_date','varchar(10)','YES','',NULL,''
*/

/* EXERCICI 8 ==============================================================================================================================
   Esquema d'estrella amb CSVs */

-- Verificació de les taules carregades i estructura
SHOW TABLES IN transactions;

SELECT
    TABLE_NAME  AS taula,
    COLUMN_NAME AS columna,
    COLUMN_KEY  AS clau,
    DATA_TYPE   AS tipus,
    IS_NULLABLE AS nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'transactions'
ORDER BY COLUMN_KEY DESC, TABLE_NAME ASC, ORDINAL_POSITION ASC;

-- Verificació de relacions (PKs i FKs)
SELECT
    TABLE_NAME           AS taula,
    COLUMN_NAME          AS columna,
    CONSTRAINT_NAME      AS nom_clau,
    REFERENCED_TABLE_NAME  AS taula_referenciada,
    REFERENCED_COLUMN_NAME AS columna_referenciada
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'transactions'
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

# DANA Luk transaction_user_id
-- Per Verificar  esquema de estrella
-- >   diagrama (en Workbench: Database -> Reverse Engineer)


-- Recompte de registres per taula
SELECT 'american_users' AS taula, COUNT(*) AS registres FROM american_users
UNION ALL SELECT 'european_users',  COUNT(*) FROM european_users

UNION ALL SELECT 'companies',       COUNT(*) FROM companies

UNION ALL SELECT 'company',       COUNT(*) FROM company
UNION ALL SELECT 'credit_card',    COUNT(*) FROM credit_card

UNION ALL SELECT 'credit_cards',    COUNT(*) FROM credit_cards
UNION ALL SELECT 'transactions',    COUNT(*) FROM transactions

UNION ALL SELECT 'transaction',    COUNT(*) FROM transaction
UNION ALL SELECT 'products',        COUNT(*) FROM products
UNION ALL SELECT 'product',        COUNT(*) FROM product
UNION ALL SELECT 'card_status',        COUNT(*) FROM card_status
UNION ALL SELECT 'user',        COUNT(*) FROM user ;


/* EXERCICI 9 ==============================================================================================================================
   Subconsulta: usuaris amb MÉS DE 80 transaccions (mínim 2 taules) */

-- 🟣 Solució amb european_users + transaction (taula original professor) -- SUBQUERY

SELECT    u.id,    u.name,    u.surname,    u.country,
    (SELECT COUNT(*) FROM transaction t WHERE t.user_id = u.id) AS num_transaccions
FROM european_users u
WHERE u.id IN (
    SELECT t.user_id    FROM transaction t
    GROUP BY t.user_id    HAVING COUNT(*) > 80)
ORDER BY num_transaccions DESC;
-- R. 4 rows. (id =185)  Molly Gilliam (United Kingdom, London) -> 110 transaccions
# EUROPEAN id = 185 / Molly
# (credit_card id CcU-3568 / user_id  185 
#TRANSACTIONS = card_id CcU-3568



-- 🟣 Solució ampliada  european_users + transactions (CSV Ex.8):
-- Mostra total gastat i número de transaccions per usuaris amb >80 transaccions
SELECT u.id            AS usuari_id,    u.name          AS nom,    u.surname       AS cognom,    u.country       AS pais,
    -- subconsulta per comptar les transaccions
    (SELECT COUNT(*)      FROM transactions t      WHERE t.user_id = u.id) AS num_transaccions,
    
    (SELECT SUM(t.amount)     FROM transactions t     WHERE t.user_id = u.id) AS total_gastat
FROM european_users u
WHERE u.id IN (    SELECT t.user_id    FROM transactions t    GROUP BY t.user_id    HAVING COUNT(t.id) > 80)
ORDER BY num_transaccions DESC;


/* # INTENT: Filtra i dona només els IDs de les targetes que tenen +80 transaccions en total :
SELECT 
    cc.id AS targeta_id, 
    cc.user_id AS usuari_propietari, 
    t.amount, 
    t.business_id,
    recompte.total_transaccions -- 
FROM credit_cards cc
JOIN transactions t ON cc.id = t.card_id
JOIN (
    SELECT sub_t.card_id, COUNT(*) AS total_transaccions
    FROM transactions sub_t
    GROUP BY sub_t.card_id
    HAVING COUNT(*) > 80
) recompte ON cc.id = recompte.card_id;# R. 376 Rows */


/* EXERCICI 10 ==============================================================================================================================
   Mitjana (Media-Average) d'AMOUNT per IBAN a la companyia Donec Ltd (mínim 2 taules) */

-- Solució amb JOIN (taules CSV Ex.8: transactions + credit_cards)
-- Utilitzo INNER JOIN perquè només m'interessen targetes que existeixin a ambdues taules

SELECT     cc.id AS targeta_id,     cc.user_id AS usuari_propietari, 
    t.business_id,    cc.iban,
    COUNT(t.id) AS num_transaccions,       
    ROUND(AVG(t.amount), 3) AS avg_amount,
    ROUND(SUM(t.amount), 2) AS total_amount
FROM transactions t JOIN credit_cards cc ON t.card_id = cc.id
WHERE t.business_id = (    SELECT company_id FROM companies WHERE company_name = 'Donec Ltd')     AND t.declined = 0
GROUP BY     cc.id,     cc.user_id,     t.business_id,     cc.iban ORDER BY avg_amount DESC; # 367 rows

-- ..........:
SELECT     cc.iban,    COUNT(t.id) AS num_transacciones,
    ROUND(AVG(t.amount), 2) AS media_amount,
    ROUND(SUM(t.amount), 2) AS total_amount
FROM transaction t JOIN credit_card cc ON t.credit_card_id = cc.id
WHERE t.company_id = (SELECT id FROM company WHERE company_name = 'Donec Ltd') AND t.declined = 0
GROUP BY cc.iban ORDER BY media_amount DESC;  # 370 rows

# -----------

USE transactions;

-- credit_card ya existeix, nomes fegir que falta en transaction
-- (transaction -> credit_card .... credit_card_ibfk_1)
-- Verificar FK cap a company

-- FK: transaction -> company (si no existe)
ALTER TABLE transaction
ADD FOREIGN KEY (company_id) REFERENCES company(id);
SELECT COUNT(*) FROM transaction 
WHERE user_id NOT IN (SELECT id FROM user);

ALTER TABLE card_status
ADD FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);


-- Vincular credit_card -> transaction
ALTER TABLE transaction
ADD FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);


-- FK: transaction -> user (si no existe)  
ALTER TABLE transaction
ADD FOREIGN KEY (user_id) REFERENCES user(id);


-- Verificar las 3 relaciones del diagrama
SELECT
    TABLE_NAME           AS taula,
    COLUMN_NAME          AS columna_fk,
    REFERENCED_TABLE_NAME  AS taula_referenciada
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'transactions'
  AND TABLE_NAME = 'transaction'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
  

-- ===========================================================================================================================================================
--  NIVELL 2
-- ===========================================================================================================================================================


/* N2.1 EXERCICI 1 ===========================================================================================================================
   5 dies amb la quantitat MÉS GRAN INGRESSOS Vendes */

/* ANY_VALUE() en consultas con GROUP BY - permitir seleccionar columnas que no están agrupadas. 
que devuelva cualquier valor arbitrario del grupo y que acepte la ambigüedad, evitando así el error de modo estricto ONLY_FULL_GROUP_BY */
# DATE + AMOUNT

--  DIES MES VENTUS EVER - Venta Global ¿?:
SELECT
    DATE(t.timestamp)       AS data,
    COUNT(t.id) AS num_transacciones,
    ROUND(SUM(t.amount), 2) AS total_ingressos
FROM transaction t WHERE t.declined = 0
GROUP BY DATE(t.timestamp) ORDER BY total_ingressos DESC  LIMIT 5;


/*'2022-12-13','Donec Ltd','46','14337.44'
'2019-11-18','Augue Foundation','49','13591.32'
'2023-02-20','Egestas Nunc Sed Limited','41','13332.59'
'2017-12-20','Sed LLC','41','13318.43'
'2019-03-18','Amet Faucibus Ut Foundation','42','12680.95' */

/*SELECT
    DATE(t.timestamp)       AS data,
    -- ANY_VALUE(c.company_name) AS empresa_top, # puc treure
    -- COUNT(t.id)             AS num_transaccions, # puc treure
    ROUND(SUM(t.amount), 2) AS total_ingressos
FROM transaction t
-- JOIN company c ON t.company_id = c.id #
WHERE t.declined = 0
GROUP BY DATE(t.timestamp) ORDER BY total_ingressos DESC LIMIT 5;*/

/*'2022-12-13','Donec Ltd','46','14337.44'
'2019-11-18','Augue Foundation','49','13591.32'
'2023-02-20','Egestas Nunc Sed Limited','41','13332.59'
'2017-12-20','Sed LLC','41','13318.43'
'2019-03-18','Amet Faucibus Ut Foundation','42','12680.95'*/

-- (5 millors Ventes Empresa en UN dia AMB EL NOM EMPRESA ): no cal Danna

SELECT
    DATE(t.timestamp)       AS data,
    c.company_name          AS empresa,
    -- COUNT(t.id)             AS num_transaccions, # ho puc treure
    ROUND(SUM(t.amount), 2) AS total_ingressos
FROM transaction t
JOIN company c ON t.company_id = c.id WHERE t.declined = 0
GROUP BY DATE(t.timestamp), c.company_name
ORDER BY total_ingressos DESC LIMIT 5;

/*'2024-12-02','Eget Ipsum Ltd','6','3398.40'
'2019-03-19','Ac Fermentum Incorporated','6','3149.04'
'2017-12-20','Nulla Integer Vulputate Corp.','4','2774.04'
'2017-12-20','Viverra Donec Foundation','5','2773.35'
'2020-12-11','Ac Fermentum Incorporated','8','2717.76'*/





/* N2.2 EXERCICI 2 ===========================================================================================================================
   Empreses amb transaccions entre 350-400€ Euros en dates específiques . Ordena els resultats de MAJOR a MENOR quantitat.
   -- Presenta el NOM, TELÈFON, PAÍS, 		DATA i AMOUNT . 29 d'abril del 2015, 		20 de juliol del 2018 i 		13 de març del 2024. 
   MITJANA DE VENDES per cada PAÍS.
-- c.id, c.company_name, c.phone, c.country
-- t.company_id, t.timestamp, t.amount*/

SELECT c.company_name, c.phone, c.country,
	DATE(t.timestamp) AS data_Exc, 			t.amount
FROM transaction t
INNER JOIN company c ON t.company_id = c.id
WHERE t.amount BETWEEN 350 AND 400	AND DATE(t.timestamp) IN ('2015-04-29','2018-07-20' , '2024-03-13') AND t.declined = 0 
ORDER BY t.amount DESC; # R. sin Condicion Precio, 70 rows. 	Con limite Valor, 8 rows


-- 'Aliquam PC', '01 45 73 52 16', 'Germany', '2024-03-13', '399.84'
-- 'Aliquam PC', '01 45 73 52 16', 'Germany', '2024-03-13', '388.29' # MATEIXA DATA 
-- 'Auctor Mauris Vel LLP', '08 09 28 74 14', 'United States', '2024-03-13', '353.75'
-- 'Auctor Mauris Vel LLP', '08 09 28 74 14', 'United States', '2018-07-20', '399.51'	# SAME COMPANY, DIF DATE

-- com havia + Transaccio  en 1 mateix dia :
SELECT c.company_name,c.phone,c.country,
    DATE(t.timestamp)        AS data_exac,
    COUNT(t.id)              AS num_transaccions,
    SUM(t.amount)  AS total_amount
FROM transaction t
INNER JOIN company c ON t.company_id = c.id
WHERE t.amount BETWEEN 350 AND 400		  AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13') AND t.declined = 0 
GROUP BY c.company_name, c.phone, c.country, DATE(t.timestamp) ORDER BY total_amount DESC;


/*FROM transaction t
JOIN company c ON t.company_id = c.id
WHERE t.amount BETWEEN 350 AND 400
  AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')  AND t.declined = 0
ORDER BY t.amount DESC;*/





/* N2.3 EXERCICI 3 ===========================================================================================================================
   Quantitat de transaccions per empresa: ≥400 o / <400 */

SELECT    c.company_name,c.country,
    COUNT(t.id) AS num_transaccions,
    CASE WHEN COUNT(t.id) >= 400 THEN 'Igual o més de 400' # 'Alt (>=400)'
        ELSE 'Menys de 400'
    END AS capacitat_operativa
FROM transaction t
JOIN company c ON t.company_id = c.id WHERE t.declined = 0
GROUP BY c.id, c.company_name, c.country ORDER BY num_transaccions DESC; # 100 rows (101 + la Random...) 



# 'Ac Fermentum Incorporated','Germany','2400','Igual o més de 400'
# 'Lorem Eu Incorporated','Canada','378','Menys de 400'
# 'Dui Quis Institute','New Zealand','400','Igual o més de 400'

--  declined=0 tabla
-- SELECT COUNT(*) FROM transaction WHERE declined = 0; #99763 '1')
-- SELECT COUNT(*) FROM transactions WHERE declined = 0; #99112 --> mateixes files, dades dif 

# Detectat canvi valors malgrat ser les mateixes empreses, i he detectat que si hi han canvis com el num de ACCEPTAT o no operacions (segons base dades, si el sql o CSV)

-- SI FOS amb TRANSACTIONS ( sense el Random) i no CASE 
SELECT    c.company_name,    c.country,
    COUNT(t.id) AS num_transaccions,
    (COUNT(t.id) >= 400) AS es_mes_400
FROM transactions t
JOIN companies c 
    ON t.business_id = c.company_id
WHERE t.declined = 0
GROUP BY c.company_id, c.company_name, c.country
ORDER BY num_transaccions DESC;

# 'Ac Fermentum Incorporated','Germany','2387','1'
# 'Lorem Eu Incorporated','Canada','374','0'
# 'Dui Quis Institute','New Zealand','397','0'



/* N2.4 EXERCICI 4 ===========================================================================================================================
   Elimina el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD */

-- ️ ATENCIÓ:
DELETE FROM transaction
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Verificació (0 rows)
SELECT * FROM transaction
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';


/* N2.5 EXERCICI 5 ===========================================================================================================================
   Crear vista VistaMarketing (CREATE VIEW)
NOM de la companyia, TELÈFON de contacte, PAÍS de residència i la MITJANA DE COMPRA realitzada per cadascuna. 
Ordenant les dades de MAJOR a MENOR mitjana de compra.*/

CREATE OR REPLACE VIEW VistaMarketing AS
SELECT
    c.company_name           AS nom_companyia,
    c.phone                  AS telefon,
    c.country                AS pais,
    ROUND(AVG(t.amount), 2)  AS mitjana_compra
FROM transaction t
JOIN company c ON t.company_id = c.id
WHERE t.declined = 0
GROUP BY c.id, c.company_name, c.phone, c.country;

-- Consultar la vista
SELECT * FROM VistaMarketing
ORDER BY mitjana_compra DESC;


-- ===========================================================================================================================================================
-- NIVELL 3
-- ===========================================================================================================================================================

/* N3.1 EXERCICI 1 ===========================================================================================================================
   Taula d'estat de targetes: activa / inactiva . En base 3 ultimes Transaccions */

CREATE TABLE IF NOT EXISTS card_status AS

-- prueba :

SELECT    cc.id AS credit_card_id,
    CASE
        WHEN SUM(CASE WHEN t.declined = 0 THEN 1 ELSE 0 END) = 0 THEN 'inactiva'
        ELSE 'activa'
    END AS estat
FROM credit_card cc
JOIN (
    SELECT t1.credit_card_id, t1.declined
    FROM transaction t1  -- (subconsulta... where:)
    WHERE (
        SELECT COUNT(*)
        FROM transaction t2
        WHERE t2.credit_card_id = t1.credit_card_id          AND t2.timestamp >= t1.timestamp) 		<= 3
) t ON cc.id = t.credit_card_id
GROUP BY cc.id;

-- Quantes targetes actives?
SELECT estat, COUNT(*) AS num_targetes
FROM card_status
GROUP BY estat;
# 'activa', '4996' 
# 'inactiva', '5'...  CcU-9999¿?

/* N3.2 EXERCICI 2 ===========================================================================================================================
   Taula products + nombre de vegades venut cada producte 
id	product_name	price	colour	weight	warehouse_id	category	brand	cost	launch_date */

# Mirar : doc @S2_Estructura

/*-- Nombre de vegades venut cada producte
-- Nota: product_ids a transactions pot contenir múltiples IDs separats per comes 
-- Carregar dades: SOURCE / LOAD DATA LOCAL INFILE products.csv
*/

# fet via Terminal, LUK, @  doc @S2_Estructura
# SELECT product_name, price FROM products WHERE category = 'Sports' 


/* (14.8 String Functions and Operators)
FIND_IN_SET(x, lista) busca un valor x dentro de una lista separada por COMAS.
REPLACE = Limpia espacio
---
JOIN expressión logica
JOIN no equi-join (xq no es =... sino una funció) */

SELECT    p.id,    p.product_name,    p.category,
    COUNT(t.id) AS vegades_venut
FROM products p
	LEFT JOIN transactions t ON FIND_IN_SET(p.id, REPLACE(t.product_ids, ', ', ',')) > 0
WHERE t.declined = 0 OR t.id IS NULL
GROUP BY p.id, p.product_name, p.category
ORDER BY vegades_venut DESC;


-- Visualitzacio exemple per mi:
SELECT 
    p.id,
    p.product_name,
    p.category
FROM products p
WHERE FIND_IN_SET(p.id, '2,5,9') > 0;

