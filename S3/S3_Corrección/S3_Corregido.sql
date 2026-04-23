#NIVELL 1

#Exercici 1 
#PRIMER, CREEM LA TAULA
CREATE TABLE credit_card (
    id VARCHAR(20) PRIMARY KEY,
    iban VARCHAR(100),
    pan VARCHAR(20),
    pin VARCHAR(10),
    cvv VARCHAR(10),
    expiring_date VARCHAR(20)
);

#Creem la relació PK i FK amb la taula de fets, transactions. Primer comprovem que tota la informació consta
SELECT DISTINCT credit_card_id
FROM transaction
WHERE credit_card_id NOT IN (
    SELECT id FROM credit_card
);
SHOW CREATE TABLE transaction;
#Com faltaria una id, l'afegim per tal de que no ens doni error
INSERT INTO credit_card (id)
VALUES ('CcU-9999');

#Ara ja executem la relació entre PK i FK de les dues taules
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_creditcard
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);

#Exercici 2
#El departament de Recursos Humans ha identificat un error en el número de compte associat a la targeta de crèdit amb ID CcU-2938. 
#La informació que ha de mostrar-se per a aquest registre és: TR323456312213576817699999. Recorda mostrar que el canvi es va realitzar.

-- Actualitzem l’IBAN de la targeta específica utilitzant WHERE per afectar només un registre
UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

-- Verifiquem el canvi mostrant únicament els camps rellevants
SELECT id, iban
FROM credit_card
WHERE id = 'CcU-2938';


#Exercici 3
-- En la taula "transaction" ingressa una nova transacció amb la següent informació:
-- L'empresa "b-9999" no existeix a la taula mare company, així que primerament l'hem d'afegir perquè no ens doni error
INSERT INTO credit_card (id) VALUES ('CcU-9999');
INSERT INTO company (id) VALUES ('b-9999');
INSERT INTO user (id) VALUES (9999);

INSERT INTO transaction (
    id,
    credit_card_id,
    company_id,
    user_id,
    lat,
    longitude,
    amount,
    declined
)
VALUES (
    '108B1D1D-5B23-A76C-55EF-C568E49A99DD',
    'CcU-9999',
    'b-9999',
    9999,
    829.999,
    -117.999,
    111.11,
    0
);

SELECT *
FROM transaction
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


#Exercici 4
-- Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. Recorda mostrar el canvi realitzat.
ALTER TABLE credit_card
DROP COLUMN pan;

DESCRIBE credit_card;

#NIVELL 2
#Exercici 1
-- Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.
DELETE FROM transaction
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

SELECT *
FROM transaction
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

#Exercici 2
-- La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives. 
-- S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions. 
-- Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació: 
-- Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. 
-- Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.

CREATE OR REPLACE VIEW VistaMarketing AS
SELECT company.company_name AS Nom_Empresa, company.phone AS telefon, company.country as Pais_Empresa, ROUND(AVG(transaction.amount), 2) AS mitjana_compra_companyia
FROM company
JOIN transaction ON company.id = transaction.company_id
GROUP BY company.id;

SELECT *
FROM VistaMarketing
ORDER BY mitjana_compra_companyia DESC;


#Exercici 3
-- Filtra la vista VistaMarketing per a mostrar només les companyies que tenen el seu país de residència en "Germany"
SELECT *
FROM VistaMarketing
WHERE Pais_Empresa = 'Germany';


#NIVELL 3
#Exercici 1
-- Executem els scripts proporcionats per crear i omplir la taula user
-- (estructura_dades_user i dades_introduir_user)
-- Eliminem la FK si ja existia per poder modificar els tipus sense errors
ALTER TABLE transaction
DROP FOREIGN KEY fk_transaction_user;

-- Canviem el nom de la taula user a data_user segons el diagrama
RENAME TABLE user TO data_user;

-- Modifiquem el tipus de la clau primària de data_user
ALTER TABLE data_user
MODIFY id INT;

-- Canviem el nom de la columna email a personal_email
ALTER TABLE data_user
CHANGE email personal_email VARCHAR(150);

-- Ajustem el tipus de user_id perquè coincideixi amb data_user.id (INT)
ALTER TABLE transaction
MODIFY user_id INT;

-- Hem d'eliminar també la FK que ja existia a transaction per poder aplicar el canvi que farem a continuació
ALTER TABLE transaction
DROP FOREIGN KEY fk_transaction_creditcard;

-- Ajustem el tipus de credit_card_id segons el diagrama
ALTER TABLE transaction
MODIFY credit_card_id VARCHAR(20);

-- Ajustem el tipus de company_id segons el diagrama
ALTER TABLE transaction
MODIFY company_id VARCHAR(20);

-- Modifiquem la taula credit_card segons el nou model
ALTER TABLE credit_card
MODIFY id VARCHAR(20);

ALTER TABLE credit_card
MODIFY iban VARCHAR(50);

ALTER TABLE credit_card
MODIFY pin VARCHAR(4);

ALTER TABLE credit_card
MODIFY cvv INT;

-- Afegim la nova columna fecha_actual
ALTER TABLE credit_card
ADD fecha_actual DATE;

-- Eliminem la columna website de la taula company
ALTER TABLE company
DROP COLUMN website;

-- Comprovem si hi ha user_id a transaction que no existeixen a data_user
SELECT DISTINCT user_id
FROM transaction
WHERE user_id NOT IN (
    SELECT id FROM data_user
);

-- Afegim els valors que falten per garantir la integritat referencial (si cal)
INSERT INTO data_user (id)
VALUES (9999);

-- Tornem a crear la relació entre transaction i data_user
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_user
FOREIGN KEY (user_id)
REFERENCES data_user(id);

-- Tornem a crear la relació entre transaction i credit_card
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_creditcard
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);

-- Fem que es vegin totes les taules després de haver fet els canvis
DESCRIBE data_user;
DESCRIBE transaction;
DESCRIBE credit_card;
DESCRIBE company;

#Exercici 2
-- L'empresa també us demana crear una vista anomenada "InformeTecnico" que contingui la informació donada.
-- Mostra els resultats de la vista, ordena els resultats de forma descendent en funció de la variable ID de transacció.
-- Assegureu-vos d'incloure informació rellevant de les taules que coneixereu i utilitzeu àlies per canviar de nom columnes segons calgui.
#ID de la transacció, Nom de l'usuari/ària, Cognom de l'usuari/ària, IBAN de la targeta de crèdit usada, Nom de la companyia de la transacció realitzada.

CREATE OR REPLACE VIEW InformeTecnico AS
SELECT transaction.id AS id_transaccio, data_user.name AS Nom_del_client, data_user.surname AS Cognom_del_client, 
credit_card.iban AS IBAN_Targeta, company.company_name AS Empresa
FROM transaction
JOIN company ON company.id = transaction.company_id
JOIN data_user ON data_user.id = transaction.user_id
JOIN credit_card ON credit_card.id = transaction.credit_card_id;

SELECT *
FROM InformeTecnico
ORDER BY id_transaccio DESC;
