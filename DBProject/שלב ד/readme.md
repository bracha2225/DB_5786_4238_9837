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
</div>
