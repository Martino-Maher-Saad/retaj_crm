-- ==========================================
-- الدالة الذكية لمطابقة العقارات (Smart AI Match)
-- ==========================================

-- إنشاء الدالة الخاصة بمطابقة العقارات
CREATE OR REPLACE FUNCTION public.match_properties(
    query_embedding vector(1536),
    match_threshold float,
    match_count int,
    filter_property_type_id uuid DEFAULT NULL,
    filter_listing_type_id uuid DEFAULT NULL,
    filter_governorate_id int DEFAULT NULL,
    filter_city_id int DEFAULT NULL,
    filter_min_price numeric DEFAULT NULL,
    filter_max_price numeric DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    title_ar text,
    desc_ar text,
    price numeric,
    city_name text,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.title_ar,
        p.desc_ar,
        p.price,
        c.name as city_name,
        1 - (p.embedding <=> query_embedding) AS similarity
    FROM public.properties p
    LEFT JOIN public.cities c ON p.city_id = c.id
    WHERE
        p.is_active = true
        AND (filter_property_type_id IS NULL OR p.property_type_id = filter_property_type_id)
        AND (filter_listing_type_id IS NULL OR p.listing_type_id = filter_listing_type_id)
        AND (filter_governorate_id IS NULL OR p.governorate_id = filter_governorate_id)
        AND (filter_city_id IS NULL OR p.city_id = filter_city_id)
        AND (filter_min_price IS NULL OR p.price >= filter_min_price)
        AND (filter_max_price IS NULL OR p.price <= filter_max_price)
        -- التأكد من أن العقار لديه تقييم embedding
        AND p.embedding IS NOT NULL
        -- تصفية بناءً على نسبة التطابق
        AND 1 - (p.embedding <=> query_embedding) > match_threshold
    ORDER BY p.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
