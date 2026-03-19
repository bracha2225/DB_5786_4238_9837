-- ============================================================
-- Fichier : insert_hospital_data.sql
-- Description : Population des données via la méthode generate_series (Méthode 1)
-- 
-- Tables à 20 000+ lignes : PATIENT, ADMISSION
-- Tables à 500+ lignes : EMERGENCY_CONTACT, MEDICAL_HISTORY, ALLERGY, INSURANCE
-- ============================================================

-- 1. PATIENT (20 000+ lignes)
--FICHIER CSV
/*INSERT INTO patient (first_name, last_name, date_of_birth, gender, phone, email, address)
SELECT 
    'FirstName_' || i,
    'LastName_' || i,
    '1950-01-01'::date + (random() * 25000)::int % ('2024-01-01'::date - '1950-01-01'::date),
    (ARRAY['Male', 'Female', 'Other', 'Prefer not to say'])[ (i % 4) + 1 ],
    '05' || (10000000 + i),
    'patient' || i || '@hospital.com',
    'Street ' || i || ', City ' || (i % 100)
FROM generate_series(1, 20500) AS i;
*/
-- 2. ADMISSION (20 000+ lignes)
-- On lie les admissions aux patients créés ci-dessus (ID de 1 à 20500)
INSERT INTO admission (patient_id, admission_date, discharge_date, reason)
SELECT 
    (random() * 20499 + 1)::int, -- ID aléatoire d'un patient existant
    '2020-01-01'::timestamp + (random() * 2000 * interval '1 day'), -- Date d'entrée
    NULL, -- Sera mis à jour juste après pour la logique de sortie
    'Reason for admission #' || i
FROM generate_series(1, 21000) AS i;

-- Mise à jour pour que certains patients soient sortis (discharge_date > admission_date)
UPDATE admission 
SET discharge_date = admission_date + (random() * 15 * interval '1 day')
WHERE admission_id % 2 = 0; -- Sortir 50% des patients pour le réalisme


-- 3. EMERGENCY_CONTACT (500+ lignes)
INSERT INTO emergency_contact (patient_id, name, relationship, phone)
SELECT 
    i, -- Un contact pour chacun des 550 premiers patients
    'ContactName_' || i,
    (ARRAY['Spouse', 'Parent', 'Sibling', 'Child', 'Friend'])[ (i % 5) + 1 ],
    '05' || (90000000 - i)
FROM generate_series(1, 550) AS i;


-- 4. MEDICAL_HISTORY (500+ lignes)
INSERT INTO medical_history (patient_id, condition_name, diagnosis_date, notes)
SELECT 
    (random() * 20499 + 1)::int,
    (ARRAY['Hypertension', 'Diabetes Type 2', 'Asthma', 'Chronic Back Pain', 'Anxiety'])[ (i % 5) + 1 ],
    '2010-01-01'::date + (random() * 5000)::int,
    'Note for condition ' || i
FROM generate_series(1, 600) AS i;


-- 5. ALLERGY (500+ lignes)
-- MOCKAROO SQL


-- 6. INSURANCE (500+ lignes)
INSERT INTO insurance (patient_id, provider_name, policy_number, coverage_type, expiration_date)
SELECT 
    i, -- On assure les 550 premiers patients
    (ARRAY['Aetna', 'BlueCross', 'Cigna', 'UnitedHealth'])[ (i % 4) + 1 ],
    'POL-' || (100000 + i),
    (ARRAY['Basic', 'Premium', 'Gold', 'Family'])[ (i % 4) + 1 ],
    '2026-01-01'::date + (random() * 1000)::int
FROM generate_series(1, 550) AS i;
