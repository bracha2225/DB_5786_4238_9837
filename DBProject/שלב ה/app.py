import os
from flask import Flask, jsonify, request, render_template
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import date, datetime

app = Flask(__name__)

# Disable browser/Flask static file caching during development
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

# ─────────────────────────────────────────────
# Database connection
# ─────────────────────────────────────────────
def get_db():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=os.getenv("DB_PORT", "5433"),
        database=os.getenv("DB_NAME_SECRET", "basnat"),
        user=os.getenv("DB_USER_SECRET", "admin"),
        password=os.getenv("DB_PASSWORD_SECRET", "password1234"),
        cursor_factory=RealDictCursor
    )

def rows_to_json(rows):
    """Convert rows; serialize date/datetime objects."""
    result = []
    for row in rows:
        d = dict(row)
        for k, v in d.items():
            if isinstance(v, (date, datetime)):
                d[k] = v.isoformat()
        result.append(d)
    return result

# ─────────────────────────────────────────────
# Main page
# ─────────────────────────────────────────────
@app.route('/')
def index():
    return render_template('index.html')

# ─────────────────────────────────────────────
# Dashboard stats
# ─────────────────────────────────────────────
@app.route('/api/stats')
def get_stats():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) AS c FROM patients.patient;")
        total_patients = cur.fetchone()['c']
        cur.execute("SELECT COUNT(*) AS c FROM patients.admission WHERE discharge_date IS NULL;")
        active_admissions = cur.fetchone()['c']
        cur.execute("SELECT COUNT(*) AS c FROM staffschema.staff;")
        total_staff = cur.fetchone()['c']
        cur.execute("SELECT COUNT(*) AS c FROM staffschema.staff WHERE status = 'Active';")
        active_staff = cur.fetchone()['c']
        return jsonify({"total_patients": total_patients, "active_admissions": active_admissions,
                        "total_staff": total_staff, "active_staff": active_staff})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# Dropdown helpers
# ─────────────────────────────────────────────
@app.route('/api/patients/list')
def patients_list():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT patient_id, first_name || ' ' || last_name AS name FROM patients.patient ORDER BY name LIMIT 500;")
        return jsonify(rows_to_json(cur.fetchall()))
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/staff/list')
def staff_list():
    conn = None
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT staffid, firstname || ' ' || lastname AS name FROM staffschema.staff ORDER BY name LIMIT 500;")
        return jsonify(rows_to_json(cur.fetchall()))
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# CRUD – Patients
# ─────────────────────────────────────────────
@app.route('/api/patients', methods=['GET', 'POST'])
def patients():
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("""
                SELECT p.patient_id, p.first_name, p.last_name, p.date_of_birth, p.gender,
                       p.phone, p.email, p.address, p.staffid,
                       s.firstname || ' ' || s.lastname AS staff_name
                FROM patients.patient p
                LEFT JOIN staffschema.staff s ON p.staffid = s.staffid
                ORDER BY p.patient_id DESC LIMIT 500;
            """)
            return jsonify(rows_to_json(cur.fetchall()))
        else:
            d = request.json
            sid = d.get('staffid') or None
            cur.execute("""INSERT INTO patients.patient(first_name,last_name,date_of_birth,gender,phone,email,address,staffid)
                           VALUES(%s,%s,%s,%s,%s,%s,%s,%s) RETURNING patient_id;""",
                        (d['first_name'],d['last_name'],d['date_of_birth'],d['gender'],d['phone'],d['email'],d['address'],sid))
            nid = cur.fetchone()['patient_id']; conn.commit()
            return jsonify({"status":"success","patient_id":nid})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/patients/<int:pid>', methods=['GET','PUT','DELETE'])
def patient_one(pid):
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("SELECT * FROM patients.patient WHERE patient_id=%s;", (pid,))
            row = cur.fetchone()
            if not row: return jsonify({"error":"not found"}), 404
            return jsonify(rows_to_json([row])[0])
        elif request.method == 'PUT':
            d = request.json; sid = d.get('staffid') or None
            cur.execute("""UPDATE patients.patient SET first_name=%s,last_name=%s,date_of_birth=%s,
                           gender=%s,phone=%s,email=%s,address=%s,staffid=%s WHERE patient_id=%s;""",
                        (d['first_name'],d['last_name'],d['date_of_birth'],d['gender'],d['phone'],d['email'],d['address'],sid,pid))
            conn.commit(); return jsonify({"status":"success"})
        else:
            cur.execute("DELETE FROM patients.patient WHERE patient_id=%s;", (pid,))
            conn.commit(); return jsonify({"status":"success"})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# CRUD – Staff
# ─────────────────────────────────────────────
@app.route('/api/staff', methods=['GET','POST'])
def staff():
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("SELECT * FROM staffschema.staff ORDER BY staffid DESC LIMIT 500;")
            return jsonify(rows_to_json(cur.fetchall()))
        else:
            d = request.json
            cur.execute("""INSERT INTO staffschema.staff(staffid,firstname,lastname,idnumber,phone,email,status,hiredate,deptid,roleid)
                           VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) RETURNING staffid;""",
                        (d['staffid'],d['firstname'],d['lastname'],d['idnumber'],d['phone'],d['email'],d['status'],d['hiredate'],d.get('deptid'),d.get('roleid')))
            nid = cur.fetchone()['staffid']; conn.commit()
            return jsonify({"status":"success","staffid":nid})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/staff/<int:sid>', methods=['GET','PUT','DELETE'])
def staff_one(sid):
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("SELECT * FROM staffschema.staff WHERE staffid=%s;", (sid,))
            row = cur.fetchone()
            if not row: return jsonify({"error":"not found"}), 404
            return jsonify(rows_to_json([row])[0])
        elif request.method == 'PUT':
            d = request.json
            cur.execute("""UPDATE staffschema.staff SET firstname=%s,lastname=%s,idnumber=%s,phone=%s,email=%s,
                           status=%s,hiredate=%s,deptid=%s,roleid=%s WHERE staffid=%s;""",
                        (d['firstname'],d['lastname'],d['idnumber'],d['phone'],d['email'],d['status'],d['hiredate'],d.get('deptid'),d.get('roleid'),sid))
            conn.commit(); return jsonify({"status":"success"})
        else:
            cur.execute("DELETE FROM staffschema.staff WHERE staffid=%s;", (sid,))
            conn.commit(); return jsonify({"status":"success"})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# CRUD – Admissions
# ─────────────────────────────────────────────
@app.route('/api/admissions', methods=['GET','POST'])
def admissions():
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("""SELECT a.admission_id, a.patient_id, a.admission_date, a.discharge_date, a.reason,
                                  p.first_name||' '||p.last_name AS patient_name
                           FROM patients.admission a JOIN patients.patient p ON a.patient_id=p.patient_id
                           ORDER BY a.admission_id DESC LIMIT 500;""")
            return jsonify(rows_to_json(cur.fetchall()))
        else:
            d = request.json; dd = d.get('discharge_date') or None
            cur.execute("INSERT INTO patients.admission(patient_id,admission_date,discharge_date,reason) VALUES(%s,%s,%s,%s) RETURNING admission_id;",
                        (d['patient_id'],d['admission_date'],dd,d['reason']))
            nid = cur.fetchone()['admission_id']; conn.commit()
            return jsonify({"status":"success","admission_id":nid})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/admissions/<int:aid>', methods=['GET','PUT','DELETE'])
def admission_one(aid):
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("SELECT * FROM patients.admission WHERE admission_id=%s;", (aid,))
            row = cur.fetchone()
            if not row: return jsonify({"error":"not found"}), 404
            return jsonify(rows_to_json([row])[0])
        elif request.method == 'PUT':
            d = request.json; dd = d.get('discharge_date') or None
            cur.execute("UPDATE patients.admission SET patient_id=%s,admission_date=%s,discharge_date=%s,reason=%s WHERE admission_id=%s;",
                        (d['patient_id'],d['admission_date'],dd,d['reason'],aid))
            conn.commit(); return jsonify({"status":"success"})
        else:
            cur.execute("DELETE FROM patients.admission WHERE admission_id=%s;", (aid,))
            conn.commit(); return jsonify({"status":"success"})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# CRUD – Allergies
# ─────────────────────────────────────────────
@app.route('/api/allergies', methods=['GET','POST'])
def allergies():
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("""SELECT al.allergy_id,al.patient_id,al.allergy_name,al.severity,al.notes,
                                  p.first_name||' '||p.last_name AS patient_name
                           FROM patients.allergy al JOIN patients.patient p ON al.patient_id=p.patient_id
                           ORDER BY al.allergy_id DESC LIMIT 500;""")
            return jsonify(rows_to_json(cur.fetchall()))
        else:
            d = request.json
            cur.execute("INSERT INTO patients.allergy(patient_id,allergy_name,severity,notes) VALUES(%s,%s,%s,%s) RETURNING allergy_id;",
                        (d['patient_id'],d['allergy_name'],d['severity'],d.get('notes')))
            nid = cur.fetchone()['allergy_id']; conn.commit()
            return jsonify({"status":"success","allergy_id":nid})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/allergies/<int:alid>', methods=['GET','PUT','DELETE'])
def allergy_one(alid):
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("SELECT * FROM patients.allergy WHERE allergy_id=%s;", (alid,))
            row = cur.fetchone()
            if not row: return jsonify({"error":"not found"}), 404
            return jsonify(rows_to_json([row])[0])
        elif request.method == 'PUT':
            d = request.json
            cur.execute("UPDATE patients.allergy SET patient_id=%s,allergy_name=%s,severity=%s,notes=%s WHERE allergy_id=%s;",
                        (d['patient_id'],d['allergy_name'],d['severity'],d.get('notes'),alid))
            conn.commit(); return jsonify({"status":"success"})
        else:
            cur.execute("DELETE FROM patients.allergy WHERE allergy_id=%s;", (alid,))
            conn.commit(); return jsonify({"status":"success"})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# CRUD – Medical History
# ─────────────────────────────────────────────
@app.route('/api/medical-histories', methods=['GET','POST'])
def histories():
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("""SELECT mh.history_id,mh.patient_id,mh.condition_name,mh.diagnosis_date,mh.notes,
                                  p.first_name||' '||p.last_name AS patient_name
                           FROM patients.medical_history mh JOIN patients.patient p ON mh.patient_id=p.patient_id
                           ORDER BY mh.history_id DESC LIMIT 500;""")
            return jsonify(rows_to_json(cur.fetchall()))
        else:
            d = request.json
            cur.execute("INSERT INTO patients.medical_history(patient_id,condition_name,diagnosis_date,notes) VALUES(%s,%s,%s,%s) RETURNING history_id;",
                        (d['patient_id'],d['condition_name'],d['diagnosis_date'],d.get('notes')))
            nid = cur.fetchone()['history_id']; conn.commit()
            return jsonify({"status":"success","history_id":nid})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/medical-histories/<int:hid>', methods=['GET','PUT','DELETE'])
def history_one(hid):
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("SELECT * FROM patients.medical_history WHERE history_id=%s;", (hid,))
            row = cur.fetchone()
            if not row: return jsonify({"error":"not found"}), 404
            return jsonify(rows_to_json([row])[0])
        elif request.method == 'PUT':
            d = request.json
            cur.execute("UPDATE patients.medical_history SET patient_id=%s,condition_name=%s,diagnosis_date=%s,notes=%s WHERE history_id=%s;",
                        (d['patient_id'],d['condition_name'],d['diagnosis_date'],d.get('notes'),hid))
            conn.commit(); return jsonify({"status":"success"})
        else:
            cur.execute("DELETE FROM patients.medical_history WHERE history_id=%s;", (hid,))
            conn.commit(); return jsonify({"status":"success"})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# CRUD – Insurance
# ─────────────────────────────────────────────
@app.route('/api/insurances', methods=['GET','POST'])
def insurances():
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("""SELECT i.insurance_id,i.patient_id,i.provider_name,i.policy_number,i.coverage_type,i.expiration_date,
                                  p.first_name||' '||p.last_name AS patient_name
                           FROM patients.insurance i JOIN patients.patient p ON i.patient_id=p.patient_id
                           ORDER BY i.insurance_id DESC LIMIT 500;""")
            return jsonify(rows_to_json(cur.fetchall()))
        else:
            d = request.json
            cur.execute("INSERT INTO patients.insurance(patient_id,provider_name,policy_number,coverage_type,expiration_date) VALUES(%s,%s,%s,%s,%s) RETURNING insurance_id;",
                        (d['patient_id'],d['provider_name'],d['policy_number'],d['coverage_type'],d['expiration_date']))
            nid = cur.fetchone()['insurance_id']; conn.commit()
            return jsonify({"status":"success","insurance_id":nid})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/insurances/<int:iid>', methods=['GET','PUT','DELETE'])
def insurance_one(iid):
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("SELECT * FROM patients.insurance WHERE insurance_id=%s;", (iid,))
            row = cur.fetchone()
            if not row: return jsonify({"error":"not found"}), 404
            return jsonify(rows_to_json([row])[0])
        elif request.method == 'PUT':
            d = request.json
            cur.execute("UPDATE patients.insurance SET patient_id=%s,provider_name=%s,policy_number=%s,coverage_type=%s,expiration_date=%s WHERE insurance_id=%s;",
                        (d['patient_id'],d['provider_name'],d['policy_number'],d['coverage_type'],d['expiration_date'],iid))
            conn.commit(); return jsonify({"status":"success"})
        else:
            cur.execute("DELETE FROM patients.insurance WHERE insurance_id=%s;", (iid,))
            conn.commit(); return jsonify({"status":"success"})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# CRUD – Emergency Contacts
# ─────────────────────────────────────────────
@app.route('/api/emergency-contacts', methods=['GET','POST'])
def contacts():
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("""SELECT ec.contact_id,ec.patient_id,ec.name,ec.relationship,ec.phone,
                                  p.first_name||' '||p.last_name AS patient_name
                           FROM patients.emergency_contact ec JOIN patients.patient p ON ec.patient_id=p.patient_id
                           ORDER BY ec.contact_id DESC LIMIT 500;""")
            return jsonify(rows_to_json(cur.fetchall()))
        else:
            d = request.json
            cur.execute("INSERT INTO patients.emergency_contact(patient_id,name,relationship,phone) VALUES(%s,%s,%s,%s) RETURNING contact_id;",
                        (d['patient_id'],d['name'],d['relationship'],d['phone']))
            nid = cur.fetchone()['contact_id']; conn.commit()
            return jsonify({"status":"success","contact_id":nid})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/emergency-contacts/<int:cid>', methods=['GET','PUT','DELETE'])
def contact_one(cid):
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        if request.method == 'GET':
            cur.execute("SELECT * FROM patients.emergency_contact WHERE contact_id=%s;", (cid,))
            row = cur.fetchone()
            if not row: return jsonify({"error":"not found"}), 404
            return jsonify(rows_to_json([row])[0])
        elif request.method == 'PUT':
            d = request.json
            cur.execute("UPDATE patients.emergency_contact SET patient_id=%s,name=%s,relationship=%s,phone=%s WHERE contact_id=%s;",
                        (d['patient_id'],d['name'],d['relationship'],d['phone'],cid))
            conn.commit(); return jsonify({"status":"success"})
        else:
            cur.execute("DELETE FROM patients.emergency_contact WHERE contact_id=%s;", (cid,))
            conn.commit(); return jsonify({"status":"success"})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# Queries (Phase 2)
# ─────────────────────────────────────────────
@app.route('/api/queries/query1')
def query1():
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        cur.execute("""
            SELECT p.first_name, p.last_name, COUNT(a.admission_id) AS total_admissions
            FROM patients.patient p
            JOIN patients.allergy al ON p.patient_id = al.patient_id
            LEFT JOIN patients.admission a ON p.patient_id = a.patient_id
            WHERE al.severity = 'Life-threatening'
            GROUP BY p.patient_id, p.first_name, p.last_name
            ORDER BY total_admissions DESC;
        """)
        return jsonify(rows_to_json(cur.fetchall()))
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/queries/query5')
def query5():
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        cur.execute("""
            SELECT p.first_name AS patient_name, ec.name AS contact_person, ec.relationship, ec.phone
            FROM patients.patient p
            JOIN patients.admission a ON p.patient_id = a.patient_id
            JOIN patients.emergency_contact ec ON p.patient_id = ec.patient_id
            WHERE a.discharge_date IS NULL
            ORDER BY p.last_name;
        """)
        return jsonify(rows_to_json(cur.fetchall()))
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
# Phase 4 – Procedures & Functions
# ─────────────────────────────────────────────
@app.route('/api/procedures/evaluate_risk/<int:patient_id>', methods=['POST'])
def evaluate_risk(patient_id):
    conn = None
    try:
        conn = get_db(); cur = conn.cursor()
        cur.execute("SET search_path TO patients, public;")
        cur.execute("SELECT evaluate_patient_risk(%s) AS risk_level;", (patient_id,))
        res = cur.fetchone()
        conn.commit()
        return jsonify({"status":"success","risk_level": res['risk_level'] if res else "Unknown"})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

@app.route('/api/procedures/bulk_discharge', methods=['POST'])
def bulk_discharge():
    conn = None
    try:
        data = request.json
        keyword = data.get('keyword','').strip()
        if not keyword:
            return jsonify({"error":"חסרה מילת מפתח"}), 400
        conn = get_db(); cur = conn.cursor()
        cur.execute("SET search_path TO patients, public;")
        cur.execute("CALL bulk_discharge_patients(%s);", (keyword,))
        notices = conn.notices
        msg = notices[-1] if notices else "שחרור המוני בוצע בהצלחה."
        conn.commit()
        return jsonify({"status":"success","message": msg})
    except Exception as e:
        if conn: conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn: conn.close()

# ─────────────────────────────────────────────
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
