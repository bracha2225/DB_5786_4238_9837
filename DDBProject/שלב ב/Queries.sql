-- ============================================================
-- File: Queries.sql
-- Phase 2 – Selection & Modification Queries
-- Database: Hospital Management System (Patient Management)
-- ============================================================

-- ************************************************************
-- SECTION A: 4 "DOUBLE" SELECT QUERIES (2 versions each)
-- ************************************************************

-- ============================================================
-- DOUBLE QUERY 1 
-- Description: Retrieves patients with 'Life-threatening' allergies and counts their total hospital admissions.
-- This helps identify high-risk patients with frequent hospital usage.

-- VERSION A:
SELECT p.first_name, p.last_name, COUNT(a.admission_id) AS total_admissions
FROM patient p
JOIN allergy al ON p.patient_id = al.patient_id
LEFT JOIN admission a ON p.patient_id = a.patient_id
WHERE al.severity = 'Life-threatening'
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY total_admissions DESC;

-- VERSION B:
SELECT p.first_name, p.last_name,
       (SELECT COUNT(*) FROM admission a WHERE a.patient_id = p.patient_id) AS total_admissions
FROM patient p
WHERE p.patient_id IN (SELECT al.patient_id FROM allergy al WHERE al.severity = 'Life-threatening')
ORDER BY total_admissions DESC;

-- COMPARISON: Version A is generally better. 
-- Version A uses standard JOINs which allows the SQL Optimizer to process the data in bulk. 
-- Version B uses a correlated subquery in the SELECT clause, which might execute the count 
-- calculation separately for every single row, leading to poor performance on large datasets.


-- ============================================================
-- DOUBLE QUERY 2 
-- Description: Identifies patients admitted in 2023 whose insurance policies are set to expire in 2026.
-- This is useful for administrative staff to update billing information for recent patients.

-- VERSION A:
SELECT p.first_name, p.last_name, i.provider_name, i.expiration_date
FROM patient p
JOIN admission ad ON p.patient_id = ad.patient_id
JOIN insurance i ON p.patient_id = i.patient_id
WHERE EXTRACT(YEAR FROM ad.admission_date) = 2023
  AND EXTRACT(YEAR FROM i.expiration_date) = 2026
ORDER BY i.expiration_date ASC;

-- VERSION B:
SELECT p.first_name, p.last_name, i.provider_name
FROM patient p
JOIN insurance i ON p.patient_id = i.patient_id
WHERE EXTRACT(YEAR FROM i.expiration_date) = 2026
AND EXISTS (
    SELECT 1 FROM admission ad 
    WHERE ad.patient_id = p.patient_id 
    AND ad.admission_date BETWEEN '2023-01-01' AND '2023-12-31'
);

-- COMPARISON: Version B is better for efficiency.
-- In Version A, if a patient was admitted 10 times in 2023, the JOIN will create 10 rows for that 
-- patient before grouping or filtering. Version B uses EXISTS, which stops searching as soon 
-- as it finds the first matching admission, reducing unnecessary data processing.


-- ============================================================
-- DOUBLE QUERY 3 
-- Description: Lists patients who have more than one recorded medical condition in their history.
-- This targets patients with complex medical profiles (multi-morbidity).

-- VERSION A:
SELECT p.first_name, p.last_name, COUNT(mh.history_id) AS nb_conditions
FROM patient p
JOIN medical_history mh ON p.patient_id = mh.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(mh.history_id) > 1;

-- VERSION B:
WITH PatientCounts AS (
    SELECT patient_id, COUNT(*) as cnt
    FROM medical_history
    GROUP BY patient_id
)
SELECT p.first_name, p.last_name, pc.cnt
FROM patient p
JOIN PatientCounts pc ON p.patient_id = pc.patient_id
WHERE pc.cnt > 1;

-- COMPARISON: Version A is slightly better for simple queries.
-- While Version B (using a CTE) is very readable and great for complex logic, Version A 
-- allows the engine to perform the JOIN and the aggregation in a single execution plan 
-- without materializing a temporary result set.


-- ============================================================
-- DOUBLE QUERY 4 
-- Description: Calculates the average stay duration (in days) for patients born before 1980.
-- This provides insight into how long older demographics stay in the hospital.

-- VERSION A:
SELECT p.first_name, p.last_name, 
       AVG(EXTRACT(DAY FROM (discharge_date - admission_date))) AS avg_stay_days
FROM patient p
JOIN admission a ON p.patient_id = a.patient_id
WHERE EXTRACT(YEAR FROM p.date_of_birth) < 1980
  AND a.discharge_date IS NOT NULL
GROUP BY p.patient_id, p.first_name, p.last_name;

-- VERSION B:
SELECT p.first_name, p.last_name, sub.avg_stay
FROM patient p,
LATERAL (
    SELECT AVG(EXTRACT(DAY FROM (a.discharge_date - a.admission_date))) as avg_stay
    FROM admission a
    WHERE a.patient_id = p.patient_id
) sub
WHERE EXTRACT(YEAR FROM p.date_of_birth) < 1980 AND sub.avg_stay IS NOT NULL;

-- COMPARISON: Version A is better.
-- Version A follows the standard relational model. Version B uses a LATERAL JOIN, 
-- which essentially acts like a loop, calculating the average for each patient one by one. 
-- Version A processes the admissions table as a whole block, which is much faster.


-- ************************************************************
-- SECTION B: 4 ADDITIONAL SELECT QUERIES
-- ************************************************************

-- ============================================================
-- QUERY 5
-- Description: Lists emergency contacts for all patients who are currently admitted (not yet discharged).
-- Essential for floor nurses and hospital administration.
SELECT p.first_name AS patient_name, ec.name AS contact_person, ec.relationship, ec.phone
FROM patient p
JOIN admission a ON p.patient_id = a.patient_id
JOIN emergency_contact ec ON p.patient_id = ec.patient_id
WHERE a.discharge_date IS NULL
ORDER BY p.last_name;

-- ============================================================
-- QUERY 6
-- Description: Provides a statistical breakdown of hospital admissions grouped by Year and Month.
-- Used by management to track hospital occupancy trends over time.
SELECT 
    EXTRACT(YEAR FROM admission_date) AS annee,
    EXTRACT(MONTH FROM admission_date) AS mois,
    COUNT(*) AS total_admissions
FROM admission
GROUP BY annee, mois
ORDER BY annee DESC, mois DESC;

-- ============================================================
-- QUERY 7
-- Description: Finds patients who have no recorded allergies AND no recorded medical history.
-- Used to identify patients with "clean" records or potential missing data.
SELECT p.first_name, p.last_name, p.email
FROM patient p
LEFT JOIN allergy al ON p.patient_id = al.patient_id
LEFT JOIN medical_history mh ON p.patient_id = mh.patient_id
WHERE al.allergy_id IS NULL AND mh.history_id IS NULL;

-- ============================================================
-- QUERY 8
-- Description: Retrieves insurance and policy details for patients admitted for "Surgery".
-- Used by the billing department to verify coverage for expensive procedures.
SELECT p.first_name, p.last_name, i.provider_name, i.policy_number, a.reason
FROM patient p
JOIN insurance i ON p.patient_id = i.patient_id
JOIN admission a ON p.patient_id = a.patient_id
WHERE a.reason LIKE '%Surgery%'
ORDER BY p.last_name;