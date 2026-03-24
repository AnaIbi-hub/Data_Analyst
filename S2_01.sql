-- Sprint SQL - Anàlisi de transaccions  
-- Autor: Ana Ibáñez Esplugues
-- Descripció: Consultes sobre vendes i empreses

#NIVELL 1
#EXERCICI 2 - JOINS
-- Utilitzant JOIN realitzaràs les següents consultes:
-- Llistat dels països que estan generant vendes.
SELECT DISTINCT company.country
FROM company
JOIN transaction ON company.id = transaction.company_id;

-- Des de quants països es generen les vendes.
SELECT COUNT(DISTINCT company.country)
FROM company
JOIN transaction ON company.id = transaction.company_id;

-- Identifica la companyia amb la mitjana més gran de vendes.
SELECT company.company_name, AVG(transaction.amount) as vendes
FROM transaction
JOIN company ON company.id = transaction.company_id
GROUP BY transaction.company_id, company.company_name
ORDER BY vendes DESC
LIMIT 1;

#EXERCICI 3 (SENSE JOINS, SOLS SUBQUERIES)
-- Mostra totes les transaccions realitzades per empreses d'Alemanya.
SELECT *
FROM transaction
WHERE transaction.company_id IN (select company.id
								from company
                                where company.country = "Germany");

# Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT company.company_name
FROM company
WHERE EXISTS (SELECT 1
              FROM transaction
              WHERE transaction.company_id = company.id
              AND transaction.amount > (SELECT AVG(transaction.amount)
			                            FROM transaction));

# Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
SELECT *
FROM company
WHERE NOT EXISTS (SELECT *
              FROM transaction
              WHERE transaction.company_id = company.id);

#NIVELL 2
#EXERCICI 1
-- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
-- Mostra la data de cada transacció juntament amb el total de les vendes.

SELECT DATE(transaction.timestamp) AS dia, SUM(transaction.amount) AS total
FROM transaction
GROUP BY dia
ORDER BY total DESC
LIMIT 5;

#EXERCICI 2 
-- Quina és la mitjana de vendes per país? Presenta els resultats ordenats de major a menor mitjà.
-- Necessito la mitjana de l'import, necessito group by per pais, així que hauré de fer un join segur
SELECT AVG(amount) as mitjana_vendes, country 
FROM transaction
JOIN company ON company.id = transaction.company_id
GROUP BY country
ORDER BY mitjana_vendes DESC;

#EXERCICI 3
-- En la teva empresa, es planteja un nou projecte per a llançar algunes campanyes publicitàries
-- per a fer competència a la companyia "Non Institute". 
-- Per a això, et demanen la llista de totes les transaccions realitzades per empreses que estan situades en el mateix país 
-- que aquesta companyia.

-- Non Institute és una empresa de United Kingdom.
-- Mostrar transaccions realitzades per empreses de United Kingdom que NO siguin Non Institute
-- Mostra el llistat aplicant JOIN i subconsultes.
SELECT company.company_name, transaction.id, company.country
FROM transaction
JOIN company ON company.id = transaction.company_id
WHERE company.country = (SELECT company.country
						 FROM company
                         WHERE company.company_name LIKE '%Non Institute%')
AND company.company_name != 'Non Institute';

-- Mostra el llistat aplicant solament subconsultes.
SELECT transaction.id
FROM transaction
WHERE EXISTS (SELECT 1
			  FROM company
			  WHERE company.id = transaction.company_id
              AND company.country = 'United Kingdom'
              AND company.company_name != 'Non Institute');
              
#NIVELL 3
-- Exercici 1
-- Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions 
-- amb un valor comprès entre 350 i 400 euros i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 
-- i 13 de març del 2024. Ordena els resultats de major a menor quantitat.

SELECT company.company_name, company.phone, company.country, date(transaction.timestamp) as data_transaccio, transaction.amount as quantitat
FROM transaction
JOIN company ON company.id = transaction.company_id
WHERE transaction.amount BETWEEN 350 AND 400
AND date(transaction.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY quantitat DESC;

#Exercici 2 
-- Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, 
-- per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses, 
-- però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis 
-- si tenen més de 400 transaccions o menys.

-- quantitat transaccions de cada empresa, tenen més de 400 transaccions 

SELECT count(transaction.id) as quantitat_transaccions, company.company_name, IF(count(transaction.id) > 400, 'SI', 'NO') as mes_de_400
FROM transaction 
JOIN company ON company.id = transaction.company_id
GROUP BY company.company_name;