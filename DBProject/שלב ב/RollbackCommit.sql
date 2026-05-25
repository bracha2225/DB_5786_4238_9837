S--roll back

SELECT name FROM emergency_contact WHERE contact_id = 1;

BEGIN;

UPDATE emergency_contact SET name = 'NOM_TEST_ERREUR' WHERE contact_id = 1;

SELECT name FROM emergency_contact WHERE contact_id = 1;

ROLLBACK;

SELECT name FROM emergency_contact WHERE contact_id = 1;

-- commit
SELECT patient_id, address FROM patient WHERE patient_id = 1;

BEGIN;

UPDATE patient
SET address = '123 New Permanent Street'
WHERE patient_id = 1;

COMMIT;

SELECT patient_id, address FROM patient WHERE patient_id = 1;