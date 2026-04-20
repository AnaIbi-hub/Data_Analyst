-- NIVELL 1
-- Descàrrega els arxius CSV, estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, 
-- almenys 4 taules de les quals puguis realitzar les següents consultes:

SET GLOBAL local_infile = 1;

-- Ara, creem la bbdd sprint 4
CREATE DATABASE IF NOT EXISTS sprint4;

#CREEM PRIMER LES TAULES DE DIMENSIÓ PERQUÈ NO DONGUI ERROR
#CREEM COMPANY
CREATE TABLE companies (
    company_id VARCHAR(50) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    country VARCHAR(100),
    website VARCHAR(255)
);
#CARREGUEM COMPANY
LOAD DATA LOCAL INFILE 'C:/Users/a-iba/Downloads/sprint_4/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

#COMPROVEM QUE, EFECTIVAMENT, ESTÀ CARREGAT
SELECT *
FROM companies;

#CREEM CREDITS_CARDS
CREATE TABLE credit_cards (
    id VARCHAR(50) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(50),
    pan VARCHAR(50),
    pin VARCHAR(10),
    cvv INT,
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date VARCHAR(20) 
);

#CARREGUEM CREDIT_CARDS
LOAD DATA LOCAL INFILE 'C:/Users/a-iba/Downloads/sprint_4/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

#COMPROVEM QUE, EFECTIVAMENT, ESTÀ CARREGAT
SELECT *
FROM credit_cards;

#ARA ANEM A AGRUPAR EL CSV DE AMERICAN USERS I EUROPEAN USERS
#PRIMER, CREEM LA TAULA PER AGRUPAR ELS DOS CSV.
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    birth_date VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(50),
    address VARCHAR(255)
);

# CARREGUEM EL CSV DELS CLIENTS AMERICANS
LOAD DATA LOCAL INFILE 'C:/Users/a-iba/Downloads/sprint_4/american_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# CARREGUEM EL CSV DELS CLIENTS EUROPEUS
LOAD DATA LOCAL INFILE 'C:/Users/a-iba/Downloads/sprint_4/european_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

#INTEGRAREM UNA NOVA COLUMNA QUE ES DIRÀ REGIÓ, PERQUÈ ES SÀPIGA QUINA INFORMACIÓ VE D'ON
ALTER TABLE users ADD COLUMN region VARCHAR(20);

#Ara li posarem la clausula perquè cada fila tingui una regió o una altra
UPDATE users 
SET region = CASE 
    WHEN country IN ('United States', 'Canada') THEN 'Amèrica'
    ELSE 'Europa' 
END;

#FILTREM PER SABER SI LA INFORMACIÓ DE AMBDOS ESTÀ RECOLLIDA
SELECT *
FROM users
WHERE country = 'United States';

SELECT *
FROM users
WHERE country = 'Germany';

#Ara canviem la birth_date a un format SQL, perquè no ens dongui problemes
UPDATE users SET birth_date = STR_TO_DATE(birth_date, '%b %d, %Y');
ALTER TABLE users MODIFY COLUMN birth_date DATE;

#Comprovem que surt bé tant la birthdate com la nova regió
SELECT *
FROM users;

#ARA CREEM LA TAULA DE FETS
CREATE TABLE transactions (
    id VARCHAR(50) PRIMARY KEY,
    card_id VARCHAR(50),
    business_id VARCHAR(50),
    timestamp TIMESTAMP,    
    amount DECIMAL(10,2),    
    declined TINYINT(1),     
    product_ids VARCHAR(255),
    user_id INT,             
    lat DECIMAL(10,8),
    longitude DECIMAL(11,8)
);

#CARREGUEM LA TAULA DE FETS, QUE ESTÀ SEPARADA PER ';' EN COMPTE DE ','
LOAD DATA LOCAL INFILE 'C:/Users/a-iba/Downloads/sprint_4/transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


SELECT *
FROM transactions;

#PER ÚLTIM, AFEGIR LES FK A LA TAULA PER GARANTITZAR L'INTEGRITAT REFERENCIAL
ALTER TABLE transactions
  ADD CONSTRAINT fk_users FOREIGN KEY (user_id) REFERENCES users(id),
  ADD CONSTRAINT fk_cards FOREIGN KEY (card_id) REFERENCES credit_cards(id),
  ADD CONSTRAINT fk_companies FOREIGN KEY (business_id) REFERENCES companies(company_id);
  
-- EXERCICI 1
-- Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.
#Ens sembla molt més neta la query sense subconsulta
SELECT users.name, users.surname, COUNT(transactions.id) as num_transaccions
FROM users
JOIN transactions ON users.id = transactions.user_id
GROUP BY users.name, users.surname
HAVING num_transaccions > 80
ORDER BY num_transaccions DESC;
 
 #Ara la fem amb subconsulta (que considerem pitjor però necessària per l'exercici), 
 # i sols posem els usuaris perquè no sabem fer que surti el num_transaccions en aquest cas
SELECT users.name, users.surname 
FROM users
WHERE EXISTS (SELECT 1 
			 FROM transactions
             WHERE transactions.user_id = users.id  
             GROUP BY transactions.user_id 
			 HAVING COUNT(*) > 80);
             
-- Exercici 2. Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.
# Fem servir una subconsulta al WHERE en lloc de filtrar directament pel nom al JOIN per evitar 
# duplicats si existissin dues empreses amb el mateix nom.

SELECT companies.company_name, credit_cards.iban, ROUND(AVG(transactions.amount), 2) AS mitjana_despesa 
FROM transactions
JOIN credit_cards ON credit_cards.id = transactions.card_id
JOIN companies ON companies.company_id = transactions.business_id
WHERE companies.company_id = (SELECT company_id 
                              FROM companies 
							  WHERE company_name = 'Donec Ltd')
GROUP BY credit_cards.iban, companies.company_name
ORDER BY mitjana_despesa DESC;

-- NIVELL 2. 
-- Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes transaccions han estat declinades 
-- aleshores és inactiu, si almenys una no és rebutjada aleshores és actiu. Partint d’aquesta taula respon:
-- Quantes targetes estan actives?

CREATE TABLE estat_targetes AS
SELECT sub.card_id AS targeta,
    CASE 
        WHEN SUM(sub.declined) = 3 THEN 'inactiu'
        ELSE 'actiu'
    END AS estat
FROM (SELECT transactions.card_id, transactions.declined,
	  ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS fila
	  FROM transactions) AS sub
WHERE sub.fila <= 3
GROUP BY sub.card_id;

SELECT *
FROM estat_targetes;

-- Quantes targetes estan actives?
SELECT COUNT(estat_targetes.estat) as num_targetes_actives
FROM estat_targetes
WHERE estat_targetes.estat = 'actiu';

#NIVELL 3
-- Crea una taula amb la qual puguem unir les dades del nou arxiu products.csv amb la base de dades creada,
-- tenint en compte que des de transaction tens product_ids.

#Primer, creem la taula products.
CREATE TABLE products (
id INT PRIMARY KEY,
product_name VARCHAR(255),
price VARCHAR(50),
colour VARCHAR(50),
weight DECIMAL(10,2),
warehouse_id VARCHAR(50)
);

#Carreguem la taula
LOAD DATA LOCAL INFILE 'C:/Users/a-iba/Downloads/sprint_4/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

#Ara, hem de crear la taula intermitja entre transactions i products per resoldre la relació N:M.
#Utilitzem FIND_IN_SET per separar els IDs de la llista de productes i filtrem les transaccions no rebutjades.
CREATE TABLE transaction_products AS
SELECT transactions.id AS transaccio, products.id AS producte
FROM products
JOIN transactions ON FIND_IN_SET(products.id, REPLACE(transactions.product_ids, ' ', '')) > 0
WHERE transactions.declined = 0; 

#Un cop creada la taula i normalitzades les dades, establim les claus primàries i foranes
#per garantir la integritat referencial que no podíem posar al principi.
ALTER TABLE transaction_products
ADD PRIMARY KEY (transaccio, producte),
ADD CONSTRAINT fk_transaccio FOREIGN KEY (transaccio) REFERENCES transactions(id),
ADD CONSTRAINT fk_producte FOREIGN KEY (producte) REFERENCES products(id);

#Fem alguna que les dades surten correctament
SELECT *
FROM transaction_products
WHERE producte = '3';

-- Exercici 1: Nombre de vegades que s'ha venut cada producte
#Fem el COUNT sobre la taula intermèdia per saber les vendes d'èxit de cada ID de producte.
SELECT products.product_name as nom_producte, transaction_products.producte as id_producte, COUNT(*) AS total_vendes
FROM transaction_products
JOIN products ON products.id = transaction_products.producte
GROUP BY transaction_products.producte
ORDER BY total_vendes DESC;

