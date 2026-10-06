# -*- coding: utf-8 -*-
"""
Retaj CRM - Unified Leads Consolidation and Preprocessing Script
=============================================================
يقوم هذا السكريبت بقراءة ملفات العملاء من المنصات الثلاث:
1. Property Finder (pf_leads.csv / pf_leads.xlsx)
2. Bayut / Dubizzle (bayut_leads.txt / bayut_leads.csv / bayut_leads.xlsx)
3. AqarMap (aqar_leads.csv / aqar_leads.xlsx / aqar_map_leads.csv)

قواعد المعالجة المتفق عليها:
----------------------------
1. Property Finder:
   - كود العقار منسق بالشكل القياسي: PREFIX-NUMBERS (حروف كابيتال + شرطة + أرقام).
   - استخراج عمود prefix كعمود مستقل.
   - البحث عن كود العقار في عقار ماب وبايوت، وفي حال وجوده يتم أخذ: نوع العقار، نوع الإعلان، المدينة، والمنطقة.
2. Bayut:
   - المدينة تؤخذ كما هي.
   - كود العقار فارغ، والـ prefix يتم استنتاجه من اسم الموظف إذا كان مسجلاً في منصة أخرى.
   - فصل نوع الإعلان: إذا وجد (ايجار/للايجار) -> "إيجار" (أو "إيجار مفروش" إن وجد مفروش)، وإذا وجد (بيع/للبيع) -> "بيع".
   - نوع العقار: باقي النص الحر كما هو (مثال: "شقة").
3. AqarMap:
   - نوع العقار والقسم يؤخذان كنص حر كما هما في الملف الأصلي.
   - المنطقة توضع في عمود "المنطقة الأصلية" وتوضع أيضاً في عمود "المدينة".
   - كود العقار منسق واستخراج الـ prefix منه.
   - اسم الموظف المفقود في عقار ماب يتم جلبه باستخدام الـ prefix من سجل الموظفين المشترك.
4. تصدير الملف الموحد: `unified_leads.csv` و `unified_leads.xlsx`.
"""

import os
import re
import json
import glob
import sys
from pathlib import Path
from datetime import datetime
import pandas as pd

if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

# ==============================================================================
# Helper Functions: Cleaning & Normalization
# ==============================================================================

ARABIC_MONTHS = {
    "يناير": 1, "فبراير": 2, "مارس": 3, "أبريل": 4, "ابريل": 4,
    "مايو": 5, "يونيو": 6, "يوليو": 7, "أغسطس": 8, "اغسطس": 8,
    "سبتمبر": 9, "أكتوبر": 10, "اكتوبر": 10, "نوفمبر": 11, "ديسمبر": 12
}

def clean_str(val):
    if val is None or pd.isna(val):
        return ""
    s = str(val).strip()
    if s.upper() in ["N/A", "N\\A", "NAN", "NULL", "NONE"]:
        return ""
    return re.sub(r'\s+', ' ', s)

def clean_client_name(name_val):
    """
    تنظيف اسم العميل:
    - إزالة أي رموز أو إيموجي أو علامات ترقيم
    - الإبقاء حصراً على: الحروف العربية، الحروف الإنجليزية، الأرقام، والمسافات
    - إزالة المسافات الزائدة
    """
    s = clean_str(name_val)
    if not s:
        return ""
    # استبدال أي رمز غير الحروف والأرقام والمسافات بمسافة
    cleaned = re.sub(r'[^\u0600-\u06FFA-Za-z0-9\s]', ' ', s)
    # تقليص المسافات المتعددة لمسافة واحدة
    cleaned = re.sub(r'\s+', ' ', cleaned).strip()
    return cleaned

def clean_employee_name(name_val):
    """
    تنظيف اسم الموظف:
    - إزالة المسافات في البداية والنهاية
    - تقليص المسافات بين الكلمات إلى مسافة واحدة فقط
    - تحويل كل الحروف إلى lowercase
    """
    s = clean_str(name_val)
    if not s:
        return ""
    return s.lower()

def clean_phone(phone_val):
    s = clean_str(phone_val)
    if not s:
        return ""
    has_plus = s.startswith("+")
    digits = re.sub(r'\D', '', s)
    if not digits:
        return ""
    return f"+{digits}" if has_plus else digits

def is_system_generated_code(s):
    """
    فحص إذا كان كود العقار كود نظام طويل أو هاش مثل 3A5YSGA6CG5BTDAPSJMGJ7QDP8
    """
    clean = str(s).strip()
    if len(clean) > 15:
        return True
    if clean and clean[0].isdigit():
        return True
    return False

def clean_property_code(code_val):
    """
    توحيد صيغة كود العقار إلى: [حروف كابيتال]-[أرقام] (مثل: HG-601, SY-4036, N-1147)
    مع الحفاظ على أكواد النظام الطويلة كما هي دون تشويه.
    """
    s = clean_str(code_val)
    if not s:
        return ""
    if is_system_generated_code(s):
        return s.strip().upper()
    m = re.search(r'^([A-Za-z]+)[\s._\-]*(\d+)', s)
    if m:
        prefix = m.group(1).upper()
        number = m.group(2)
        return f"{prefix}-{number}"
    return s.upper().strip()

def extract_code_prefix(code_val):
    """استخراج بادئة كود العقار (الحروف فقط بالإنجليزية الكبيرة)، مع تجاهل أكواد النظام"""
    cleaned = clean_property_code(code_val)
    if not cleaned or is_system_generated_code(cleaned):
        return ""
    if "-" in cleaned:
        return cleaned.split("-")[0]
    m = re.search(r'^[A-Z]+', cleaned)
    return m.group(0) if m else ""

def parse_arabic_date(text):
    """
    تحويل التواريخ العربية إلى ISO string
    """
    s = clean_str(text)
    if not s:
        return ""
    
    match_iso = re.search(r'(\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}:\d{2})?)', s)
    if match_iso:
        iso_str = match_iso.group(1).replace('T', ' ')
        if len(iso_str) == 10:
            iso_str += " 00:00:00"
        return iso_str

    pattern = r'([^\d\s,]+)\s+(\d{1,2}),?\s+(\d{4})\s*[\n\s]+(\d{1,2}):(\d{2})\s*(ص|م|am|pm)?'
    m = re.search(pattern, s, re.IGNORECASE)
    if m:
        month_name = m.group(1).strip()
        day = int(m.group(2))
        year = int(m.group(3))
        hour = int(m.group(4))
        minute = int(m.group(5))
        period = (m.group(6) or "").strip().lower()

        month = ARABIC_MONTHS.get(month_name, 1)

        if period in ["م", "pm"]:
            if hour < 12:
                hour += 12
        elif period in ["ص", "am"]:
            if hour == 12:
                hour = 0

        dt = datetime(year, month, day, hour, minute)
        return dt.strftime("%Y-%m-%d %H:%M:%S")

    return s

def parse_pf_date(text):
    """تحويل تواريخ بروبرتي فايندر وعقار ماب القياسية"""
    s = clean_str(text)
    if not s:
        return ""
    m = re.search(r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})', s)
    if m:
        return m.group(1)
    return parse_arabic_date(s)

def parse_bayut_property_free(raw_prop):
    """
    فصل نوع العقار ونوع الإعلان لمنصة بايوت مع الحفاظ على النص الحر:
    مثال: 'شقة للايجار' -> نوع العقار: 'شقة', نوع الإعلان: 'إيجار'
    مثال: 'شقة للبيع' -> نوع العقار: 'شقة', نوع الإعلان: 'بيع'
    مثال: 'شقة مفروشة للايجار' -> نوع العقار: 'شقة مفروشة', نوع الإعلان: 'إيجار مفروش'
    """
    s = clean_str(raw_prop)
    if not s:
        return "", ""

    s_lower = s.lower()
    is_furnished = any(k in s_lower for k in ["مفروش", "مفروشة"])
    is_rent = any(k in s_lower for k in ["ايجار", "إيجار", "للايجار", "للإيجار", "rent"])
    is_sale = any(k in s_lower for k in ["بيع", "للبيع", "شراء", "تمليك", "sale"])

    if is_rent and is_furnished:
        listing_type = "إيجار مفروش"
    elif is_rent:
        listing_type = "إيجار"
    elif is_sale:
        listing_type = "بيع"
    else:
        listing_type = ""

    # استخراج نوع العقار الحر بحذف كلمات الإعلان من النص
    cleaned = s
    for w in ["للايجار", "للإيجار", "ايجار", "إيجار", "للبيع", "بيع", "تمليك"]:
        cleaned = re.sub(rf'\b{w}\b', '', cleaned)
    cleaned = re.sub(r'\s+', ' ', cleaned).strip()

    return cleaned, listing_type

# ==============================================================================
# Platform Readers
# ==============================================================================

def find_file(directory, patterns):
    p = Path(directory)
    for pattern in patterns:
        matches = list(p.glob(pattern))
        if matches:
            matches.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            return matches[0]
    return None

def read_data_file(file_path):
    ext = file_path.suffix.lower()
    if ext in [".xlsx", ".xls"]:
        return pd.read_excel(file_path)
    elif ext == ".csv":
        try:
            return pd.read_csv(file_path, encoding="utf-8-sig")
        except UnicodeDecodeError:
            return pd.read_csv(file_path, encoding="cp1256")
    elif ext == ".txt":
        raw = file_path.read_text(encoding="utf-8").strip()
        try:
            return json.loads(raw)
        except Exception:
            return pd.read_csv(file_path, sep=None, engine="python", encoding="utf-8")
    return None

def process_pf_leads(file_path):
    """معالجة ملف بروبرتي فايندر Property Finder"""
    print(f"📖 جاري قراءة بروبرتي فايندر من: {file_path.name}")
    df = read_data_file(file_path)
    if df is None or len(df) == 0:
        return []

    df.columns = [str(c).strip().lower() for c in df.columns]

    leads = []
    for _, row in df.iterrows():
        date_raw = row.get("created_at", "")
        client_name = clean_client_name(row.get("sender_name", ""))
        phone = clean_phone(row.get("sender_phone", ""))
        if not phone:
            continue
        agent = clean_employee_name(row.get("agent_name", ""))
        prop_code = clean_property_code(row.get("listing_reference", row.get("reference", "")))
        prefix = extract_code_prefix(prop_code)

        leads.append({
            "التاريخ": parse_pf_date(date_raw),
            "اسم المنصة": "property finder",
            "اسم العميل": client_name,
            "رقم العميل": phone,
            "اسم الموظف": agent,
            "prefix": prefix,
            "كود العقار": prop_code,
            "نوع العقار": "",
            "نوع الاعلان": "",
            "المنطقة الأصلية": "",
            "المدينة": ""
        })

    print(f"   ✅ تم استخراج {len(leads)} عميل من بروبرتي فايندر.")
    return leads

def process_aqar_leads(file_path):
    """معالجة ملف عقار ماب AqarMap"""
    print(f"📖 جاري قراءة عقار ماب من: {file_path.name}")
    
    ext = file_path.suffix.lower()
    if ext == ".csv":
        try:
            with open(file_path, "r", encoding="utf-8-sig") as f:
                lines = f.readlines()
        except UnicodeDecodeError:
            with open(file_path, "r", encoding="cp1256") as f:
                lines = f.readlines()
        
        start_idx = 0
        for i, l in enumerate(lines[:10]):
            if "رقم الهاتف" in l or "إسم الإتصال" in l or "التاريخ" in l:
                start_idx = i
                break
        
        from io import StringIO
        clean_csv_content = "".join(lines[start_idx:])
        df = pd.read_csv(StringIO(clean_csv_content))
    else:
        df = pd.read_excel(file_path)

    df.columns = [str(c).strip() for c in df.columns]

    leads = []
    for _, row in df.iterrows():
        date_raw = row.get("التاريخ", "")
        client_name = clean_client_name(row.get("إسم الإتصال", row.get("اسم العميل", "")))
        phone = clean_phone(row.get("رقم الهاتف", ""))
        if not phone:
            continue
        # فحص كود العقار: إذا كان فارغاً أو N/A أو na يُسند تلقائياً لـ nora ashraf
        raw_code = str(row.get("الرقم المرجعى للإعلان", row.get("كود العقار", ""))).strip()
        is_empty_or_na = not raw_code or raw_code.lower() in ["n/a", "na", "#n/a", "n\\a", "nan", "none", "null"]

        if is_empty_or_na:
            agent = "nora ashraf"
            prop_code = ""
            prefix = ""
        else:
            agent = clean_employee_name(row.get("اسم الناشر", row.get("اسم الموظف", "")))
            prop_code = clean_property_code(raw_code)
            prefix = extract_code_prefix(prop_code)
        
        # أخذ نوع العقار والقسم كنص حر أصلي كما جاء من المنصة
        raw_prop_type = clean_str(row.get("نوع العقار", ""))
        raw_section = clean_str(row.get("القسم", ""))
        raw_area = clean_str(row.get("المنطقه", row.get("المنطقة", "")))

        leads.append({
            "التاريخ": parse_pf_date(date_raw),
            "اسم المنصة": "aqar map",
            "اسم العميل": client_name,
            "رقم العميل": phone,
            "اسم الموظف": agent,  # سيتم تعبئته لاحقاً بالـ prefix
            "prefix": prefix,
            "كود العقار": prop_code,
            "نوع العقار": raw_prop_type,
            "نوع الاعلان": raw_section,
            "المنطقة الأصلية": raw_area,
            "المدينة": raw_area  # وضع المنطقة أيضاً في المدينة ليتم مطابقتها في الـ CRM
        })

    print(f"   ✅ تم استخراج {len(leads)} عميل من عقار ماب.")
    return leads

def process_bayut_leads(file_path):
    """معالجة ملف بايوت / دوبيزل Bayut / Dubizzle"""
    print(f"📖 جاري قراءة بايوت من: {file_path.name}")
    leads = []
    
    if file_path.suffix.lower() == ".txt":
        raw = file_path.read_text(encoding="utf-8").strip()
        rows = json.loads(raw)
        
        for row in rows:
            if not row or len(row) < 4:
                continue
            
            date_cell = str(row[0])
            cust_cell = str(row[1])
            inquiry_cell = str(row[2])
            agent_cell = str(row[3])
            
            if date_cell.strip() == "التاريخ" or not any(row):
                continue
            
            phone_m = re.search(r'رقم الهاتف:\s*([+\d][\d\s\-]*)', cust_cell)
            phone = clean_phone(phone_m.group(1)) if phone_m else ""
            if not phone:
                continue
            
            client_name = ""
            cust_lines = [x.strip() for x in cust_cell.splitlines() if x.strip()]
            for i, line in enumerate(cust_lines):
                if line == "الواتساب" and i + 1 < len(cust_lines):
                    client_name = cust_lines[i + 1]
                    break
            if not client_name and cust_lines:
                client_name = cust_lines[0]
            
            agent = ""
            agent_lines = [x.strip() for x in agent_cell.splitlines() if x.strip()]
            for l in agent_lines:
                if "@" not in l and l != "ايميل:":
                    agent = l
                    break
            agent = clean_employee_name(agent)
            
            inq_lines = [x.strip() for x in inquiry_cell.splitlines() if x.strip()]
            first_line = inq_lines[0] if inq_lines else ""
            second_line = inq_lines[1] if len(inq_lines) > 1 else ""
            
            property_type, listing_type = parse_bayut_property_free(first_line)
            raw_city = second_line

            leads.append({
                "التاريخ": parse_arabic_date(date_cell),
                "اسم المنصة": "bayut",
                "اسم العميل": clean_client_name(client_name),
                "رقم العميل": phone,
                "اسم الموظف": agent,
                "prefix": "",
                "كود العقار": "",
                "نوع العقار": property_type,
                "نوع الاعلان": listing_type,
                "المنطقة الأصلية": "",
                "المدينة": raw_city
            })

    else:
        df = read_data_file(file_path)
        df.columns = [str(c).strip() for c in df.columns]
        
        for _, row in df.iterrows():
            date_raw = row.get("التاريخ", "")
            phone = clean_phone(row.get("رقم العميل", row.get("رقم الهاتف", "")))
            if not phone:
                continue
            client_name = clean_client_name(row.get("اسم العميل", ""))
            agent = clean_employee_name(row.get("اسم الموظف", ""))
            
            prop_raw = clean_str(row.get("نوع العقار", ""))
            property_type, listing_type = parse_bayut_property_free(prop_raw)
            
            raw_city = clean_str(row.get("المدينة", row.get("المنطقة", "")))

            leads.append({
                "التاريخ": parse_arabic_date(date_raw),
                "اسم المنصة": "bayut",
                "اسم العميل": client_name,
                "رقم العميل": phone,
                "اسم الموظف": agent,
                "prefix": "",
                "كود العقار": "",
                "نوع العقار": property_type,
                "نوع الاعلان": listing_type,
                "المنطقة الأصلية": "",
                "المدينة": raw_city
            })

    print(f"   ✅ تم استخراج {len(leads)} عميل من بايوت.")
    return leads

# ==============================================================================
# Intelligence: Cross-Platform Prefix & Property Linking
# ==============================================================================

def link_prefixes_and_agents(leads):
    """
    تم إيقاف الربط والخلط بين المنصات:
    - كل صف يعتمد حصراً على كوده الخاص وبريفكسه الخاص.
    - بايوت يظل دائماً بـ prefix وكود عقار فارغين.
    """
    return leads

def enrich_pf_leads_from_other_platforms(leads):
    """
    البحث عن كود العقار لعملاء Property Finder في باقي المنصات (عقار ماب).
    في حال تطابق كود العقار: يتم نسخ (نوع العقار، نوع الإعلان، المدينة، والمنطقة الأصلية) تلقائياً.
    """
    property_catalog = {}
    
    for lead in leads:
        if lead.get("اسم المنصة", "").lower() == "property finder":
            continue
        
        code = lead.get("كود العقار", "").strip()
        if not code:
            continue
        
        p_type = lead.get("نوع العقار", "").strip()
        l_type = lead.get("نوع الاعلان", "").strip()
        city = lead.get("المدينة", "").strip()
        area = lead.get("المنطقة الأصلية", "").strip()

        if code not in property_catalog:
            property_catalog[code] = {
                "نوع العقار": p_type,
                "نوع الاعلان": l_type,
                "المدينة": city,
                "المنطقة الأصلية": area
            }

    matched_count = 0
    pf_total = 0

    for lead in leads:
        if lead.get("اسم المنصة", "").lower() == "property finder":
            pf_total += 1
            code = lead.get("كود العقار", "").strip()
            
            if code and code in property_catalog:
                matched_info = property_catalog[code]
                updated = False
                
                if not lead["المدينة"] and matched_info["المدينة"]:
                    lead["المدينة"] = matched_info["المدينة"]
                    updated = True
                
                if not lead["نوع العقار"] and matched_info["نوع العقار"]:
                    lead["نوع العقار"] = matched_info["نوع العقار"]
                    updated = True
                
                if not lead["نوع الاعلان"] and matched_info["نوع الاعلان"]:
                    lead["نوع الاعلان"] = matched_info["نوع الاعلان"]
                    updated = True
                
                if not lead["المنطقة الأصلية"] and matched_info["المنطقة الأصلية"]:
                    lead["المنطقة الأصلية"] = matched_info["المنطقة الأصلية"]
                    updated = True
                
                if updated:
                    matched_count += 1

    print("\n" + "=" * 60)
    print("🔗 نتيجة المطابقة الذكية لأكواد العقارات (Cross-Platform Enrichment):")
    print(f"   • إجمالي أكواد العقارات المسجلة في عقار ماب: {len(property_catalog)} كود")
    print(f"   • تم بنجاح إثراء {matched_count} عميل من Property Finder بنوع العقار والإعلان والمدينة والمنطقة!")
    print("=" * 60)

    return leads

# ==============================================================================
# Main Orchestrator
def _fix_xlsx_compatibility(xlsx_path):
    """
    إصلاح توافقية ملف الإكسيل مع محركات قراءة Excel في Flutter (OpenXML Relationships & Empty inlineStr).
    """
    import zipfile, io
    buf = io.BytesIO()
    with zipfile.ZipFile(xlsx_path, 'r') as zin:
        with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                data = zin.read(item.filename)
                if item.filename == 'xl/_rels/workbook.xml.rels':
                    text = data.decode('utf-8')
                    text = text.replace('Target="/xl/', 'Target="')
                    data = text.encode('utf-8')
                elif item.filename.startswith('xl/worksheets/') and item.filename.endswith('.xml'):
                    text = data.decode('utf-8')
                    text = re.sub(r'<c\s+([^>]*?)t=["\']inlineStr["\']\s*>\s*</c>', r'<c \1></c>', text)
                    text = re.sub(r'<c\s+([^>]*?)t=["\']inlineStr["\']\s*/>', r'<c \1/>', text)
                    data = text.encode('utf-8')
                zout.writestr(item, data)
    with open(xlsx_path, 'wb') as f:
        f.write(buf.getvalue())

# ==============================================================================

def main():
    print("=" * 60)
    print("🚀 بدء تجميع ومعالجة ملفات الـ Leads لـ Retaj CRM")
    print("=" * 60)

    work_dir = Path("C:/Users/marti/Retaj")
    if not work_dir.exists():
        work_dir = Path(".")
    
    pf_file = find_file(work_dir, [
        "pf_leads.xlsx", "pf_leads.csv", "*pf_leads*.csv", "*pf_leads*.xlsx"
    ])
    aqar_file = find_file(work_dir, [
        "aqar_leads.xlsx", "aqar_leads.csv", "*aqar*.csv", "*aqar*.xlsx"
    ])
    bayut_file = find_file(work_dir, [
        "bayut_leads.txt", "bayut_leads.xlsx", "bayut_leads.csv", "*bayut*.txt", "*bayut*.csv", "*bayut*.xlsx"
    ])

    all_leads = []

    if pf_file and pf_file.exists():
        all_leads.extend(process_pf_leads(pf_file))
    else:
        print("⚠️ لم يتم العثور على ملف لـ Property Finder (pf_leads)")

    if aqar_file and aqar_file.exists():
        all_leads.extend(process_aqar_leads(aqar_file))
    else:
        print("⚠️ لم يتم العثور على ملف لـ AqarMap (aqar_leads)")

    if bayut_file and bayut_file.exists():
        all_leads.extend(process_bayut_leads(bayut_file))
    else:
        print("⚠️ لم يتم العثور على ملف لـ Bayut (bayut_leads)")

    total_extracted = len(all_leads)
    print("\n" + "-" * 60)
    print(f"📊 إجمالي العملاء المستخرجين من الملفات: {total_extracted}")
    print("-" * 60)

    if total_extracted == 0:
        print("❌ لم يتم استخراج أي بيانات. تأكد من وجود الملفات بالأسماء المطلوبة.")
        return

    # 1. الربط التبادلي للـ prefix وأسماء الموظفين (استنتاج الموظف لعقار ماب، وتعبئة prefix لبايوت)
    all_leads = link_prefixes_and_agents(all_leads)

    # 2. إثراء عقارات Property Finder بالمدينة ونوع العقار والإعلان من عقار ماب
    all_leads = enrich_pf_leads_from_other_platforms(all_leads)

    # 3. إزالة التكرار الذكية حسب طبيعة كل منصة
    # فرز جميع العملاء تنازلياً حسب التاريخ لضمان أسبقية وأخذ الأحدث دائماً
    all_leads.sort(key=lambda x: str(x.get("التاريخ", "")), reverse=True)

    unique_leads = []
    seen_keys = set()
    duplicates_count = 0

    for lead in all_leads:
        phone = lead["رقم العميل"]
        employee = lead["اسم الموظف"].strip().lower()
        platform = lead["اسم المنصة"].strip().lower()
        property_code = lead["كود العقار"].strip()
        
        dt_full = lead["التاريخ"]
        date_day = dt_full[:10] if len(dt_full) >= 10 else dt_full
        
        # 1. عقار ماب بكود عقار حقيقي: التكرار فقط لو نفس العميل على نفس العقار في نفس اليوم
        if platform == "aqar map" and property_code:
            unique_key = (phone, date_day, "aqar map", property_code)
        # 2. عقار ماب بدون كود عقار (حالة نورا أشرف): التكرار لنفس العميل مع نورا أشرف في نفس اليوم
        elif platform == "aqar map" and not property_code:
            unique_key = (phone, date_day, "aqar map", "nora ashraf")
        # 3. باقي المنصات (بروبرتي فايندر وبايوت): التكرار لنفس العميل مع نفس الموظف في نفس اليوم
        else:
            unique_key = (phone, date_day, employee if employee else platform)

        if phone and unique_key in seen_keys:
            duplicates_count += 1
            continue
        
        if phone:
            seen_keys.add(unique_key)
        
        unique_leads.append(lead)

    print(f"🔍 تم اكتشاف {duplicates_count} صف مكرر في نفس اليوم وتم استبعادهم.")
    print(f"✨ عدد العملاء النهائي الصافي: {len(unique_leads)}")

    # 4. تصدير الملف النهائي الموحد مع عمود prefix الجديد
    final_df = pd.DataFrame(unique_leads)
    
    ordered_columns = [
        "التاريخ",
        "اسم المنصة",
        "اسم العميل",
        "رقم العميل",
        "اسم الموظف",
        "prefix",
        "كود العقار",
        "نوع العقار",
        "نوع الاعلان",
        "المنطقة الأصلية",
        "المدينة"
    ]
    final_df = final_df[ordered_columns]

    output_csv = work_dir / "unified_leads.csv"
    output_excel = work_dir / "unified_leads.xlsx"

    final_df.to_csv(output_csv, index=False, encoding="utf-8-sig")
    
    try:
        final_df.to_excel(output_excel, index=False)
        # إصلاح التوافقية التامة مع محركات قراءة Excel في فلاتر
        _fix_xlsx_compatibility(output_excel)
        print(f"💾 تم حفظ ملف الإكسيل المتوافق تماماً: {output_excel.resolve()}")
    except Exception as e:
        print(f"تعذر حفظ ملف xlsx: {e}")

    print(f"💾 تم حفظ ملف CSV: {output_csv.resolve()}")
    print("=" * 60)
    print("🎉 اكتملت العملية بنجاح! الملف جاهز للرفع إلى سيستم Retaj CRM.")
    print("=" * 60)

if __name__ == "__main__":
    main()
