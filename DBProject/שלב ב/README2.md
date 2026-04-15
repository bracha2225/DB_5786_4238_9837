

# מערכת לניהול פציינטים בבית חולים 🏥

## דוח פרויקט בסיסי נתונים — שלב ב'

---

## תוכן עניינים

* [מבוא](#מבוא)
* [שאילתות Select בשתי וריאציות (השוואת יעילות)](#שאילתות-select-בשתי-וריאציות-השוואת-יעילות)
* [שאילתות Select מורכבות נוספות](#שאילתות-select-מורכבות-נוספות)
* [שאילתות עדכון (Update) ומחיקה (Delete)](#שאילתות-עדכון-update-ומחיקה-delete)
* [אילוצים (Constraints)](#אילוצים-constraints)
* [ניהול טרנזקציות (Rollback & Commit)](#ניהול-טרנזקציות-rollback--commit)
* [שיפור ביצועים באמצעות אינדקסים](#שיפור-ביצועים-באמצעות-אינדקסים)

---

## מבוא

בשלב זה של הפרויקט, התמקדנו בבניית שאילתות המדמות את הפעילות היומיומית בבית החולים. המטרה הייתה לספק מידע ניהולי ורפואי בעל ערך (כמו זיהוי חולים בסיכון או מעקב אדמיניסטרטיבי) תוך שימת דגש על כתיבת קוד יעיל ואופטימלי. במהלך העבודה בחנו כיצד שימוש בשיטות כתיבה שונות משפיע על מהירות שליפת הנתונים וכיצד ניתן לשמור על שלמות המידע בעזרת אילוצים.

---

## שאילתות Select בשתי וריאציות (השוואת יעילות)

עבור כל אחת מהשאילתות הבאות כתבנו שתי גרסאות ובחנו איזו מהן עדיפה מבחינת ביצועים.

---

### 1. חולים עם אלרגיות מסכנות חיים ומספר האשפוזים שלהם

**תיאור:** שליפת שמות חולים עם אלרגיה ברמת 'Life-threatening' וספירת כמות האשפוזים לכל אחד.

**גרסה א' (שימוש ב-JOIN):**

```sql
SELECT p.first_name, p.last_name, COUNT(a.admission_id) AS total_admissions
FROM patient p
JOIN allergy al ON p.patient_id = al.patient_id
LEFT JOIN admission a ON p.patient_id = a.patient_id
WHERE al.severity = 'Life-threatening'
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY total_admissions DESC;
```

<img width="1033" height="834" alt="image" src="https://github.com/user-attachments/assets/3e5ef4eb-19c1-4e2f-aefd-97409e96f045" />




**גרסה ב' (שימוש ב-Subquery):**

```sql
SELECT p.first_name, p.last_name,
       (SELECT COUNT(*) FROM admission a WHERE a.patient_id = p.patient_id) AS total_admissions
FROM patient p
WHERE p.patient_id IN (SELECT al.patient_id FROM allergy al WHERE al.severity = 'Life-threatening')
ORDER BY total_admissions DESC;
```

<img width="1273" height="840" alt="image" src="https://github.com/user-attachments/assets/c0925e1d-a854-4884-98da-297d5931f554" />

**השוואת יעילות:**
גרסה א' עדיפה. שימוש ב-JOIN מאפשר למסד הנתונים לעבד את המידע כיחידה אחת (Bulk). גרסה ב' מריצה שאילתת ספירה עבור כל שורה בנפרד, מה שיוצר עומס רב בזמן ריצה על טבלאות גדולות.

---

### 2. חולים שאושפזו ב-2023 עם ביטוח בתוקף עד 2026

**תיאור:** איתור חולים רלוונטיים לצורך עדכון מנהלתי של פרטי הביטוח שלהם.

**גרסה א' (ריבוי JOINs):**

```sql
SELECT p.first_name, p.last_name, i.provider_name, i.expiration_date
FROM patient p
JOIN admission ad ON p.patient_id = ad.patient_id
JOIN insurance i ON p.patient_id = i.patient_id
WHERE EXTRACT(YEAR FROM ad.admission_date) = 2023
  AND EXTRACT(YEAR FROM i.expiration_date) = 2026
ORDER BY i.expiration_date ASC;
```

<img width="1039" height="639" alt="image" src="https://github.com/user-attachments/assets/22ded742-743b-40e1-88db-72fcefa345de" />

**גרסה ב' (שימוש ב-EXISTS):**

```sql
SELECT p.first_name, p.last_name, i.provider_name
FROM patient p
JOIN insurance i ON p.patient_id = i.patient_id
WHERE EXTRACT(YEAR FROM i.expiration_date) = 2026
AND EXISTS (
    SELECT 1 FROM admission ad 
    WHERE ad.patient_id = p.patient_id 
    AND ad.admission_date BETWEEN '2023-01-01' AND '2023-12-31'
);
```

<img width="1113" height="828" alt="image" src="https://github.com/user-attachments/assets/51e9c4ec-19f0-4c4b-a6d8-1fa57eaaf28e" />

**השוואת יעילות:**
גרסה ב' עדיפה. בגרסה א', כל אשפוז משכפל את שורת החולה בזיכרון לפני הסינון. גרסה ב' עוצרת את החיפוש ברגע שנמצא אשפוז אחד מתאים, ובכך חוסכת זמן עיבוד יקר.

---

### 3. חולים עם ריבוי מצבים רפואיים (מורכבות רפואית)

**תיאור:** רשימת חולים שיש להם יותר ממצב רפואי אחד רשום בהיסטוריה שלהם.

**גרסה א' (שימוש ב-HAVING):**

```sql
SELECT p.first_name, p.last_name, COUNT(mh.history_id) AS nb_conditions
FROM patient p
JOIN medical_history mh ON p.patient_id = mh.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(mh.history_id) > 1;
```

<img width="1122" height="827" alt="image" src="https://github.com/user-attachments/assets/5d66bfc8-e750-4998-ac7e-9d167c0f66c2" />

**גרסה ב' (שימוש ב-CTE):**

```sql
WITH PatientCounts AS (
    SELECT patient_id, COUNT(*) as cnt
    FROM medical_history
    GROUP BY patient_id
)
SELECT p.first_name, p.last_name, pc.cnt
FROM patient p
JOIN PatientCounts pc ON p.patient_id = pc.patient_id
WHERE pc.cnt > 1;
```

<img width="1052" height="835" alt="image" src="https://github.com/user-attachments/assets/9ede416d-5726-4d6c-a707-9053e146c56d" />

**השוואת יעילות:**
גרסה א' עדיפה. גרסה ב' אמנם קריאה וברורה מאוד, אך גרסה א' מאפשרת למנוע ה-SQL לבצע את החישוב והקישור תוך כדי העבודה בלי ליצור טבלה זמנית בזיכרון.

---

### 4. משך אשפוז ממוצע לחולים מבוגרים

**תיאור:** רשימת חולים שנולדו לפני שנת 1980, יחד עם משך האשפוז הממוצע שלהם בבית החולים (בימים). השאילתה מאפשרת לבחון את משך האשפוז של אוכלוסייה מבוגרת ולהבין את רמת השימוש שלה בשירותי האשפוז. נכללים רק אשפוזים שהסתיימו (כלומר בעלי תאריך שחרור).

**גרסה א' (שימוש ב-JOIN + GROUP BY):**

```sql
SELECT p.first_name, p.last_name, 
       AVG(EXTRACT(DAY FROM (discharge_date - admission_date))) AS avg_stay_days
FROM patient p
JOIN admission a ON p.patient_id = a.patient_id
WHERE EXTRACT(YEAR FROM p.date_of_birth) < 1980
  AND a.discharge_date IS NOT NULL
GROUP BY p.patient_id, p.first_name, p.last_name;
```

<img width="928" height="752" alt="image" src="https://github.com/user-attachments/assets/081b1b7d-d4a9-4222-b7c2-d9d92d712df4" />

**גרסה ב' (שימוש ב-LATERAL JOIN):**

```sql
SELECT p.first_name, p.last_name, sub.avg_stay
FROM patient p,
LATERAL (
    SELECT AVG(EXTRACT(DAY FROM (a.discharge_date - a.admission_date))) as avg_stay
    FROM admission a
    WHERE a.patient_id = p.patient_id
) sub
WHERE EXTRACT(YEAR FROM p.date_of_birth) < 1980 AND sub.avg_stay IS NOT NULL;
```

<img width="1018" height="796" alt="image" src="https://github.com/user-attachments/assets/c7ce0993-c509-479b-9b49-23088a0378f5" />

**השוואת יעילות:**
גרסה א' עדיפה משמעותית. גרסה א' מעבדת את כל טבלת האשפוזים בבת אחת. גרסה ב' מבצעת מעין "לולאה" ומחשבת את הממוצע עבור כל חולה בנפרד, מה שגורם להאטה משמעותית ככל שמספר החולים גדל.

---

## שאילתות Select מורכבות נוספות

### 5. אנשי קשר לשעת חירום עבור חולים המאושפזים כעת

**תיאור:** שליפת פרטי יצירת קשר דחופים עבור חולים שטרם שוחררו.

```sql
SELECT p.first_name AS patient_name, ec.name AS contact_person, ec.relationship, ec.phone
FROM patient p
JOIN admission a ON p.patient_id = a.patient_id
JOIN emergency_contact ec ON p.patient_id = ec.patient_id
WHERE a.discharge_date IS NULL
ORDER BY p.last_name;
```
<img width="1078" height="671" alt="image" src="https://github.com/user-attachments/assets/a9459233-e9f0-4c28-b85b-786dc0397f77" />


---

### 6. פילוח אשפוזים לפי שנה וחודש

**תיאור:** מעקב סטטיסטי אחר עומסים בבית החולים לאורך זמן.

```sql
SELECT 
    EXTRACT(YEAR FROM admission_date) AS annee,
    EXTRACT(MONTH FROM admission_date) AS mois,
    COUNT(*) AS total_admissions
FROM admission
GROUP BY annee, mois
ORDER BY annee DESC, mois DESC;
```

<img width="926" height="853" alt="image" src="https://github.com/user-attachments/assets/bda48a83-bd1e-49ce-bd8f-290dca03a06e" />


---

### 7. איתור רשומות רפואיות חסרות

**תיאור:** חולים שאין עבורם תיעוד רפואי קודם במערכת.

```sql
SELECT p.first_name, p.last_name, p.email
FROM patient p
LEFT JOIN allergy al ON p.patient_id = al.patient_id
LEFT JOIN medical_history mh ON p.patient_id = mh.patient_id
WHERE al.allergy_id IS NULL AND mh.history_id IS NULL;
```

<img width="951" height="824" alt="image" src="https://github.com/user-attachments/assets/cebef81c-1206-4f05-970f-a99d209fdd46" />


---

### 8. פרטי ביטוח לחולים המיועדים לניתוח

**תיאור:** עזרה למחלקת הגבייה בבירור כיסוי עבור פרוצדורות יקרות.

```sql
SELECT p.first_name, p.last_name, i.provider_name, i.policy_number, a.reason
FROM patient p
JOIN insurance i ON p.patient_id = i.patient_id
JOIN admission a ON p.patient_id = a.patient_id
WHERE a.reason LIKE '%Surgery%'
ORDER BY p.last_name;
```

<img width="975" height="846" alt="image" src="https://github.com/user-attachments/assets/d570d023-8de7-45f1-bb89-53a4be677e84" />


---


## שאילתות עדכון (Update) ומחיקה (Delete)

---

### שאילתות מחיקה (Delete)

#### 1. מחיקה של אנשי קשר לשעת חירום לחולים שלא אושפזו ב-5 שנים

**תיאור:** מחיקת אנשי קשר לחולים שלא בקרו בבית החולים ליותר מ-5 שנים. זו פעולה ניקיון נתונים עבור רשומות שאינן פעילות וההנתקות שלהן אינן רלוונטיות עוד.

```sql
DELETE FROM emergency_contact
WHERE patient_id IN (
    SELECT p.patient_id
    FROM patient p
    LEFT JOIN admission a ON p.patient_id = a.patient_id
    GROUP BY p.patient_id
    HAVING MAX(a.admission_date) < CURRENT_DATE - INTERVAL '5 years'
       OR COUNT(a.admission_id) = 0
);
```

📷 צילום המסד לפני המחיקה
<img width="1094" height="713" alt="image" src="https://github.com/user-attachments/assets/66d04fb9-feb1-4206-a687-b5b99252c4c1" />




📷 צילום המסד אחרי המחיקה
<img width="897" height="849" alt="image" src="https://github.com/user-attachments/assets/d7411399-e5e3-4f5e-9293-1a90fced59a3" />


---

#### 2. מחיקה של רשומות ביטוח שפג תוקפן לחולים ללא אשפוזים פעילים

**תיאור:** הסרת רשומות ביטוח שתוקפן פג וחולים אלו אינם מאושפזים כעת בבית החולים. המערכת מבטיחה שלא נמחק מידע ביטוח בזמן אשפוז, אפילו אם הפוליסה פג טכנית במהלך השהייה.

```sql
DELETE FROM insurance
WHERE expiration_date < CURRENT_DATE
AND patient_id NOT IN (
    SELECT patient_id 
    FROM admission 
    WHERE discharge_date IS NULL
);
```

📷 צילום המסד לפני המחיקה

<img width="733" height="657" alt="image" src="https://github.com/user-attachments/assets/6d44c711-87a8-41a5-9f01-8de85c3d4974" />


📷 צילום המסד אחרי המחיקה
<img width="861" height="840" alt="image" src="https://github.com/user-attachments/assets/2b9d58a8-c2b6-49c8-9753-7bfdb397c7f9" />


---

#### 3. מחיקה של רשומות רפואיות ישנות (מזומן ללא תקשורת)

**תיאור:** מחיקת רשומות היסטוריה רפואית כגון 'Minor Flu' שאובחנו לפני יותר מ-10 שנים. זוהי פעולת שמירה על פרטיות ומינימום נתונים על ידי הסרת רשומות רפואיות ישנות וקטנות בחשיבות.

```sql
DELETE FROM medical_history
WHERE condition_name = 'Minor Flu'
AND EXTRACT(YEAR FROM diagnosis_date) < EXTRACT(YEAR FROM CURRENT_DATE) - 10;
```

📷 צילום המסד לפני המחיקה

<img width="975" height="842" alt="image" src="https://github.com/user-attachments/assets/b65c2983-96ae-4f6b-ac39-fd9b8f07722c" />


📷 צילום המסד אחרי המחיקה

<img width="940" height="850" alt="image" src="https://github.com/user-attachments/assets/c5c4fd60-5f8f-4cc3-8668-4c3b9ba93409" />

---

### שאילתות עדכון (Update)

#### 1. עדכון הערות אלרגיות לחולים בתדירות אשפוז גבוהה

**תיאור:** עדכון שדה ההערות בטבלת האלרגיות עבור חולים שאושפזו יותר מ-3 פעמים. זה מסמן חולים בסיכון גבוה בהערות המערכת לתשומת לב קלינית מיוחדת.

```sql
UPDATE allergy
SET notes = CONCAT(notes, ' [CRITICAL: High-frequency admission patient]')
WHERE patient_id IN (
    SELECT patient_id
    FROM admission
    GROUP BY patient_id
    HAVING COUNT(admission_id) > 3
);
```

📷 צילום המסד לפני העדכון

<img width="955" height="841" alt="image" src="https://github.com/user-attachments/assets/48151feb-e58d-4b8d-ad56-51d08716f0c1" />


📷 צילום המסד במשך העדכון
<img width="1069" height="555" alt="image" src="https://github.com/user-attachments/assets/e7f0baef-38e5-4343-9aa3-fd18f645aa2a" />


📷 צילום המסד אחרי העדכון


<img width="1044" height="837" alt="image" src="https://github.com/user-attachments/assets/850956eb-deb4-42e0-9722-e2b0a3ca0ec1" />


---

#### 2. שדרוג סוג כיסוי ביטוח לחולים עם אלרגיות מסכנות חיים

**תיאור:** התקנה של 'Premium Extended' לכל חולים בעלי אלרגיות ברמת 'Life-threatening', בהתאם למדיניות חדשה של בית החולים לחולים בטיפול גבוה. זה מקשר את טבלת הביטוח עם טבלת האלרגיות.

```sql
UPDATE insurance
SET coverage_type = 'Premium Extended'
WHERE patient_id IN (
    SELECT patient_id
    FROM allergy
    WHERE severity = 'Life-threatening'
);
```

📷 צילום המסד לפני העדכון

<img width="915" height="841" alt="image" src="https://github.com/user-attachments/assets/ad694344-9e9e-4819-bcde-d43f5dd8bd17" />



📷 צילום המסד במשך העדכון


<img width="968" height="762" alt="image" src="https://github.com/user-attachments/assets/34a2edc1-f268-445e-ad0c-36a11cf38709" />




📷 צילום המסד אחרי העדכון
<img width="934" height="838" alt="image" src="https://github.com/user-attachments/assets/cc129a83-da9d-4eff-8352-5a60d7af026b" />



---

#### 3. הוספת אזהרה להערות היסטוריה רפואית לחולים עם ביטוח שפג

**תיאור:** הוספת התראה להערות של רשומות היסטוריה רפואית עבור חולים שביטוחם כבר פג. זה מעניין רופאים שהיסטוריה רפואית עדכנית אולי לא מכוסה על ידי הספק הביטוח הקודם.

```sql
UPDATE medical_history
SET notes = CONCAT(notes, ' (Review insurance: Policy expired on ', i.expiration_date, ')')
FROM insurance i
WHERE medical_history.patient_id = i.patient_id
AND i.expiration_date < CURRENT_DATE;
```

📷 צילום המסד לפני העדכון

<img width="887" height="836" alt="image" src="https://github.com/user-attachments/assets/3f042770-be5e-49a0-8c54-9e89b8ef6e07" />



📷 צילום המסד במשך העדכון

<img width="1093" height="593" alt="image" src="https://github.com/user-attachments/assets/d58819e9-94e8-4e14-9e74-ea8dcc603e55" />




📷 צילום המסד אחרי העדכון


<img width="1182" height="678" alt="image" src="https://github.com/user-attachments/assets/0bdcc075-0370-4517-aa16-dfe2a94ebe65" />



---
```
