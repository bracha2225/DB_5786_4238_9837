DO $$
DECLARE
    v_risk_status VARCHAR;
BEGIN
    RAISE NOTICE '--- Running Main Program 1 ---';

    CALL bulk_discharge_patients('Flu');

    v_risk_status := evaluate_patient_risk(1);
    RAISE NOTICE 'Risk Analysis for Patient 1: %', v_risk_status;

    RAISE NOTICE '--- Main Program 1 Finished ---';
END $$;