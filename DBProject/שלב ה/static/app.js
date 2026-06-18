/* ==========================================================================
   Hospital Management System - Main Application Logic
   ========================================================================== */

// ── Global State ──────────────────────────────────────────────────────────────
var activeTab = 'dashboard';

// ── Startup ───────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function () {
    setupNavigation();
    loadDashboardStats();
    loadDropdowns();
    setupGlobalSearch();
});

// ── Navigation ────────────────────────────────────────────────────────────────
function setupNavigation() {
    var navItems = document.querySelectorAll('.nav-item');
    for (var i = 0; i < navItems.length; i++) {
        (function (item) {
            item.addEventListener('click', function (e) {
                e.preventDefault();
                switchTab(item.getAttribute('data-tab'));
            });
        })(navItems[i]);
    }
}

function switchTab(tabId) {
    activeTab = tabId;

    // Update sidebar active class
    var navItems = document.querySelectorAll('.nav-item');
    for (var i = 0; i < navItems.length; i++) {
        if (navItems[i].getAttribute('data-tab') === tabId) {
            navItems[i].classList.add('active');
        } else {
            navItems[i].classList.remove('active');
        }
    }

    // Show/hide tab panes
    var panes = document.querySelectorAll('.tab-pane');
    for (var i = 0; i < panes.length; i++) {
        if (panes[i].id === 'tab-' + tabId) {
            panes[i].classList.add('active');
        } else {
            panes[i].classList.remove('active');
        }
    }

    // Load relevant data
    if (tabId === 'dashboard') {
        loadDashboardStats();
    } else {
        fetchTableData(tabId);
    }
}

// ── Toast Notifications ───────────────────────────────────────────────────────
function showToast(message, type) {
    type = type || 'success';
    var container = document.getElementById('toast-container');
    var toast = document.createElement('div');
    toast.className = 'toast toast-' + type;
    var icon = type === 'error'
        ? '<i class="fa-solid fa-triangle-exclamation"></i>'
        : '<i class="fa-solid fa-circle-check"></i>';
    toast.innerHTML = icon + ' <span>' + message + '</span>';
    container.appendChild(toast);
    setTimeout(function () {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(-30px)';
        toast.style.transition = 'all 0.5s ease';
        setTimeout(function () { toast.remove(); }, 500);
    }, 4000);
}

// ── Global Search ─────────────────────────────────────────────────────────────
function setupGlobalSearch() {
    var el = document.getElementById('global-search');
    if (el) {
        el.addEventListener('input', function () {
            var q = el.value.toLowerCase();
            var tbody = document.querySelector('.tab-pane.active tbody');
            if (!tbody) return;
            var rows = tbody.querySelectorAll('tr');
            for (var i = 0; i < rows.length; i++) {
                var text = rows[i].textContent.toLowerCase();
                rows[i].style.display = text.indexOf(q) !== -1 ? '' : 'none';
            }
        });
    }
}

// ── Dashboard Stats ───────────────────────────────────────────────────────────
function loadDashboardStats() {
    fetch('/api/stats')
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (data.error) { showToast('שגיאה בטעינת סטטיסטיקות: ' + data.error, 'error'); return; }
            document.getElementById('stat-total-patients').innerText = data.total_patients;
            document.getElementById('stat-active-admissions').innerText = data.active_admissions;
            document.getElementById('stat-total-staff').innerText = data.total_staff;
            document.getElementById('stat-active-staff').innerText = data.active_staff;
        })
        .catch(function (e) { showToast('שגיאה בחיבור לשרת', 'error'); });
}

// ── Dropdowns ─────────────────────────────────────────────────────────────────
function loadDropdowns() {
    fetch('/api/patients/list')
        .then(function (r) { return r.json(); })
        .then(function (data) {
            var ids = ['adm_patient_id', 'all_patient_id', 'hist_patient_id', 'ins_patient_id', 'con_patient_id', 'risk-patient-select'];
            ids.forEach(function (id) {
                var sel = document.getElementById(id);
                if (!sel) return;
                var cur = sel.value;
                sel.innerHTML = '<option value="">-- בחר מטופל --</option>';
                data.forEach(function (p) {
                    var opt = document.createElement('option');
                    opt.value = p.patient_id;
                    opt.textContent = p.name + ' (#' + p.patient_id + ')';
                    sel.appendChild(opt);
                });
                sel.value = cur;
            });
        })
        .catch(function (e) { console.warn('patients list error', e); });

    fetch('/api/staff/list')
        .then(function (r) { return r.json(); })
        .then(function (data) {
            var sel = document.getElementById('p_staffid');
            if (!sel) return;
            var cur = sel.value;
            sel.innerHTML = '<option value="">ללא שיוך צוות</option>';
            data.forEach(function (s) {
                var opt = document.createElement('option');
                opt.value = s.staffid;
                opt.textContent = s.name + ' (#' + s.staffid + ')';
                sel.appendChild(opt);
            });
            sel.value = cur;
        })
        .catch(function (e) { console.warn('staff list error', e); });
}

// ── Table Data Fetch ──────────────────────────────────────────────────────────
function fetchTableData(tabId) {
    var endpoint = '/api/' + tabId;
    if (tabId === 'history')  endpoint = '/api/medical-histories';
    if (tabId === 'contacts') endpoint = '/api/emergency-contacts';
    if (tabId === 'insurance') endpoint = '/api/insurances';

    fetch(endpoint)
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (data.error) { showToast('שגיאה בטעינת נתונים: ' + data.error, 'error'); return; }
            renderTable(tabId, data);
        })
        .catch(function (e) { showToast('שגיאת תקשורת', 'error'); });
}

// ── Table Rendering ───────────────────────────────────────────────────────────
function renderTable(tabId, data) {
    var tbody = document.querySelector('#table-' + tabId + ' tbody');
    if (!tbody) return;
    tbody.innerHTML = '';

    if (!data || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="20" style="text-align:center;padding:32px;color:var(--text-muted);">אין רשומות להצגה</td></tr>';
        return;
    }

    data.forEach(function (row) {
        var tr = document.createElement('tr');
        var id = row.patient_id || row.staffid || row.admission_id || row.allergy_id || row.history_id || row.insurance_id || row.contact_id;

        var actionsHtml =
            '<td class="actions-cell">' +
            '<button class="btn btn-secondary btn-sm" onclick="editRecord(\'' + tabId + '\',' + id + ')">' +
            '<i class="fa-solid fa-pen"></i> ערוך</button> ' +
            '<button class="btn btn-danger btn-sm" onclick="deleteRecord(\'' + tabId + '\',' + id + ')">' +
            '<i class="fa-solid fa-trash"></i> מחק</button>' +
            '</td>';

        var cells = '';
        if (tabId === 'patients') {
            cells =
                '<td>#' + row.patient_id + '</td>' +
                '<td class="fw-bold">' + (row.first_name || '') + '</td>' +
                '<td>' + (row.last_name || '') + '</td>' +
                '<td>' + formatDate(row.date_of_birth) + '</td>' +
                '<td>' + genderHe(row.gender) + '</td>' +
                '<td>' + (row.phone || '') + '</td>' +
                '<td>' + (row.email || '') + '</td>' +
                '<td>' + (row.staff_name || '<span class="text-muted">אין שיוך</span>') + '</td>';
        } else if (tabId === 'staff') {
            cells =
                '<td>#' + row.staffid + '</td>' +
                '<td class="fw-bold">' + (row.firstname || '') + '</td>' +
                '<td>' + (row.lastname || '') + '</td>' +
                '<td>' + (row.idnumber || '') + '</td>' +
                '<td>' + (row.phone || '') + '</td>' +
                '<td>' + (row.email || '') + '</td>' +
                '<td><span class="status-indicator ' + (row.status || '').toLowerCase().replace(/ /g, '-') + '">' + (row.status || '') + '</span></td>' +
                '<td>' + formatDate(row.hiredate) + '</td>' +
                '<td>' + (row.deptid ? 'מח\' ' + row.deptid : 'כללי') + '</td>' +
                '<td>' + (row.roleid ? 'תפקיד ' + row.roleid : 'כללי') + '</td>';
        } else if (tabId === 'admissions') {
            cells =
                '<td>#' + row.admission_id + '</td>' +
                '<td class="fw-bold">' + (row.patient_name || '') + '</td>' +
                '<td>' + formatDateTime(row.admission_date) + '</td>' +
                '<td>' + (row.discharge_date ? formatDateTime(row.discharge_date) : '<span class="status-indicator active">מאושפז פעיל</span>') + '</td>' +
                '<td>' + (row.reason || '') + '</td>';
        } else if (tabId === 'allergies') {
            var sev = (row.severity || '').toLowerCase();
            cells =
                '<td>#' + row.allergy_id + '</td>' +
                '<td class="fw-bold">' + (row.patient_name || '') + '</td>' +
                '<td>' + (row.allergy_name || '') + '</td>' +
                '<td><span class="severity-badge ' + sev + '">' + (row.severity || '') + '</span></td>' +
                '<td>' + (row.notes || '') + '</td>';
        } else if (tabId === 'history') {
            cells =
                '<td>#' + row.history_id + '</td>' +
                '<td class="fw-bold">' + (row.patient_name || '') + '</td>' +
                '<td>' + (row.condition_name || '') + '</td>' +
                '<td>' + formatDate(row.diagnosis_date) + '</td>' +
                '<td>' + (row.notes || '') + '</td>';
        } else if (tabId === 'insurance') {
            cells =
                '<td>#' + row.insurance_id + '</td>' +
                '<td class="fw-bold">' + (row.patient_name || '') + '</td>' +
                '<td>' + (row.provider_name || '') + '</td>' +
                '<td><code>' + (row.policy_number || '') + '</code></td>' +
                '<td>' + (row.coverage_type || '') + '</td>' +
                '<td>' + formatDate(row.expiration_date) + '</td>';
        } else if (tabId === 'contacts') {
            cells =
                '<td>#' + row.contact_id + '</td>' +
                '<td class="fw-bold">' + (row.patient_name || '') + '</td>' +
                '<td>' + (row.name || '') + '</td>' +
                '<td>' + (row.relationship || '') + '</td>' +
                '<td>' + (row.phone || '') + '</td>';
        }

        tr.innerHTML = cells + actionsHtml;
        tbody.appendChild(tr);
    });
}

// ── Modal Management ──────────────────────────────────────────────────────────
function openModal(type) {
    loadDropdowns();

    var form = document.getElementById('form-' + type);
    if (form) form.reset();

    // Clear hidden IDs
    var hiddenId = document.getElementById(type + '_id');
    if (hiddenId) hiddenId.value = '';

    // For staff, un-readonly staffid
    var staffIdField = document.getElementById('s_staffid');
    if (staffIdField) staffIdField.removeAttribute('readonly');

    var title = document.getElementById(type + '-modal-title');
    if (title) title.innerText = 'רישום ' + heTitle(type) + ' חדש';

    document.getElementById('modal-backdrop').style.display = 'block';
    document.getElementById('modal-' + type).style.display = 'block';
}

function closeModal() {
    document.getElementById('modal-backdrop').style.display = 'none';
    var modals = document.querySelectorAll('.modal');
    for (var i = 0; i < modals.length; i++) {
        modals[i].style.display = 'none';
    }
}

// ── Edit Record ───────────────────────────────────────────────────────────────
function editRecord(type, id) {
    loadDropdowns();

    var endpoint = '/api/' + type;
    if (type === 'history')  endpoint = '/api/medical-histories';
    if (type === 'contacts') endpoint = '/api/emergency-contacts';
    if (type === 'insurance') endpoint = '/api/insurances';

    fetch(endpoint + '/' + id)
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (data.error) { showToast('שגיאה בטעינת הרשומה: ' + data.error, 'error'); return; }
            fillForm(type, data);
            var title = document.getElementById(type + '-modal-title');
            if (title) title.innerText = 'עדכון פרטי ' + heTitle(type);
            document.getElementById('modal-backdrop').style.display = 'block';
            document.getElementById('modal-' + type).style.display = 'block';
        })
        .catch(function (e) { showToast('שגיאה בטעינת הרשומה', 'error'); });
}

function fillForm(type, data) {
    function set(id, val) {
        var el = document.getElementById(id);
        if (el) el.value = (val === null || val === undefined) ? '' : val;
    }

    if (type === 'patient') {
        set('patient_id', data.patient_id);
        set('p_first_name', data.first_name);
        set('p_last_name', data.last_name);
        set('p_date_of_birth', data.date_of_birth);
        set('p_gender', data.gender);
        set('p_phone', data.phone);
        set('p_email', data.email);
        set('p_address', data.address);
        set('p_staffid', data.staffid || '');
    } else if (type === 'staff') {
        var staffIdField = document.getElementById('s_staffid');
        if (staffIdField) { staffIdField.value = data.staffid; staffIdField.setAttribute('readonly', 'true'); }
        set('s_idnumber', data.idnumber);
        set('s_firstname', data.firstname);
        set('s_lastname', data.lastname);
        set('s_phone', data.phone);
        set('s_email', data.email);
        set('s_status', data.status);
        set('s_hiredate', data.hiredate);
        set('s_deptid', data.deptid || '');
        set('s_roleid', data.roleid || '');
    } else if (type === 'admission') {
        set('admission_id', data.admission_id);
        set('adm_patient_id', data.patient_id);
        set('adm_admission_date', data.admission_date ? data.admission_date.substring(0, 16) : '');
        set('adm_discharge_date', data.discharge_date ? data.discharge_date.substring(0, 16) : '');
        set('adm_reason', data.reason);
    } else if (type === 'allergy') {
        set('allergy_id', data.allergy_id);
        set('all_patient_id', data.patient_id);
        set('all_allergy_name', data.allergy_name);
        set('all_severity', data.severity);
        set('all_notes', data.notes || '');
    } else if (type === 'history') {
        set('history_id', data.history_id);
        set('hist_patient_id', data.patient_id);
        set('hist_condition_name', data.condition_name);
        set('hist_diagnosis_date', data.diagnosis_date);
        set('hist_notes', data.notes || '');
    } else if (type === 'insurance') {
        set('insurance_id', data.insurance_id);
        set('ins_patient_id', data.patient_id);
        set('ins_provider_name', data.provider_name);
        set('ins_policy_number', data.policy_number);
        set('ins_coverage_type', data.coverage_type || '');
        set('ins_expiration_date', data.expiration_date);
    } else if (type === 'contact') {
        set('contact_id', data.contact_id);
        set('con_patient_id', data.patient_id);
        set('con_name', data.name);
        set('con_relationship', data.relationship);
        set('con_phone', data.phone);
    }
}

// ── Form Submit (Create / Update) ─────────────────────────────────────────────
function submitForm(event, type) {
    event.preventDefault();

    var formData = new FormData(event.target);
    var obj = {};
    formData.forEach(function (val, key) {
        obj[key] = val === '' ? null : val;
    });

    var endpoint = '/api/' + type;
    if (type === 'history')  endpoint = '/api/medical-histories';
    if (type === 'contacts') endpoint = '/api/emergency-contacts';
    if (type === 'insurance') endpoint = '/api/insurances';

    var method = 'POST';
    var id = null;

    if (type === 'staff') {
        var staffIdEl = document.getElementById('s_staffid');
        if (staffIdEl && staffIdEl.hasAttribute('readonly')) {
            method = 'PUT';
            id = obj['staffid'];
            endpoint += '/' + id;
        }
    } else {
        var hiddenId = document.getElementById(type + '_id');
        if (hiddenId && hiddenId.value) {
            method = 'PUT';
            id = hiddenId.value;
            endpoint += '/' + id;
        }
    }

    fetch(endpoint, {
        method: method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(obj)
    })
        .then(function (r) { return r.json(); })
        .then(function (res) {
            if (res.error) { showToast('שגיאה בשמירה: ' + res.error, 'error'); return; }
            showToast(method === 'POST' ? 'רשומה נוצרה בהצלחה!' : 'רשומה עודכנה בהצלחה!');
            closeModal();
            fetchTableData(activeTab);
        })
        .catch(function (e) { showToast('שגיאת שרת בשמירה', 'error'); });
}

// ── Delete Record ─────────────────────────────────────────────────────────────
function deleteRecord(type, id) {
    if (!confirm('האם למחוק רשומה זו?')) return;

    var endpoint = '/api/' + type;
    if (type === 'history')  endpoint = '/api/medical-histories';
    if (type === 'contacts') endpoint = '/api/emergency-contacts';
    if (type === 'insurance') endpoint = '/api/insurances';

    fetch(endpoint + '/' + id, { method: 'DELETE' })
        .then(function (r) { return r.json(); })
        .then(function (res) {
            if (res.error) { showToast('שגיאה במחיקה: ' + res.error, 'error'); return; }
            showToast('הרשומה נמחקה בהצלחה');
            fetchTableData(activeTab);
        })
        .catch(function (e) { showToast('שגיאה במחיקה', 'error'); });
}

// ── Queries ───────────────────────────────────────────────────────────────────
function executeSelectQuery(queryNum) {
    var out = document.getElementById('res-' + queryNum);
    out.innerHTML = '<span class="text-muted"><i class="fa-solid fa-spinner fa-spin"></i> מריץ שאילתה...</span>';

    fetch('/api/queries/' + queryNum)
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (data.error) { out.innerHTML = '<span style="color:var(--danger-color)">שגיאה: ' + data.error + '</span>'; return; }
            if (!data.length) { out.innerHTML = '<span class="text-muted">אין תוצאות.</span>'; return; }
            var keys = Object.keys(data[0]);
            var html = '<table class="query-results-table"><thead><tr>';
            keys.forEach(function (k) { html += '<th>' + heCol(k) + '</th>'; });
            html += '</tr></thead><tbody>';
            data.forEach(function (row) {
                html += '<tr>';
                keys.forEach(function (k) { html += '<td>' + (row[k] === null ? '-' : row[k]) + '</td>'; });
                html += '</tr>';
            });
            html += '</tbody></table>';
            out.innerHTML = html;
        })
        .catch(function () { out.innerHTML = '<span style="color:var(--danger-color)">שגיאת תקשורת</span>'; });
}

function executeEvaluateRisk() {
    var pid = document.getElementById('risk-patient-select').value;
    var out = document.getElementById('res-risk');
    if (!pid) { showToast('בחר מטופל תחילה', 'error'); return; }
    out.innerHTML = '<span class="text-muted"><i class="fa-solid fa-spinner fa-spin"></i> מחשב סיכון...</span>';
    fetch('/api/procedures/evaluate_risk/' + pid, { method: 'POST' })
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (data.error) { out.innerHTML = '<span style="color:var(--danger-color)">שגיאה: ' + data.error + '</span>'; return; }
            var lvl = data.risk_level || 'לא ידוע';
            var cls = lvl.indexOf('Critical') !== -1 ? 'life-threatening' : lvl.indexOf('Moderate') !== -1 ? 'moderate' : 'low';
            out.innerHTML = 'רמת סיכון: <span class="severity-badge ' + cls + '">' + lvl + '</span>';
            showToast('הערכת הסיכון הושלמה!');
        })
        .catch(function () { out.innerHTML = '<span style="color:var(--danger-color)">שגיאת שרת</span>'; });
}

function executeBulkDischarge() {
    var kw = document.getElementById('discharge-keyword').value.trim();
    var out = document.getElementById('res-discharge');
    if (!kw) { showToast('הזן מילת מפתח', 'error'); return; }
    out.innerHTML = '<span class="text-muted"><i class="fa-solid fa-spinner fa-spin"></i> מבצע שחרור...</span>';
    fetch('/api/procedures/bulk_discharge', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ keyword: kw })
    })
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (data.error) { out.innerHTML = '<span style="color:var(--danger-color)">שגיאה: ' + data.error + '</span>'; return; }
            out.innerHTML = '<span style="color:var(--success-color)">' + data.message + '</span>';
            showToast('שחרור המוני הושלם!');
        })
        .catch(function () { out.innerHTML = '<span style="color:var(--danger-color)">שגיאת תקשורת</span>'; });
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function formatDate(s) {
    if (!s) return '-';
    try {
        var d = new Date(s);
        return d.toLocaleDateString('he-IL');
    } catch (e) { return s; }
}

function formatDateTime(s) {
    if (!s) return '-';
    try {
        var d = new Date(s);
        return d.toLocaleString('he-IL', { dateStyle: 'short', timeStyle: 'short' });
    } catch (e) { return s; }
}

function genderHe(g) {
    if (g === 'Male') return 'זכר';
    if (g === 'Female') return 'נקבה';
    return g || '';
}

function heTitle(type) {
    var m = { patient: 'מטופל', staff: 'איש סגל', admission: 'אשפוז', allergy: 'אלרגיה', history: 'תיק רפואי', insurance: 'פוליסת ביטוח', contact: 'איש קשר' };
    return m[type] || type;
}

function heCol(col) {
    var m = { first_name: 'שם פרטי', last_name: 'שם משפחה', total_admissions: 'סה"כ אשפוזים', patient_name: 'שם מטופל', contact_person: 'איש קשר', relationship: 'קרבה', phone: 'טלפון' };
    return m[col] || col;
}
