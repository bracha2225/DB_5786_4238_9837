-- PostgreSQL Schema for Patient Management System

-- 1. PATIENT TABLE
CREATE TABLE patient (
    patient_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT check_dob CHECK (date_of_birth <= CURRENT_DATE),
    CONSTRAINT check_gender CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say'))
);

COMMENT ON TABLE patient IS 'Stores core demographic information for hospital patients.';
COMMENT ON COLUMN patient.patient_id IS 'Unique identifier for each patient (Auto-incrementing).';
COMMENT ON COLUMN patient.gender IS 'Standardized gender field with CHECK constraint.';


-- 2. ADMISSION TABLE
CREATE TABLE admission (
    admission_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    discharge_date TIMESTAMP,
    reason TEXT NOT NULL,
    
    -- Constraints
    CONSTRAINT fk_patient FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
    CONSTRAINT check_dates CHECK (discharge_date IS NULL OR discharge_date >= admission_date)
);

COMMENT ON TABLE admission IS 'Tracks patient hospital stays and discharge status.';
COMMENT ON COLUMN admission.discharge_date IS 'Can be NULL if the patient is currently admitted.';


-- 3. EMERGENCY_CONTACT TABLE
CREATE TABLE emergency_contact (
    contact_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    
    -- Constraints
    CONSTRAINT fk_patient_contact FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE
);

COMMENT ON TABLE emergency_contact IS 'Contact information for people to notify in case of emergency.';


-- 4. MEDICAL_HISTORY TABLE
CREATE TABLE medical_history (
    history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INT NOT NULL,
    condition_name VARCHAR(255) NOT NULL, -- Renamed from 'condition' as it is often a reserved word
    diagnosis_date DATE NOT NULL,
    notes TEXT,
    
    -- Constraints
    CONSTRAINT fk_patient_history FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE
);

COMMENT ON TABLE medical_history IS 'Historical record of previous diagnoses and medical conditions.';


-- 5. ALLERGY TABLE
CREATE TABLE allergy (
    allergy_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INT NOT NULL,
    allergy_name VARCHAR(100) NOT NULL,
    severity VARCHAR(50) NOT NULL,
    notes TEXT,
    
    -- Constraints
    CONSTRAINT fk_patient_allergy FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
    CONSTRAINT check_severity CHECK (severity IN ('Low', 'Moderate', 'High', 'Life-threatening'))
);

COMMENT ON TABLE allergy IS 'List of patient allergies and their severity levels.';


-- 6. INSURANCE TABLE
CREATE TABLE insurance (
    insurance_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INT NOT NULL,
    provider_name VARCHAR(150) NOT NULL,
    policy_number VARCHAR(50) NOT NULL,
    coverage_type VARCHAR(100),
    expiration_date DATE NOT NULL,
    
    -- Constraints
    CONSTRAINT fk_patient_insurance FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
    CONSTRAINT unique_policy UNIQUE (policy_number)
);

COMMENT ON TABLE insurance IS 'Patient insurance coverage details and policy validity.';