-- הוספת עמודת הקישור לטבלת המטופלים
ALTER TABLE patients.patient
ADD COLUMN staffid INT;

-- הגדרת מפתח זר פיזי המקשר בין הסכמות
ALTER TABLE patients.patient
ADD CONSTRAINT fk_patient_staff
FOREIGN KEY (staffid) REFERENCES staffschema.staff(staffid)
ON DELETE RESTRICT;