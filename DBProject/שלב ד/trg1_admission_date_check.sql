CREATE OR REPLACE FUNCTION trg_audit_admission_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.admission_date > NOW() THEN
        RAISE EXCEPTION 'Admission date cannot be set in the future.';
    END IF;

    IF OLD.discharge_date IS NULL AND NEW.discharge_date IS NOT NULL THEN
        INSERT INTO admission_audit_logs(admission_id, patient_id, total_stay_hours, logged_at)
        VALUES(OLD.admission_id, OLD.patient_id, EXTRACT(EPOCH FROM (NEW.discharge_date - OLD.admission_date))/3600, NOW());
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_admission_date_check
BEFORE UPDATE ON admission
FOR EACH ROW
EXECUTE FUNCTION trg_audit_admission_update();