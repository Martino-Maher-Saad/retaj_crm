-- تنظيف الدالة القديمة لتفادي تعارضات التوقيع (Signature)
DROP FUNCTION IF EXISTS public.match_properties_with_filters(vector, double precision, integer, uuid, uuid, integer, integer, numeric, numeric, uuid, integer, uuid);
DROP FUNCTION IF EXISTS public.match_properties_with_filters(vector(384), double precision, integer, uuid, uuid, integer, integer, numeric, numeric, uuid, integer, uuid);

CREATE OR REPLACE FUNCTION public.match_properties_with_filters(
    query_embedding vector(384),
    match_threshold float DEFAULT 0.0,
    match_count int DEFAULT 10,
    filter_property_type_id uuid DEFAULT NULL,
    filter_listing_type_id uuid DEFAULT NULL,
    filter_governorate_id int DEFAULT NULL,
    filter_city_id int DEFAULT NULL,
    filter_min_price numeric DEFAULT NULL,
    filter_max_price numeric DEFAULT NULL,
    filter_created_by uuid DEFAULT NULL, -- تصفية الموظف (عقاراتي فقط)
    filter_offset int DEFAULT 0, -- إزاحة الترقيم (Pagination)
    filter_approval_status_id uuid DEFAULT NULL -- تصفية الحالة
)
RETURNS TABLE (
    id uuid,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        (1 - (p.embedding <=> query_embedding))::float AS similarity
    FROM public.properties p
    WHERE
        p.is_active = true
        AND (filter_approval_status_id IS NULL OR p.approval_status_id = filter_approval_status_id)
        AND (filter_created_by IS NULL OR p.created_by = filter_created_by)
        AND (filter_property_type_id IS NULL OR p.property_type_id = filter_property_type_id)
        AND (filter_listing_type_id IS NULL OR p.listing_type_id = filter_listing_type_id)
        AND (filter_governorate_id IS NULL OR p.governorate_id = filter_governorate_id)
        AND (filter_city_id IS NULL OR p.city_id = filter_city_id)
        AND (filter_min_price IS NULL OR p.price >= filter_min_price)
        AND (filter_max_price IS NULL OR p.price <= filter_max_price)
        AND p.embedding IS NOT NULL
    ORDER BY p.embedding <=> query_embedding
    LIMIT match_count
    OFFSET filter_offset;
END;
$$;

-- إنشاء الفهرس الذكي للبحث المتجهي لتسريع البحث باستخدام HNSW
CREATE INDEX IF NOT EXISTS properties_embedding_hnsw_idx 
ON public.properties 
USING hnsw (embedding vector_cosine_ops);
