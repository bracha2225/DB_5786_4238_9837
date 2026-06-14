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


<img width="1100" height="872" alt="Capture d&#39;écran 2026-06-14 131513" src="https://github.com/user-attachments/assets/4ff59508-5018-4bf9-a5fc-f0b4d90c9a4d" />


-- 1. טבלה לארכוב פוליסות ביטוח פגות תוקף (עבור פרוצדורה 2)
```sql
CREATE TABLE insurance_archive (
    archive_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    insurance_id INT,
    patient_id INT,
    provider_name VARCHAR(150),
    policy_number VARCHAR(50),
    expiration_date DATE,
    archived_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

-- 2. טבלת לוגים לתיעוד משך אשפוז של מטופלים (עבור טריגר 1)
```sql
CREATE TABLE admission_audit_logs (
    log_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    admission_id INT,
    patient_id INT,
    total_stay_hours NUMERIC,
    logged_at TIMESTAMPTZ
);
```



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
```

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
```

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
```
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
```
<img width="1132" height="881" alt="Capture d&#39;écran 2026-06-14 132438" src="https://github.com/user-attachments/assets/e9dd8b70-af57-451c-90ae-f4c60b98b83b" />


## ⚡ שלב 4: טריגרים (Triggers)

הטריגרים הם רכיבי אבטחה המופעלים אוטומטית בזמן ביצוע שינויים בטבלאות כדי לאכוף חוקים עסקיים מורכבים ולבצע תיעוד ברקע.
<p align="right">

### 4.1 מעקב וביקורת שעות אשפוז (`trg_admission_date_check.sql`)
טריגר זה מופעל בזמן **UPDATE** (לפני עדכון השורה) על טבלת `admission`. הוא מונע הזנת תאריכים עתידיים לא חוקיים, ובנוסף, ברגע שמטופל משתחרר (תאריך השחרור משתנה מ-`NULL` לתאריך נוכחי), הטריגר מחשב אוטומטית את משך השהות שלו בשעות ומכניס שורת תיעוד לטבלת הביקורת.
<br>• **אלמנטים בקוד:** הפעלה בזמן **UPDATE**, שימוש במשתני מערכת (`OLD` ו-`NEW`), וביצוע פקודת **DML** של הכנסה (`INSERT INTO`).

</p>

```sql
SET search_path TO patients, public;

CREATE OR REPLACE FUNCTION trg_audit_admission_update()
RETURNS TRIGGER AS $$
BEGIN
    -- אכיפת חוק עסקי: מניעת עדכון תאריך אשפוז לעתיד
    IF NEW.admission_date > NOW() THEN
        RAISE EXCEPTION 'Admission date cannot be set in the future.';
    END IF;

    -- c. פקודת DML: הזנת לוג אוטומטית לטבלת הביקורת בעת שחרור המטופל
    IF OLD.discharge_date IS NULL AND NEW.discharge_date IS NOT NULL THEN
        INSERT INTO admission_audit_logs(admission_id, patient_id, total_stay_hours, logged_at)
        VALUES(OLD.admission_id, OLD.patient_id, EXTRACT(EPOCH FROM (NEW.discharge_date - OLD.admission_date))/3600, NOW());
    END IF;

    RETURN NEW;
END;
```

-- הגדרת הטריגר על הטבלה בזמן UPDATE
CREATE TRIGGER trigger_admission_date_check
BEFORE UPDATE ON admission
FOR EACH ROW
EXECUTE FUNCTION trg_audit_admission_update();

<img width="1098" height="871" alt="Capture d&#39;écran 2026-06-14 132524" src="https://github.com/user-attachments/assets/1f5b0b7b-4ff4-40b2-ae97-f81b78072edb" />
<p align="right">

### 4.2 מניעת כפילות אשפוזים פעילים (`trg_prevent_duplicate_active_admission.sql`)
טריגר זה מופעל בזמן **INSERT** על טבלת `admission`. הוא מוודא שמטופל לא יאושפז מחדש אם יש לו כבר אשפוז נוכחי פעיל שטרם נסגר, ובכך מונע כפילויות מידע קריטיות בבית החולים.
<br>• **אלמנטים בקוד:** הפעלה בזמן **INSERT**, שימוש בתנאים, והפעלת חסימה מוחלטת באמצעות זריקת חריגה (`RAISE EXCEPTION`).

</p>

```sql
SET search_path TO patients, public;

CREATE OR REPLACE FUNCTION trg_check_active_admissions()
RETURNS TRIGGER AS $$
DECLARE
    v_active_count INT;
BEGIN
    -- בדיקה האם קיים כבר אשפוז פעיל עבור אותו מטופל
    SELECT COUNT(*) INTO v_active_count 
    FROM admission 
    WHERE patient_id = NEW.patient_id AND discharge_date IS NULL;

    -- חסימת הפעולה במקרה של כפילות
    IF v_active_count > 0 THEN
        RAISE EXCEPTION 'Patient ID % is already currently admitted and cannot have another active admission.', NEW.patient_id;
    END IF;

    RETURN NEW;
END;
```

-- הגדרת הטריגר על הטבלה בזמן INSERT
CREATE TRIGGER trigger_prevent_duplicate_active_admission
BEFORE INSERT ON admission
FOR EACH ROW
EXECUTE FUNCTION trg_check_active_admissions();
<img width="1105" height="863" alt="Capture d&#39;écran 2026-06-14 132603" src="https://github.com/user-attachments/assets/92fd5dfc-f66a-4e56-ae63-804e56cc37fc" />

<p align="right">

## 📸 שלב 5: הוכחות הרצה - בדיקת הנתונים ההתחלתית (מצב "לפני")

לפני הרצת תוכניות הבדיקה הראשיות (`Main Programs`), בוצעו שאילתות בקרה על טבלאות בסיס הנתונים עבור מטופל מספר 1 כדי לתעד את מצב המערכת ההתחלתי.

### 5.1 בדיקת מצב אשפוזים פעילים ("לפני")
השאילתה הבאה בודקת את האשפוזים הנוכחיים המשויכים למטופל. כפי שניתן לראות בצילום המסך, קיימים שני אשפוזים פתוחים (עבור שפעת ועבור בעיות לב), כאשר בשניהם עמודת תאריך השחרור (`discharge_date`) מכילה ערך `[null]`. עובדה זו מוכיחה שהמטופל עדיין לא שוחרר מבית החולים ומערכת הטריגרים טרם הופעלה על שורות אלו.

</p>

<img width="1126" height="750" alt="Capture d&#39;écran 2026-06-14 132649" src="https://github.com/user-attachments/assets/28e882db-b5a7-4ab9-96fd-9dbb21186402" />

<p align="right">

### 5.2 בדיקת פוליסות ביטוח פעילות ("לפני")
השאילתה הבאה מציגה את רשומות הביטוח של המטופל בטבלה הפעילה `insurance`. בצילום המסך ניתן לראות כי פוליסת הביטוח הישנה `POL-OLD-99` (שהיא פגת תוקף מעל 5 שנים) עדיין נמצאת בטבלה המקורית וטרם עברה תהליך ארכוב ומחיקה על ידי הפרוצדורה.

</p>

<img width="1112" height="637" alt="Capture d&#39;écran 2026-06-14 132703" src="https://github.com/user-attachments/assets/79e4927d-37d8-4edb-9073-f9f5801cd1f8" />
<p align="right">

## 📸 שלב 6: הוכחות הרצה - הפעלת תוכניות ראשיות (לשונית Messages)

לאחר תיעוד המצב ההתחלתי, הורצו בלוקי הבדיקה האנונימיים כדי להפעיל את הפונקציות והפרוצדורות של המערכת ולבחון את הפלט הישיר שלהן.

### 6.1 פלט הרצת התוכניות הראשיות 1 ו-2 (תוצאות הזימונים)
* **תוכנית ראשית 1:** הפרוצדורה איתרה את אשפוז השפעת הפתוח וסגרה אותו. מיד לאחר מכן, הפונקציה סרקה את ההיסטוריה הרפואית והאלרגיות של המטופל והחזירה את סטטוס הסיכון המשוקלל שלו (`Moderate Risk`).
* **תוכנית ראשית 2:** הפרוצדורה העבירה את פוליסת הביטוח הישנה לארכיון ומחקה אותה מהטבלה הפעילה. לאחר מכן, הפונקציה פתחה `Ref Cursor` על אשפוזים פעילים עם סיבת לב ('Heart'), והלולאה של הבלוק שלפה והדפיסה את הנתונים ישירות למסך.

</p>

#### פלט Messages עבור תוכנית ראשית 1:
<img width="1127" height="867" alt="Capture d&#39;écran 2026-06-14 132909" src="https://github.com/user-attachments/assets/643338a9-f388-4bce-bf84-649b554854e6" />

#### פלט Messages עבור תוכנית ראשית 2:
<img width="1161" height="856" alt="Capture d&#39;écran 2026-06-14 133044" src="https://github.com/user-attachments/assets/2af7df49-19eb-41b1-9897-e986ccc5004f" />

---

<p align="right">

## 📸 שלב 7: הוכחות שינוי נתונים בבסיס הנתונים (מצב "אחרי")

כדי להוכיח שהפרוצדורות והטריגרים ביצעו שינויי DML אמיתיים בבסיס הנתונים, בוצעו שאילתות בדיקה חוזרות על הטבלאות.

### 7.1 הוכחת פעולת הטריגר - טבלת ביקורת האשפוזים (`admission_audit_logs`)
בעקבות עדכון תאריך השחרור של חולה השפעת על ידי הפרוצדורה בתוכנית 1, הטריגר `trigger_admission_date_check` הופעל אוטומטית ברקע (BEFORE UPDATE). הטריגר חישב את כמות השעות המדויקת שהמטופל שהה בבית החולים מאז תאריך האשפוז שלו והזין רשומה חדשה המציגה בדיוק 72.23 שעות אשפוז.

</p>

<img width="1131" height="658" alt="Capture d&#39;écran 2026-06-14 133009" src="https://github.com/user-attachments/assets/9189a25d-5852-41e0-b0eb-39a065855ea9" />

<p align="right">

### 7.2 הוכחת ארכוב הביטוחים - טבלת ארכיון הביטוח (`insurance_archive`)
לאחר הרצת תוכנית 2, פוליסת הביטוח הישנה `POL-OLD-99` נמחקה לחלוטין מטבלת `insurance` הפעילה (כפי שנדרש בפעולת ה-DELETE), והועברה בצורה מאובטחת לטבלת הארכיון החדשה יחד עם חותמת זמן של רגע הארכוב.

</p>
<img width="1316" height="845" alt="image" src="https://github.com/user-attachments/assets/7a872903-8728-4ded-a74e-d68f45fe2d41" />

</div>
