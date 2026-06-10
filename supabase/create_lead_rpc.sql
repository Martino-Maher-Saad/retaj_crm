CREATE OR REPLACE FUNCTION create_lead_with_details(
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
  p_notes jsonb,
  p_budget_from integer DEFAULT NULL,
  p_budget_to integer DEFAULT NULL,
  p_exclusion_reason_id uuid DEFAULT NULL,
  p_is_pinned boolean DEFAULT false,
  p_is_archived boolean DEFAULT false,
  p_is_active boolean DEFAULT true
) RETURNS uuid AS $$
DECLARE
  v_lead_id uuid;
BEGIN
  -- 1. إضافة العميل
  INSERT INTO public.leads (
    client_name, assigned_to, created_by, status_id, platform_id,
    property_type_id, listing_type_id, channel_id, city_id, governorate_id,
    property_code, desc_lead_need, budget_from, budget_to, 
    exclusion_reason_id, is_pinned, is_archived, is_active
  ) VALUES (
    p_client_name, p_assigned_to, auth.uid(), p_status_id, p_platform_id,
    p_property_type_id, p_listing_type_id, p_channel_id, p_city_id, p_governorate_id,
    p_property_code, p_desc_lead_need, p_budget_from, p_budget_to,
    p_exclusion_reason_id, p_is_pinned, p_is_archived, p_is_active
  ) RETURNING id INTO v_lead_id;

  -- 2. إضافة الأرقام
  IF p_phones IS NOT NULL THEN
    INSERT INTO public.lead_phones (lead_id, phone_number, is_primary)
    SELECT
      v_lead_id,
      trim(value->>'phone_number'),
      COALESCE((value->>'is_primary')::boolean, false)
    FROM jsonb_array_elements(p_phones)
    WHERE trim(value->>'phone_number') != '';
  END IF;

  -- 3. إضافة الملاحظات
  IF p_notes IS NOT NULL THEN
    INSERT INTO public.lead_notes (lead_id, user_id, note_text)
    SELECT
      v_lead_id,
      auth.uid(),
      trim(value->>'note_text')
    FROM jsonb_array_elements(p_notes)
    WHERE trim(value->>'note_text') != '';
  END IF;

  RETURN v_lead_id;
END;
$$ LANGUAGE plpgsql;
