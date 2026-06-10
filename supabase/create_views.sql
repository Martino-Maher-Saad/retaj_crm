-- 1. Create leads_view
CREATE OR REPLACE VIEW public.leads_view AS
SELECT 
    l.id,
    l.client_name,
    l.created_by,
    creator.first_name || ' ' || creator.last_name AS created_by_name,
    l.property_code,
    l.created_at,
    l.desc_lead_need,
    l.assigned_to,
    assignee.first_name || ' ' || assignee.last_name AS assigned_to_name,
    l.updated_at,
    l.status_id,
    ls.name_ar AS status_name,
    l.channel_id,
    cc.name_ar AS channel_name,
    l.property_type_id,
    pt.name_ar AS property_type_name,
    l.listing_type_id,
    lt.name_ar AS listing_type_name,
    l.platform_id,
    lp.name_ar AS platform_name,
    l.city_id,
    c.name AS city_name,
    l.governorate_id,
    g.name AS governorate_name,
    l.is_active,
    l.is_archived,
    l.exclusion_reason_id,
    ler.name_ar AS exclusion_reason_name,
    l.is_pinned,
    l.budget_from,
    l.budget_to
FROM public.leads l
LEFT JOIN public.profiles assignee ON l.assigned_to = assignee.id
LEFT JOIN public.profiles creator ON l.created_by = creator.id
LEFT JOIN public.lead_statuses ls ON l.status_id = ls.id
LEFT JOIN public.lead_platforms lp ON l.platform_id = lp.id
LEFT JOIN public.property_types pt ON l.property_type_id = pt.id
LEFT JOIN public.listing_types lt ON l.listing_type_id = lt.id
LEFT JOIN public.communication_channels cc ON l.channel_id = cc.id
LEFT JOIN public.cities c ON l.city_id = c.id
LEFT JOIN public.governorates g ON l.governorate_id = g.id
LEFT JOIN public.lead_exclusion_reasons ler ON l.exclusion_reason_id = ler.id;

-- 2. Create properties_view
CREATE OR REPLACE VIEW public.properties_view AS
SELECT 
    p.id,
    p.created_by,
    creator.first_name || ' ' || creator.last_name AS created_by_name,
    p.property_code,
    p.title_ar,
    p.desc_ar,
    p.region_ar,
    p.location_in_details,
    p.location_map,
    p.price,
    p.status,
    p.owner_name,
    p.owner_phone,
    p.created_at,
    p.internal_notes,
    p.property_type_id,
    pt.name_ar AS property_type_name,
    p.listing_type_id,
    lt.name_ar AS listing_type_name,
    p.source_id,
    s.name_ar AS source_name,
    p.city_id,
    c.name AS city_name,
    p.governorate_id,
    g.name AS governorate_name,
    p.is_active,
    p.approval_status_id,
    pas.name_ar AS approval_status_name,
    p.manager_notes,
    p.is_pinned
FROM public.properties p
LEFT JOIN public.profiles creator ON p.created_by = creator.id
LEFT JOIN public.property_types pt ON p.property_type_id = pt.id
LEFT JOIN public.listing_types lt ON p.listing_type_id = lt.id
LEFT JOIN public.property_sources s ON p.source_id = s.id
LEFT JOIN public.cities c ON p.city_id = c.id
LEFT JOIN public.governorates g ON p.governorate_id = g.id
LEFT JOIN public.property_approval_statuses pas ON p.approval_status_id = pas.id;
