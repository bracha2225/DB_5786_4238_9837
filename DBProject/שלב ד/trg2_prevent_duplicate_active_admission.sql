CREATE OR REPLACE FUNCTION trg_check_active_admissions()
RETURNS TRIGGER AS $$
DECLARE
    v_active_count INT;
BEGIN
    SELECT COUNT(*) INTO v_active_count
    FROM admission
    WHERE patient_id = NEW.patient_id AND discharge_date IS NULL;

    IF v_active_count > 0 THEN
        RAISE EXCEPTION 'Patient ID % is already currently admitted.', NEW.patient_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_duplicate_active_admission
BEFORE INSERT ON admission
FOR EACH ROW
EXECUTE FUNCTION trg_check_active_admissions();