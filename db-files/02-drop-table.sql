-- SQL script to drop all tables in the Patient Management System
-- Order is determined by Foreign Key dependencies to ensure smooth execution.

-- Step 1: Drop tables that contain Foreign Keys (Child Tables)
DROP TABLE IF EXISTS insurance;
DROP TABLE IF EXISTS allergy;
DROP TABLE IF EXISTS medical_history;
DROP TABLE IF EXISTS emergency_contact;
DROP TABLE IF EXISTS admission;

-- Step 2: Drop the primary table (Parent Table)
-- This table can only be dropped after the tables above are removed.
DROP TABLE IF EXISTS patient;

-- Optional: Print confirmation
-- SELECT 'All tables dropped successfully' AS status;