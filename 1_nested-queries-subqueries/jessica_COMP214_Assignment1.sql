/*
COMP214 - SUMMER 2024 - ASSIGNMENT 1

1. List probation officers that have less than average criminals with sentences
assigned (not nulls) with them.
*/

WITH avg_sentences AS (
    SELECT AVG(criminal_count) AS avg_criminals
    FROM (
        SELECT COUNT(*) AS criminal_count
        FROM sentences
        WHERE criminal_id IS NOT NULL
        GROUP BY prob_id
    ) avg_criminals_subquery
)
SELECT po.prob_id, 
       po.first || ' ' || po.last AS prob_officer_name,
       COUNT(s.criminal_id) AS num_sentences_assigned,
       avg_sentences.avg_criminals
FROM prob_officers po
LEFT JOIN sentences s ON po.prob_id = s.prob_id AND s.criminal_id IS NOT NULL,
avg_sentences
GROUP BY po.prob_id, po.first, po.last, avg_sentences.avg_criminals
HAVING COUNT(s.criminal_id) < avg_sentences.avg_criminals;

/*
-- 2. List criminal(s) that Crime charges court fee is greater than avg per crime.
*/

SELECT ci.FIRST || ' ' || ci.LAST AS criminal_name,
       SUM(NVL(cc.court_fee, 0)) AS total_court_fee,
       ROUND((SELECT AVG(NVL(court_fee, 0))
        FROM crime_charges),2) AS avg_court_fee_per_crime
FROM criminals ci
JOIN crimes cr ON ci.criminal_id = cr.criminal_id
JOIN crime_charges cc ON cc.crime_id = cr.crime_id
GROUP BY ci.FIRST, ci.LAST
HAVING SUM(NVL(cc.court_fee, 0)) > 
       (SELECT AVG(NVL(court_fee, 0))
        FROM crime_charges);

/*
3. List Officers that have greater or equal avg number of crimes assigned.
*/

SELECT o.officer_id, 
       o.first || ' ' || o.last AS officer_name, 
       COUNT(co.crime_id) AS num_crimes_assigned,
       (SELECT AVG(crime_count)
        FROM (SELECT COUNT(*) AS crime_count
              FROM crime_officers
              GROUP BY officer_id)) AS avg_crimes_per_officer
FROM officers o
LEFT JOIN crime_officers co ON o.officer_id = co.officer_id
GROUP BY o.officer_id, o.first, o.last
HAVING COUNT(co.crime_id) >= 
       (SELECT AVG(crime_count)
        FROM (SELECT COUNT(*) AS crime_count
              FROM crime_officers
              GROUP BY officer_id));

/*
4. List criminals that have greater or equal amount paid in crime charges per
crime.
*/
                      
WITH TotalAmounts AS (
    SELECT cco.code_description, NVL(SUM(cc.amount_paid), 0) AS total_amount_paid
    FROM crime_charges cc
    JOIN crime_codes cco ON cc.crime_code = cco.crime_code
    GROUP BY cco.code_description
)
SELECT ci.first || ' ' || ci.last AS criminal_name, 
    NVL(cc.amount_paid,0) AS amount_paid, cco.code_description AS crime,
    ta.total_amount_paid AS total_amount_paid_per_crime
FROM criminals ci
JOIN crimes ce ON ci.criminal_id = ce.criminal_id
JOIN crime_charges cc ON ce.crime_id = cc.crime_id
JOIN crime_codes cco ON cc.crime_code = cco.crime_code
JOIN TotalAmounts ta ON cco.code_description = ta.code_description
GROUP BY ci.first, ci.last,cc.amount_paid, cco.code_description, ta.total_amount_paid
HAVING NVL(SUM(cc.amount_paid), 0) >= ta.total_amount_paid;

/*
5. List criminals that have equal to max sentences issued.
*/

SELECT c.criminal_id, c.first, c.last, sentence_counts.max_sentences
FROM criminals c
JOIN (
    SELECT criminal_id, COUNT(*) AS num_sentences
    FROM sentences
    GROUP BY criminal_id
) sc ON c.criminal_id = sc.criminal_id
JOIN (
    SELECT MAX(sentence_count) AS max_sentences
    FROM (
        SELECT COUNT(*) AS sentence_count
        FROM sentences
        GROUP BY criminal_id
    ) max_sentence_counts
) sentence_counts ON sc.num_sentences = sentence_counts.max_sentences;


