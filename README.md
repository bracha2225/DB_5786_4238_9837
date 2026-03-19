# 🏥 Hospital Management System - Phase 1

**Team Members:** Guila Czerniewicz (2045605), Braha Kalaghi  
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
---
## 🏗️ 4. Design Decisions & Architecture
---
## 📥 5. Data Population Methods
---
## 🔄 6. Backup and Restoration
---

## 🛠️ Tech Stack & Population Methods
* **Database:** PostgreSQL (Dockerized)
* **GUI:** pgAdmin 4
* **Volume:** 20,000+ entries generated via Python & SQL Scripts.
