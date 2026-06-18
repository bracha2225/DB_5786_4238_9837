DO $$
DECLARE
    v_adm_cursor refcursor;
    v_id INT;
    v_pat_id INT;
    v_date TIMESTAMP;
    v_reason TEXT;
BEGIN
    RAISE NOTICE '--- Running Main Program 2 ---';

    CALL archive_expired_insurance(5);

    v_adm_cursor := get_active_admissions('Heart');

    LOOP
        FETCH v_adm_cursor INTO v_id, v_pat_id, v_date, v_reason;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Admission ID: %, Patient ID: %, Date: %, Reason: %', v_id, v_pat_id, v_date, v_reason;
    END LOOP;
    CLOSE v_adm_cursor;

    RAISE NOTICE '--- Main Program 2 Finished ---';
END $$;