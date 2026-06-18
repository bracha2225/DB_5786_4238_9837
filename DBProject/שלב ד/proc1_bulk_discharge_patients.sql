CREATE OR REPLACE PROCEDURE bulk_discharge_patients(p_reason_keyword VARCHAR)
AS $$
DECLARE
    v_adm_rec RECORD;
    v_update_count INT := 0;
BEGIN
    IF p_reason_keyword IS NULL OR p_reason_keyword = '' THEN
        RAISE EXCEPTION 'Reason keyword cannot be empty.';
    END IF;

    FOR v_adm_rec IN
        SELECT admission_id FROM admission
        WHERE discharge_date IS NULL AND reason ILIKE '%' || p_reason_keyword || '%'
    LOOP
        UPDATE admission
        SET discharge_date = NOW()
        WHERE admission_id = v_adm_rec.admission_id;

        v_update_count := v_update_count + 1;
    END LOOP;

    RAISE NOTICE 'Successfully discharged % patients.', v_update_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Transaction failed. Error: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;