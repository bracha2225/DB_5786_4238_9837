CREATE OR REPLACE VIEW patients.view_patient_medical_assignments AS
SELECT
    p.patient_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    p.date_of_birth,
    s.staffid,
    s.firstname AS staff_first_name,
    s.lastname AS staff_last_name,
    s.status AS staff_status
FROM patients.patient p
LEFT JOIN staffschema.staff s ON p.staffid = s.staffid;

SELECT * FROM patients.view_patient_medical_assignments
WHERE staff_status = 'Active';

SELECT COUNT(*) AS young_patients_with_staff
FROM patients.view_patient_medical_assignments
WHERE date_of_birth > '2000-01-01' AND staffid IS NOT NULL;


CREATE OR REPLACE VIEW staffschema.view_staff_workload AS
SELECT
    s.staffid,
    s.firstname,
    s.lastname,
    s.status,
    COUNT(p.patient_id) AS total_assigned_patients
FROM staffschema.staff s
LEFT JOIN patients.patient p ON s.staffid = p.staffid
GROUP BY s.staffid, s.firstname, s.lastname, s.status;

SELECT staffid, firstname, lastname, total_assigned_patients
FROM staffschema.view_staff_workload
WHERE total_assigned_patients > 5;

SELECT AVG(total_assigned_patients) AS average_patients_per_staff
FROM staffschema.view_staff_workload;