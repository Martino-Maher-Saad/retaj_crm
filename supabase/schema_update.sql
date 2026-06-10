-- 1. Create Lookup Tables
CREATE TABLE public.lead_exclusion_reasons (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name_ar text NOT NULL UNIQUE,
  created_at timestamp with time zone DEFAULT now(),
  is_active boolean DEFAULT true,
  CONSTRAINT lead_exclusion_reasons_pkey PRIMARY KEY (id)
);

CREATE TABLE public.property_approval_statuses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name_ar text NOT NULL UNIQUE,
  created_at timestamp with time zone DEFAULT now(),
  is_active boolean DEFAULT true,
  CONSTRAINT property_approval_statuses_pkey PRIMARY KEY (id)
);

-- Insert Default Values for approval statuses
INSERT INTO public.property_approval_statuses (name_ar) VALUES
('قيد المراجعة'),
('مرفوض'),
('تمت الموافقة'),
('تم النشر');

-- 2. Alter leads table
ALTER TABLE public.leads
  DROP COLUMN IF EXISTS client_phone,
  DROP COLUMN IF EXISTS city,
  DROP COLUMN IF EXISTS lead_status,
  DROP COLUMN IF EXISTS communication_channel,
  DROP COLUMN IF EXISTS platform,
  DROP COLUMN IF EXISTS history,
  DROP COLUMN IF EXISTS property_type,
  DROP COLUMN IF EXISTS listing_type,
  DROP COLUMN IF EXISTS governorate,
  
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS is_archived boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS exclusion_reason_id uuid REFERENCES public.lead_exclusion_reasons(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS embedding public.vector,
  ADD COLUMN IF NOT EXISTS is_pinned boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS budget_from integer,
  ADD COLUMN IF NOT EXISTS budget_to integer;

-- 3. Update properties search trigger BEFORE modifying the table
CREATE OR REPLACE FUNCTION properties_search_trigger()
RETURNS trigger AS $$
DECLARE
  gov_name text;
  city_name text;
BEGIN
  -- جلب الأسماء من الـ ID لتخزينها في البحث
  SELECT name INTO gov_name FROM governorates WHERE id = NEW.governorate_id;
  SELECT name INTO city_name FROM cities WHERE id = NEW.city_id;
  
  NEW.search_vector :=
    to_tsvector('arabic', coalesce(NEW.desc_ar, ''))              ||
    to_tsvector('arabic', coalesce(gov_name, ''))                 ||
    to_tsvector('arabic', coalesce(city_name, ''))                ||
    to_tsvector('arabic', coalesce(NEW.region_ar, ''))            ||
    to_tsvector('arabic', coalesce(NEW.location_in_details, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Alter properties table
ALTER TABLE public.properties
  DROP COLUMN IF EXISTS listing_type_ar,
  DROP COLUMN IF EXISTS property_type_ar,
  DROP COLUMN IF EXISTS governorate_ar,
  DROP COLUMN IF EXISTS city_ar,
  DROP COLUMN IF EXISTS platforms,
  DROP COLUMN IF EXISTS source,

  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS approval_status_id uuid REFERENCES public.property_approval_statuses(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS manager_notes text,
  ADD COLUMN IF NOT EXISTS is_pinned boolean DEFAULT false;

-- Assign default approval status 'pending' to existing properties
UPDATE public.properties 
SET approval_status_id = (SELECT id FROM public.property_approval_statuses WHERE name_ar = 'قيد المراجعة' LIMIT 1) 
WHERE approval_status_id IS NULL;

-- 4. Alter property_platforms
ALTER TABLE public.property_platforms
  ADD COLUMN IF NOT EXISTS is_published boolean DEFAULT false;

-- 5. Create Many-to-Many Tables
CREATE TABLE public.lead_property_interests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT lead_property_interests_pkey PRIMARY KEY (id),
  CONSTRAINT unique_lead_property_interest UNIQUE (lead_id, property_id)
);

CREATE TABLE public.property_shares (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT property_shares_pkey PRIMARY KEY (id)
);

-- 6. (تم نقل الدالة لأعلى لحل مشكلة التحديث)

-- 7. Update update_lead_with_details RPC
CREATE OR REPLACE FUNCTION update_lead_with_details(
  p_lead_id uuid,
  p_client_name text,
  p_assigned_to uuid,
  p_status_id uuid,
  p_platform_id uuid,
  p_property_type_id uuid,
  p_listing_type_id uuid,
  p_channel_id uuid,
  p_city_id integer,
  p_governorate_id integer,
  p_property_code text,
  p_desc_lead_need text,
  p_phones jsonb,
  p_new_note text,
  p_budget_from integer DEFAULT NULL,
  p_budget_to integer DEFAULT NULL,
  p_exclusion_reason_id uuid DEFAULT NULL,
  p_is_pinned boolean DEFAULT false,
  p_is_archived boolean DEFAULT false,
  p_is_active boolean DEFAULT true,
  p_transferred_from uuid DEFAULT NULL
) RETURNS uuid AS $$
DECLARE
  old_status uuid;
  old_assigned uuid;
BEGIN
  SELECT status_id, assigned_to INTO old_status, old_assigned
  FROM public.leads WHERE id = p_lead_id;

  -- 1. تحديث بيانات العميل
  UPDATE public.leads SET
    client_name      = p_client_name,
    assigned_to      = p_assigned_to,
    status_id        = p_status_id,
    platform_id      = p_platform_id,
    property_type_id = p_property_type_id,
    listing_type_id  = p_listing_type_id,
    channel_id       = p_channel_id,
    city_id          = p_city_id,
    governorate_id   = p_governorate_id,
    property_code    = p_property_code,
    desc_lead_need   = p_desc_lead_need,
    budget_from      = p_budget_from,
    budget_to        = p_budget_to,
    exclusion_reason_id = p_exclusion_reason_id,
    is_pinned        = p_is_pinned,
    is_archived      = p_is_archived,
    is_active        = p_is_active,
    transferred_from = CASE
      WHEN p_status_id IS DISTINCT FROM old_status THEN NULL
      WHEN p_transferred_from IS NOT NULL THEN p_transferred_from
      WHEN p_assigned_to IS DISTINCT FROM old_assigned THEN old_assigned
      ELSE transferred_from
    END,
    status_updated_at = CASE
      WHEN p_status_id IS DISTINCT FROM old_status THEN now()
      ELSE status_updated_at
    END,
    updated_at       = now()
  WHERE id = p_lead_id;

  -- 2. Smart Phone Sync
  -- حذف الأرقام اللي اتشالت من الفورم
  DELETE FROM public.lead_phones
  WHERE lead_id = p_lead_id
    AND phone_number NOT IN (
      SELECT value->>'phone_number'
      FROM jsonb_array_elements(p_phones)
      WHERE trim(value->>'phone_number') != ''
    );

  -- إضافة الأرقام الجديدة فقط (اللي مش موجودة في الـ DB)
  INSERT INTO public.lead_phones (lead_id, phone_number, is_primary)
  SELECT
    p_lead_id,
    trim(value->>'phone_number'),
    COALESCE((value->>'is_primary')::boolean, false)
  FROM jsonb_array_elements(p_phones)
  WHERE trim(value->>'phone_number') != ''
    AND trim(value->>'phone_number') NOT IN (
      SELECT phone_number FROM public.lead_phones WHERE lead_id = p_lead_id
    );

  -- تحديث is_primary لو اتغير لرقم موجود
  UPDATE public.lead_phones lp
  SET is_primary = COALESCE((p.value->>'is_primary')::boolean, false)
  FROM jsonb_array_elements(p_phones) p
  WHERE lp.lead_id = p_lead_id
    AND lp.phone_number = trim(p.value->>'phone_number')
    AND lp.is_primary IS DISTINCT FROM COALESCE((p.value->>'is_primary')::boolean, false);

  -- 3. إضافة ملاحظة جديدة لو مش فاضية
  IF p_new_note IS NOT NULL AND trim(p_new_note) != '' THEN
    INSERT INTO public.lead_notes (lead_id, user_id, note_text)
    VALUES (p_lead_id, auth.uid(), trim(p_new_note));
  END IF;

  RETURN p_lead_id;
END;
$$ LANGUAGE plpgsql;

-- 8. RPC: Check lead duplicate phone
CREATE OR REPLACE FUNCTION check_lead_phone_duplicate(p_phone text)
RETURNS TABLE (
  is_duplicate boolean,
  duplicate_count bigint,
  added_by_names jsonb
) AS $$
BEGIN
  RETURN QUERY
  WITH duplicates AS (
    SELECT l.id, p.first_name || ' ' || p.last_name AS employee_name
    FROM public.lead_phones lp
    JOIN public.leads l ON l.id = lp.lead_id
    JOIN public.profiles p ON p.id = l.created_by
    WHERE lp.phone_number LIKE '%' || p_phone
       OR p_phone LIKE '%' || lp.phone_number
  )
  SELECT 
    COUNT(*) > 0 AS is_duplicate,
    COUNT(*) AS duplicate_count,
    jsonb_agg(employee_name) AS added_by_names
  FROM duplicates;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. RPC: Check property owner phone duplicate
CREATE OR REPLACE FUNCTION check_property_owner_phone_duplicate(p_phone text)
RETURNS TABLE (
  is_duplicate boolean,
  duplicate_count bigint,
  added_by_names jsonb
) AS $$
BEGIN
  RETURN QUERY
  WITH duplicates AS (
    SELECT pr.id, p.first_name || ' ' || p.last_name AS employee_name
    FROM public.properties pr
    JOIN public.profiles p ON p.id = pr.created_by
    WHERE pr.owner_phone LIKE '%' || p_phone
       OR p_phone LIKE '%' || pr.owner_phone
  )
  SELECT 
    COUNT(*) > 0 AS is_duplicate,
    COUNT(*) AS duplicate_count,
    jsonb_agg(employee_name) AS added_by_names
  FROM duplicates;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Auto Archive Leads Function (for pg_cron)
CREATE OR REPLACE FUNCTION auto_archive_leads()
RETURNS void AS $$
BEGIN
  -- إيجار: أسبوعين (14 يوم) بدون تحديث
  UPDATE public.leads
  SET is_archived = true
  WHERE is_active = true 
    AND is_archived = false
    AND listing_type_id = (SELECT id FROM listing_types WHERE name_ar = 'إيجار' LIMIT 1)
    AND updated_at < now() - interval '14 days';

  -- بيع: شهرين (60 يوم) بدون تحديث
  UPDATE public.leads
  SET is_archived = true
  WHERE is_active = true 
    AND is_archived = false
    AND listing_type_id = (SELECT id FROM listing_types WHERE name_ar = 'بيع' LIMIT 1)
    AND updated_at < now() - interval '60 days';
END;
$$ LANGUAGE plpgsql;

-- (اختياري) تفعيل المجدول إذا كانت الإضافة pg_cron مفعلة في Supabase:
-- SELECT cron.schedule('auto-archive-leads', '0 0 * * *', 'SELECT auto_archive_leads();');
