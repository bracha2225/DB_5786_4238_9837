CREATE OR REPLACE FUNCTION get_active_admissions(p_admission_reason_keyword VARCHAR)
RETURNS refcursor AS $$
DECLARE
    v_admission_cursor refcursor;
BEGIN
    OPEN v_admission_cursor FOR
        SELECT admission_id, patient_id, admission_date, reason
        FROM admission
        WHERE discharge_date IS NULL
          AND reason ILIKE '%' || p_admission_reason_keyword || '%'
        ORDER BY admission_date ASC;

    RETURN v_admission_cursor;
END;
$$ LANGUAGE plpgsql;