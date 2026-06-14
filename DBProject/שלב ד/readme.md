<div dir="rtl">
# מערכת לניהול מטופלים - שלב ד' (תכנות בסיס הנתונים - PL/pgSQL)

בשלב זה שדרגנו את בסיס הנתונים ממחסן מידע סטטי למערכת דינמית ומנוהלת על ידי לוגיקה עסקית מורכבת. השלב כולל כתיבת פונקציות, פרוצדורות וטריגרים מתקדמים בשפת PL/pgSQL המבוצעים ישירות על שרת ה-PostgreSQL בתוך הסכמה `patients`.

כדי לעמוד בדרישות הגבוהות ביותר של הפרויקט, כל התוכניות שנכתבו אינן טרוויאליות ומשלבות את האלמנטים הבאים:
* **Cursors (משתמעים ומפורשים)** למעבר שורה-אחר-שורה על נתונים.
* **החזרת Ref Cursor** דינמי.
* **פקודות DML** (עדכון, מחיקה והכנסה) מורכבות.
* **הסתעפויות (If-Else)** ולולאות מתקדמות.
* **מנגנוני חריגות (Exceptions)** לטיפול בשגיאות ומניעת קריסות.
* **שימוש ברשומות (Records)**.

---

## 🛠️ שלב 1:  הכנת התשתית (קובץ `AlterTable.sql`)

לפני הרצת הלוגיקה, עלינו להוסיף לבסיס הנתונים טבלאות תמיכה שישמשו את הטריגרים והפרוצדורות לצורך ארכוב נתונים ישנים ותיעוד פעולות (Audit Logs). 

יש להריץ קוד זה ראשון ב-Query Tool ב-pgAdmin:

```sql
-- הגדרת נתיב החיפוש לסכמה הרלוונטית
SET search_path TO patients, public;

-- 1. טבלה לארכוב פוליסות ביטוח פגות תוקף (עבור פרוצדורה 2)
CREATE TABLE insurance_archive (
    archive_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    insurance_id INT,
    patient_id INT,
    provider_name VARCHAR(150),
    policy_number VARCHAR(50),
    expiration_date DATE,
    archived_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. טבלת לוגים לתיעוד משך אשפוז של מטופלים (עבור טריגר 1)
CREATE TABLE admission_audit_logs (
    log_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    admission_id INT,
    patient_id INT,
    total_stay_hours NUMERIC,
    logged_at TIMESTAMPTZ
);

<img width="1100" height="872" alt="Capture d&#39;écran 2026-06-14 131513" src="https://github.com/user-attachments/assets/4ff59508-5018-4bf9-a5fc-f0b4d90c9a4d" />


<p align="right">

## 📑 שלב 2: פונקציות (Functions)

הפונקציות משמשות לביצוע חישובים ושליפת נתונים מורכבים (במצב קריאה בלבד) מתוך טבלאות המערכת. בשלב זה נכתבו שתי פונקציות העונות על דרישות הפרויקט.

### 2.1 הערכת סיכון רפואי במערכת (`fn_evaluate_patient_risk.sql`)
פונקציה זו מקבלת מזהה מטופל (`patient_id`), מחשבת את רמת הסיכון שלו בבית החולים על סמך כמות האבחנות הרפואיות שלו וחומרת האלרגיות שלו, ומחזירה סיווג סיכון סופי.
<br>• **אלמנטים בקוד:** קורסור מפורש (`Explicit Cursor`), לולאה (`LOOP`), תנאים (`IF-THEN-ELSE`), וטיפול בחריגות (`Exception`).

</p>

```sql
SET search_path TO patients, public;

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
    -- f. Exception Handling: בדיקה אם המטופל בכלל קיים במערכת
    PERFORM 1 FROM patient WHERE patient_id = p_patient_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Patient with ID % does not exist.', p_patient_id;
    END IF;

    -- שליפת כמות האבחנות הרפואיות מההיסטוריה
    SELECT COUNT(*) INTO v_history_count FROM medical_history WHERE patient_id = p_patient_id;
    v_risk_score := v_risk_score + (v_history_count * 5);

    -- e. לולאה על גבי קורסור מפורש (Explicit Cursor) למעבר על כל האלרגיות
    OPEN cur_allergies;
    LOOP
        FETCH cur_allergies INTO v_allergy_rec;
        EXIT WHEN NOT FOUND;
        
        -- d. הסתעפויות (Branches) על פי חומרת האלרגיה
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

    -- קביעת רמת הסיכון הסופית על סמך הציון המשוקלל
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

<img width="1127" height="825" alt="Capture d&#39;écran 2026-06-14 132223" src="https://github.com/user-attachments/assets/4b1f9b47-4126-48e5-afea-f3806976aa1f" />

<p align="right">

### 2.2 שליפת אשפוזים פעילים באמצעות מצביע (`fn_get_active_admissions.sql`)
פונקציה זו מחזירה מצביע דינמי לנתונים עבור אשפוזים שטרם הסתיימו (שם תאריך השחרור הוא `NULL`), ומסננת אותם לפי מילת מפתח בסיבת האשפוז.
<br>• **אלמנטים בקוד:** החזרת קורסור דינמי (`Ref Cursor`).

</p>

```sql
SET search_path TO patients, public;

CREATE OR REPLACE FUNCTION get_active_admissions(p_admission_reason_keyword VARCHAR)
RETURNS refcursor AS $$
DECLARE
    -- b. הגדרת Ref Cursor
    v_admission_cursor refcursor;
BEGIN
    -- פתיחת הקורסור עבור שאילתת אשפוזים פעילים
    OPEN v_admission_cursor FOR 
        SELECT admission_id, patient_id, admission_date, reason 
        FROM admission 
        WHERE discharge_date IS NULL 
          AND reason ILIKE '%' || p_admission_reason_keyword || '%'
        ORDER BY admission_date ASC;
        
    RETURN v_admission_cursor;
END;
$$ LANGUAGE plpgsql;

<img width="1127" height="846" alt="Capture d&#39;écran 2026-06-14 132303" src="https://github.com/user-attachments/assets/dd1bd9ed-27db-4a58-b778-c2a0c88e4284" />

<p align="right">

## 💼 שלב 3: פרוצדורות (Procedures)

הפרוצדורות מיועדות לביצוע שינויים ועדכונים מסיביים בבסיס הנתונים (פעולות DML). בשלב זה נכתבו שתי פרוצדורות העונות על דרישות המורכבות של הפרויקט.

### 3.1 שחרור המוני של מטופלים לפי מחלה (`proc_bulk_discharge_patients.sql`)
פרוצדורה זו מאפשרת לשחרר בבת אחת את כל המטופלים המאושפזים הנוכחיים שסיבת האשפוז שלהם תואמת למילת מפתח מסוימת (למשל, 'Flu'). היא מעדכנת את תאריך השחרור שלהם לזמן הנוכחי.
<br>• **אלמנטים בקוד:** קורסור משתמע (`Implicit Cursor` בתוך לולאת `FOR`), פקודת **DML** לעדכון (`UPDATE`), וניהול חריגות המפיץ את השגיאה בצורה מבוקרת ללא סיכון הטרנזקציה הראשית.

</p>

```sql
SET search_path TO patients, public;

CREATE OR REPLACE PROCEDURE bulk_discharge_patients(p_reason_keyword VARCHAR)
AS $$
DECLARE
    v_adm_rec RECORD;
    v_update_count INT := 0;
BEGIN
    -- בדיקת תקינות הקלט
    IF p_reason_keyword IS NULL OR p_reason_keyword = '' THEN
        RAISE EXCEPTION 'Reason keyword cannot be empty.';
    END IF;

    -- e. לולאה עם קורסור משתמע (Implicit Cursor) על כל האשפוזים הפעילים
    FOR v_adm_rec IN 
        SELECT admission_id FROM admission 
        WHERE discharge_date IS NULL AND reason ILIKE '%' || p_reason_keyword || '%' 
    LOOP
        
        -- c. פקודת DML (עדכון בסיס הנתונים)
        UPDATE admission 
        SET discharge_date = NOW()
        WHERE admission_id = v_adm_rec.admission_id;
        
        v_update_count := v_update_count + 1;
    END LOOP;

    RAISE NOTICE 'Successfully discharged % patients.', v_update_count;

EXCEPTION
    WHEN OTHERS THEN
        -- f. טיפול בחריגה: רישום השגיאה והעברתה הלאה ללא חסימת השרת
        RAISE NOTICE 'Transaction failed. Error: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;
<img width="1113" height="737" alt="Capture d&#39;écran 2026-06-14 132348" src="https://github.com/user-attachments/assets/5c34df49-c530-43fb-ae73-4d88b9e4018f" />

<p align="right">

### 3.2 ארכוב פוליסות ביטוח ישנות (`proc_archive_expired_insurance.sql`)
פרוצדורה זו מנקה ומייעלת את נפח בסיס הנתונים על ידי העברת פוליסות ביטוח שפג תוקפן (לפי מספר השנים שהוזן) מטבלת הביטוח הפעילה לטבלת הארכיון, ולאחר מכן מוחקת אותן מטבלת המקור.
<br>• **אלמנטים בקוד:** שילוב של מספר פקודות **DML** מורכבות (`INSERT INTO ... SELECT` ו-`DELETE`), שימוש ב-`make_interval` למניעת שגיאות טיפוסי תאריכים ב-PostgreSQL, ושימוש ב-`RECORD` לצורך מעקב שורות שהושפעו.

</p>

```sql
SET search_path TO patients, public;

CREATE OR REPLACE PROCEDURE archive_expired_insurance(p_years_old INT)
AS $$
DECLARE
    v_archived_count INT;
BEGIN
    -- c. פקודת DML ראשונה: העתקת הנתונים לטבלת הארכיון
    INSERT INTO insurance_archive (insurance_id, patient_id, provider_name, policy_number, expiration_date)
    SELECT insurance_id, patient_id, provider_name, policy_number, expiration_date 
    FROM insurance 
    WHERE expiration_date < CURRENT_DATE - make_interval(years => p_years_old);

    -- בדיקה כמה שורות הושפעו מההכנסה
    GET DIAGNOSTICS v_archived_count = ROW_COUNT;

    -- c. פקודת DML שנייה: מחיקת הרשומות המקוריות מטבלת הביטוח הפעילה
    DELETE FROM insurance 
    WHERE expiration_date < CURRENT_DATE - make_interval(years => p_years_old);

    RAISE NOTICE 'Archived % expired insurance policies successfully.', v_archived_count;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Archiving failed: %', SQLERRM;
        RAISE;
END;
$$ LANGUAGE plpgsql;
<img width="1132" height="881" alt="Capture d&#39;écran 2026-06-14 132438" src="https://github.com/user-attachments/assets/e9dd8b70-af57-451c-90ae-f4c60b98b83b" />

</div>
