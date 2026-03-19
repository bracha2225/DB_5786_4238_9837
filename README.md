# 🏥 Hospital Management System - Phase 1

**Team Members:** Guila Czerniewicz (2045605), Braha Kalaghi (325464238)
**System Name:** Antigravity Hospital Suite  
**Selected Module:** Patient Management & Medical Administration


---
## 📋 Table of Contents

1. [Introduction](#1-introduction)
2. [UI Prototypes (AI Generated)](#2-ui-prototypes-ai-generated)
3. [Database Design & Diagrams](#3-database-design--diagrams)
4. [Design Decisions & Architecture](#4-design-decisions--architecture)
5. [Data Population Methods](#5-data-population-methods)
6. [Backup and Restoration](#6-backup-and-restoration)
7. [How to Run the Project](#7-how-to-run-the-project)
---

## 📖 1. Introduction

### System Overview
This system is strictly bounded to the **medical administration of a human hospital environment**. It is designed to manage the core entities involved in patient care, ensuring seamless tracking of medical history, insurance coverage, and hospital admissions. The system provides a centralized database to handle high-volume data (**20,000+ records**) while maintaining strict relational integrity.

---

## ✨ Core Functionalities

* **👤 Patient Management:** Centralized registration of patients, including demographics, unique identification, and contact details.
* **🏨 Admission Tracking:** Managing hospital stays, recording admission/discharge dates, and reasons for hospitalization with automated consistency checks.
* **📂 Medical History & Diagnostics:** Persistent logging of pre-existing conditions and past diagnoses associated with specific patients.
* **⚠️ Allergy & Risk Management:** Tracking patient sensitivities (Allergies) with severity levels to ensure clinical safety during treatment.
* **📄 Insurance & Policy Administration:** Managing insurance provider details, policy numbers, and coverage expiration dates to facilitate billing administration.

> **Note:** This module focuses on administrative and clinical data and does not handle external operations such as financial transactions, staff payroll, or pharmacy inventory management.

---
## 🎨 2. UI Prototypes (AI Generated)
To visualize the end product, we used Google AI Studio in a Top-Down approach to generate the initial frontend screens. These mockups dictate the data we need to store and retrieve.

<img width="1225" height="731" alt="image" src="https://github.com/user-attachments/assets/c477cc1d-0391-4424-9655-e4218f4b0ac0" />
>Patient List Page: A central dashboard that displays all registered patients in a searchable table with quick actions for viewing, editing, or deleting records.

<img width="1242" height="728" alt="image" src="https://github.com/user-attachments/assets/eec79d50-fc3c-4b42-8816-45badc89e0ee" />
>Add Patient Page: A comprehensive registration form used to capture a new patient's personal details, contact information, and residential address.

<img width="1240" height="737" alt="image" src="https://github.com/user-attachments/assets/428e559e-d74b-4108-9318-765bf5890b19" />
>Patient Details Page: An all-in-one profile view that summarizes a patient's identity, emergency contacts, insurance status, and recent medical history.

<img width="1241" height="730" alt="image" src="https://github.com/user-attachments/assets/a0abe2c9-4031-4473-8fdb-f1941b4aca82" />
>Insurance Information Page: A dedicated management area for viewing, adding, and updating a patient's insurance providers, policy numbers, and coverage dates.

<img width="1236" height="742" alt="image" src="https://github.com/user-attachments/assets/27c91a9b-1f7b-4750-9169-ac9c76e8dd52" />
>Medical Information Page: A detailed clinical record screen focused on tracking patient allergies, chronic conditions, and primary emergency contact details.

---
## 📐 3. Database Design & Diagrams

Our database is designed to reflect the administrative and clinical realities of a modern hospital environment, following standard relational design principles. The schema is normalized to at least 3NF (Third Normal Form) to ensure data integrity, eliminate redundancy, and support high-volume transactions for thousands of patient records.

---

## 🔗 Entity Relationship Diagram (ERD)
<img width="4512" height="1902" alt="erdplus (8)" src="https://github.com/user-attachments/assets/47720a20-ad6e-4700-96d6-a4a8583fa5c3" />

---

## 📊 Data Structure Diagram (DSD)
---
<img width="4512" height="1902" alt="erdplus (9)" src="https://github.com/user-attachments/assets/13a5dfc7-ff56-4272-b437-7eaf05a8dd88" />


---

## 🏗️ 4. Design Decisions & Architecture

> Our database is designed to reflect the administrative and clinical realities of a modern hospital environment, following standard relational design principles. The schema is **normalized to at least 3NF** (Third Normal Form) to ensure data integrity, eliminate redundancy, and support high-volume transactions for thousands of patient records.



### Key Architectural Decisions:

* **Normalization (3NF):** We utilized dedicated relational structures to resolve complex dependencies. For instance, separate tables for `Allergy` and `Medical_History` are linked to the `Patient` entity via Foreign Keys. This structure prevents data duplication and update anomalies, ensuring that a single patient can have multiple clinical records without redundant demographic data.

* **Data Integrity (Constraints):** We implemented strict relational constraints to guarantee "Clean Data":
    * **NOT NULL:** Applied to critical fields like `last_name`, `admission_date`, and `policy_number`.
    * **UNIQUE:** Enforced on sensitive fields such as `email` and insurance `policy_number` to prevent identity or billing conflicts.
    * **Check Constraints:** Custom logic (e.g., `check_dates`) ensures that a `discharge_date` cannot occur before an `admission_date`.
    * **Referential Integrity:** Cascading deletes (`ON DELETE CASCADE`) are used so that if a patient record is removed, all associated admissions and histories are cleaned up, preventing "orphaned" data.



* **Optimized Data Types:** Appropriate PostgreSQL types were selected for precision and performance:
    * **TIMESTAMPTZ:** Used for admissions to track exact time across different time zones.
    * **DATE:** Used for `date_of_birth` to ensure efficient indexing and age calculations.
    * **VARCHAR/TEXT:** Carefully balanced to handle variable-length notes while optimizing storage for standard fields.



---

## 📥 5. Data Population Methods

To ensure a robust testing environment and simulate a real-world hospital load, the database was populated with realistic mock data using three distinct strategies. We successfully met the requirement of generating at least **500 records** for standard clinical tables and over **20,000 records** for high-volume entities like `Patient` and `Admission`.

### Method 1: Database Scripting & SQL Logic (`generate_series`)

We utilized advanced PostgreSQL scripting—leveraging the `generate_series()` function combined with `ARRAY` constants and `random()` logic—to programmatically generate large-scale datasets directly within the SQL engine. 

<img width="1059" height="459" alt="image" src="https://github.com/user-attachments/assets/c3ce6b01-2506-4bbc-866f-37c19a9825b2" />


---
### Method 2: External Data Generators (Mockaroo)

For specialized clinical data requiring realistic medical terminology (e.g., `allergy_name`, `severity` levels, and clinical notes), we utilized **Mockaroo** to generate high-fidelity test data. 

This approach allowed us to:
* **Simulate Clinical Diversity:** Populating the `Allergy` table with 500+ records of common allergens (e.g., Penicillin, Latex, Peanuts) and varying severity levels from 'Low' to 'Life-threatening'.
* **Consistent Formatting:** Exporting the data directly as **SQL INSERT statements** to ensure seamless integration with our PostgreSQL schema and maintaining strict relational mapping to our existing `patient_id` values.

This method proved highly efficient for meeting the **20,000+ row requirement** for the `Admission` table. By using this approach, we were able to:
* **Maintain Logical Consistency:** Ensuring that every admission record is linked to a valid `patient_id`.
* **Enforce Temporal Logic:** Using interval arithmetic (`start_date + random interval`) to guarantee that discharge dates always occur after admission dates, thereby respecting our database constraints.

<img width="1751" height="881" alt="image" src="https://github.com/user-attachments/assets/15cd4c78-d4dc-4d04-897c-f68e2eff7b6e" />
<img width="1640" height="740" alt="Capture d&#39;écran 2026-03-19 142028" src="https://github.com/user-attachments/assets/6b27b15d-a164-4cb8-bd0e-5be202a4ccf4" />

### Method 3: Administrative Data (CSV Import)

For the **Insurance** table, we utilized **Mockaroo** to generate a realistic dataset of 550+ records.

* **Strategy:** Generated unique `policy_number` values to satisfy the database's `UNIQUE` constraint and ensure zero data conflicts during ingestion.
* **Process:** Imported via pgAdmin 4 using the **Import/Export Tool**.
* **Key Detail:** We enabled the **Header** option and excluded the `insurance_id` (Identity) column to allow PostgreSQL to handle primary key generation automatically.

<img width="1882" height="923" alt="image" src="https://github.com/user-attachments/assets/dd319b79-0346-43c3-af6a-d75545f77f68" />


---
## 🔄 6. Backup and Restoration
---

### 1. Backup Creation
* **Filename:** `backup_19_03_2026.backup`
* **Format:** PostgreSQL Custom Format (compressed).
* **Method:** Generated via **pgAdmin 4 Backup tool** and exported using the **Storage Manager**.
* **Content:** Complete database state, including schemas, relational constraints, and 20,500+ patient records.

### 2. Portability & Validation
To verify the backup's integrity, a restoration test was conducted:
1. Created a clean database instance (`hospital_test_db`).
2. Performed a **Restore** operation using the generated `.backup` file.
3. **Verification:** Executed `SELECT count(*) FROM patient;` to confirm all 20,500 records were successfully recovered.

> **Result:** The backup is fully functional and ready to be deployed on any PostgreSQL 16+ instance.

-----

## 🚀 7. How to Run the Project

### Prerequisites
* **Docker Desktop** installed and running.

### Step 1: Launch the Environment
1. Open a terminal in the project folder and run:
   ```bash
   docker-compose up -d

### Step 2: Connect to pgAdmin
1. Open your browser and go to: `http://localhost:5050`
2. **Login with:**
   * **Email:** `-`
   * **Password:** `-` 
3. **Add a new server connection:**
   * **Name:** `Antigravity-DB`
   * **Host:** `db`
   * **Port:** `5432`
   * **Username:** `-`
   * **Password:** `-`
   * **Maintenance database:** `-`
   **All the elements to fill are defined in ".env"**

### Step 3: Import Insurance Data (CSV)
1. In the pgAdmin sidebar, navigate to: 
   **Servers** → **Antigravity-DB** → **Databases** → **basnat** → **Schemas** → **public** → **Tables** → **insurance**.
2. Right-click on the **insurance** table → **Import/Export Data...**
3. **Configure the import:**
   * **Import/Export:** `Import`
   * **Filename:** Select `db-files/insurance.csv`
   * **Format:** `CSV`
   * **Header:** `Yes`
   * **Delimiter:** `,`
4. **Important:** In the **Columns** tab, **uncheck** `insurance_id`.
5. Click **OK** to import ~550 insurance records.

### Step 4: Run Data Scripts
1. In pgAdmin, open the **Query Tool** (Tools → Query Tool).
2. Click the **Open File** (📂) button and run these scripts in order:
   * `db-files/03-insert-table.sql` (Inserts 20,500+ Patients and Admissions).
   * `db-files/04-mockaroo-allergy.sql` (Inserts allergy data).
3. Click **Execute** (▶) or press **F5** for each.

### Step 5: Verify the Data
1. Open the **Query Tool** again.
2. Open and run the file: `db-files/06-select-all.sql`.
3. Verify that all tables are populated correctly.

## Summary of Data Sources
<img width="1024" height="559" alt="image" src="https://github.com/user-attachments/assets/5a96aef7-8e05-4ec8-8859-3d3728dea295" />

## 🛠️ Tech Stack & Population Methods
* **Database:** PostgreSQL (Dockerized)
* **GUI:** pgAdmin 4
