CREATE TABLE insurance_archive (
    archive_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    insurance_id INT,
    patient_id INT,
    provider_name VARCHAR(150),
    policy_number VARCHAR(50),
    expiration_date DATE,
    archived_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admission_audit_logs (
    log_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    admission_id INT,
    patient_id INT,
    total_stay_hours NUMERIC,
    logged_at TIMESTAMPTZ
);