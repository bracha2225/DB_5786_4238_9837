-- ============================================================
-- Fichier : insertTables.sql
-- Description : Population des données pour le système hospitalier
-- Méthode : generate_series et random SQL
-- ============================================================

-- 1. PATIENTS (20 000+ lignes)
TRUNCATE TABLE patient RESTART IDENTITY CASCADE;
INSERT INTO patient (first_name, last_name, date_of_birth, gender, phone, email, address)
SELECT 
    'FirstName_' || i,
    'LastName_' || i,
    '1950-01-01'::date + (random() * 25000)::int % ('2024-01-01'::date - '1950-01-01'::date),
    (ARRAY['Male', 'Female', 'Other', 'Prefer not to say'])[ (i % 4) + 1 ],
    '05' || (10000000 + i),
    'patient' || i || '@hospital.com',
    i || ' Medical Center Dr, Suite ' || (i % 100)
FROM generate_series(1, 20500) AS i;

-- 2. ADMISSIONS (Version "Voyageur du Temps" corrigée)
INSERT INTO admission (patient_id, admission_date, discharge_date, reason)
SELECT 
    (random() * 20499 + 1)::int,
    start_date,
    -- On ajoute entre 1 heure et 10 jours à la date d'entrée
    start_date + (random() * 10 * interval '1 day') + (random() * 24 * interval '1 hour'),
    (ARRAY['Routine checkup', 'Severe flu', 'Broken bone', 'Surgery recovery', 'Cardiac observation'])[ (i % 5) + 1 ]
FROM (
    SELECT 
        i, 
        '2022-01-01'::timestamp + (random() * 3000 * interval '1 hour') AS start_date
    FROM generate_series(1, 21000) AS i
) AS sub;


-- 3. EMERGENCY_CONTACT (500+ lignes)
INSERT INTO emergency_contact (patient_id, name, relationship, phone)
SELECT 
    i, -- On donne un contact aux 600 premiers patients
    'Contact_' || i,
    (ARRAY['Spouse', 'Parent', 'Sibling', 'Child', 'Friend'])[ (i % 5) + 1 ],
    '05' || (90000000 - i)
FROM generate_series(1, 600) AS i;

-- 4. MEDICAL_HISTORY (500+ lignes)
INSERT INTO medical_history (patient_id, condition_name, diagnosis_date, notes)
SELECT 
    (random() * 20499 + 1)::int,
    (ARRAY['Hypertension', 'Type 2 Diabetes', 'Asthma', 'Chronic Migraine', 'Anxiety'])[ (i % 5) + 1 ],
    '2015-01-01'::date + (random() * 3000)::int,
    'Patient history record #' || i
FROM generate_series(1, 700) AS i;

-- 5. ALLERGY (500+ lignes)
INSERT INTO allergy (patient_id, allergy_name, severity, notes)
SELECT 
    (random() * 20499 + 1)::int,
    (ARRAY['Penicillin', 'Peanuts', 'Latex', 'Pollen', 'Shellfish'])[ (i % 5) + 1 ],
    (ARRAY['Low', 'Moderate', 'High', 'Life-threatening'])[ (i % 4) + 1 ],
    'Allergy noted during intake #' || i
FROM generate_series(1, 550) AS i;

-- 6. INSURANCE (500+ lignes)
INSERT INTO insurance (patient_id, provider_name, policy_number, coverage_type, expiration_date)
SELECT 
    i, -- On assure les 550 premiers patients
    (ARRAY['Aetna', 'BlueCross', 'Cigna', 'UnitedHealth'])[ (i % 4) + 1 ],
    'POL-' || (100000 + i),
    (ARRAY['Basic', 'Premium', 'Gold'])[ (i % 3) + 1 ],
    '2026-01-01'::date + (random() * 500)::int
FROM generate_series(1, 550) AS i;