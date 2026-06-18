CREATE OR REPLACE FUNCTION evaluate_patient_risk(p_patient_id INT)
RETURNS VARCHAR AS $$
DECLARE
    cur_allergies CURSOR FOR
        SELECT severity FROM allergy WHERE patient_id = p_patient_id;
    v_allergy_rec RECORD;
    v_risk_score INT := 0;
    v_history_count INT := 0;
    v_result VARCHAR;
BEGIN
    PERFORM 1 FROM patient WHERE patient_id = p_patient_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Patient with ID % does not exist.', p_patient_id;
    END IF;

    SELECT COUNT(*) INTO v_history_count FROM medical_history WHERE patient_id = p_patient_id;
    v_risk_score := v_risk_score + (v_history_count * 5);

    OPEN cur_allergies;
    LOOP
        FETCH cur_allergies INTO v_allergy_rec;
        EXIT WHEN NOT FOUND;

        IF v_allergy_rec.severity = 'Life-threatening' THEN
            v_risk_score := v_risk_score + 20;
        ELSIF v_allergy_rec.severity = 'High' THEN
            v_risk_score := v_risk_score + 10;
        ELSIF v_allergy_rec.severity = 'Moderate' THEN
            v_risk_score := v_risk_score + 5;
        ELSE
            v_risk_score := v_risk_score + 1;
        END IF;
    END LOOP;
    CLOSE cur_allergies;

    IF v_risk_score >= 30 THEN
        v_result := 'Critical Risk';
    ELSIF v_risk_score >= 15 THEN
        v_result := 'Moderate Risk';
    ELSE
        v_result := 'Low Risk';
    END IF;

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in patient risk evaluation: %', SQLERRM;
        RETURN 'Evaluation Failed';
END;
$$ LANGUAGE plpgsql;