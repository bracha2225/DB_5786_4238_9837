CREATE OR REPLACE PROCEDURE archive_expired_insurance(p_years_old INT)
AS $$
DECLARE
    v_archived_count INT;
BEGIN
    INSERT INTO insurance_archive (insurance_id, patient_id, provider_name, policy_number, expiration_date)
    SELECT insurance_id, patient_id, provider_name, policy_number, expiration_date
    FROM insurance
    WHERE expiration_date < CURRENT_DATE - make_interval(years => p_years_old);

    GET DIAGNOSTICS v_archived_count = ROW_COUNT;

    DELETE FROM insurance
    WHERE expiration_date < CURRENT_DATE - make_interval(years => p_years_old);

    RAISE NOTICE 'Archived % expired insurance policies successfully.', v_archived_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Archiving failed: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;