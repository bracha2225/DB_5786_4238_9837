ALTER TABLE patient
ADD CONSTRAINT check_email_at CHECK (email LIKE '%@%');
--
ALTER TABLE insurance
ADD CONSTRAINT check_insurance_valid_date CHECK (expiration_date > '2000-01-01');

ALTER TABLE emergency_contact
ADD CONSTRAINT check_relationship_type CHECK (relationship IN ('Parent', 'Spouse', 'Child', 'Sibling', 'Friend', 'Other'));