-- ==========================================
-- الدالة الذكية لمطابقة العملاء (Smart AI Match for Leads)
-- ==========================================

-- إنشاء الدالة الخاصة بمطابقة العملاء
CREATE OR REPLACE FUNCTION public.match_leads(
    query_embedding vector(1536),
    match_threshold float,
    match_count int,
    filter_property_type_id uuid DEFAULT NULL,
    filter_listing_type_id uuid DEFAULT NULL,
    filter_governorate_id int DEFAULT NULL,
    filter_city_id int DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    client_name text,
    desc_lead_need text,
    city_name text,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id,
        l.client_name,
        l.desc_lead_need,
        c.name as city_name,
        1 - (l.embedding <=> query_embedding) AS similarity
    FROM public.leads l
    LEFT JOIN public.cities c ON l.city_id = c.id
    WHERE
        l.is_active = true
        AND (filter_property_type_id IS NULL OR l.property_type_id = filter_property_type_id)
        AND (filter_listing_type_id IS NULL OR l.listing_type_id = filter_listing_type_id)
        AND (filter_governorate_id IS NULL OR l.governorate_id = filter_governorate_id)
        AND (filter_city_id IS NULL OR l.city_id = filter_city_id)
        -- التأكد من أن العميل لديه تقييم embedding
        AND l.embedding IS NOT NULL
        -- تصفية بناءً على نسبة التطابق
        AND 1 - (l.embedding <=> query_embedding) > match_threshold
    ORDER BY l.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
