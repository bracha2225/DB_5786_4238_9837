-- ============================================================
-- File: selectAll.sql
-- Description: FINAL CHECK FOR ALL TABLES
-- ============================================================

SELECT * FROM patient LIMIT 10;
SELECT * FROM admission LIMIT 10;
SELECT * FROM emergency_contact LIMIT 10;
SELECT * FROM medical_history LIMIT 10;
SELECT * FROM allergy LIMIT 10;
SELECT * FROM insurance LIMIT 10;

-- ============================================================
-- VERIFICATION OF THE 20,000 ROWS REQUIREMENT
-- ============================================================
SELECT 'patient' AS table_name, count(*) AS total_rows FROM patient
UNION ALL
SELECT 'admission', count(*) FROM admission
UNION ALL
SELECT 'allergy', count(*) FROM allergy;