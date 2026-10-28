-- ============================================================================
-- RoamBite Production Upgrade Migration (00002_production_features.sql)
-- Adds support for:
-- 1. Extended User Profiles (avatar, DOB, anniversary, gender, veg_mode)
-- 2. Truck Profile Avatar & Prep/Walk Time
-- 3. Rich Video & Photo Reviews (Camera/Gallery uploads, duration, likes)
-- 4. Dynamic Zomato-style Hero Promotions table
-- 5. Saved/Bookmarked Trucks table
-- 6. Supabase Storage Bucket ('roambite-media') & RLS Policies for Camera/Gallery
-- ============================================================================

-- 1. EXTEND PROFILES TABLE
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS email TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS date_of_birth TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS anniversary TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS veg_mode BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. EXTEND TRUCKS TABLE
ALTER TABLE public.trucks
    ADD COLUMN IF NOT EXISTS profile_image_url TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS prep_time_walk_mins TEXT NOT NULL DEFAULT '6-10 mins';

-- 3. EXTEND REVIEWS TABLE FOR VIDEO REELS & PHOTO REVIEWS
ALTER TABLE public.reviews
    ADD COLUMN IF NOT EXISTS reviewer_name TEXT NOT NULL DEFAULT 'RoamBite Foodie',
    ADD COLUMN IF NOT EXISTS reviewer_avatar_url TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS media_url TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS video_url TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS is_video BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS media_caption TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS duration TEXT NOT NULL DEFAULT '0:15',
    ADD COLUMN IF NOT EXISTS likes_count INT NOT NULL DEFAULT 0;

-- 4. PROMOTIONS TABLE (Upper Zomato-style Animated Hero Promotions)
CREATE TABLE IF NOT EXISTS public.promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    truck_id UUID REFERENCES public.trucks(id) ON DELETE SET NULL,
    tag TEXT NOT NULL DEFAULT 'LIMITED TIME OFFER',
    headline_top TEXT NOT NULL,
    headline_bottom TEXT NOT NULL,
    subtext TEXT NOT NULL DEFAULT '',
    cta_text TEXT NOT NULL DEFAULT 'Order now',
    image_url TEXT NOT NULL,
    primary_color_hex TEXT NOT NULL DEFAULT '#D32F2F',
    secondary_color_hex TEXT NOT NULL DEFAULT '#8E1B1B',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Promotions are publicly readable" ON public.promotions;
CREATE POLICY "Promotions are publicly readable" ON public.promotions
    FOR SELECT USING (is_active = true);

-- 5. SAVED_TRUCKS TABLE (User Bookmarks / Collections)
CREATE TABLE IF NOT EXISTS public.saved_trucks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    truck_id UUID NOT NULL REFERENCES public.trucks(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, truck_id)
);

ALTER TABLE public.saved_trucks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their saved trucks" ON public.saved_trucks;
CREATE POLICY "Users can manage their saved trucks" ON public.saved_trucks
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 6. SUPABASE STORAGE BUCKET FOR CAMERA / GALLERY UPLOADS
-- Creates public bucket 'roambite-media' for dish photos, truck avatars, and review videos/photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('roambite-media', 'roambite-media', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public read access for roambite-media" ON storage.objects;
CREATE POLICY "Public read access for roambite-media"
ON storage.objects FOR SELECT
USING (bucket_id = 'roambite-media');

DROP POLICY IF EXISTS "Authenticated users can upload to roambite-media" ON storage.objects;
CREATE POLICY "Authenticated users can upload to roambite-media"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'roambite-media' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update own uploads in roambite-media" ON storage.objects;
CREATE POLICY "Users can update own uploads in roambite-media"
ON storage.objects FOR UPDATE
USING (bucket_id = 'roambite-media' AND auth.uid() = owner);

-- 7. HELPER RPC: UPSERT USER PROXIMITY ALERT RADIUS (Geofence System)
CREATE OR REPLACE FUNCTION public.upsert_user_alert_radius(
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_radius_miles NUMERIC,
    p_notify_enabled BOOLEAN,
    p_quiet_hours_enabled BOOLEAN DEFAULT TRUE
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_area_id UUID;
    v_radius_km NUMERIC(5,2) := ROUND(p_radius_miles * 1.60934, 2);
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    SELECT id INTO v_area_id FROM public.user_areas WHERE user_id = v_user_id LIMIT 1;

    IF v_area_id IS NULL THEN
        INSERT INTO public.user_areas (
            user_id, center, latitude, longitude, radius_km, notify_enabled, quiet_hours_start, quiet_hours_end
        ) VALUES (
            v_user_id,
            ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
            p_latitude,
            p_longitude,
            v_radius_km,
            p_notify_enabled,
            CASE WHEN p_quiet_hours_enabled THEN '22:00:00'::time ELSE '00:00:00'::time END,
            CASE WHEN p_quiet_hours_enabled THEN '08:00:00'::time ELSE '00:00:00'::time END
        ) RETURNING id INTO v_area_id;
    ELSE
        UPDATE public.user_areas
        SET center = ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
            latitude = p_latitude,
            longitude = p_longitude,
            radius_km = v_radius_km,
            notify_enabled = p_notify_enabled,
            quiet_hours_start = CASE WHEN p_quiet_hours_enabled THEN '22:00:00'::time ELSE '00:00:00'::time END,
            quiet_hours_end = CASE WHEN p_quiet_hours_enabled THEN '08:00:00'::time ELSE '00:00:00'::time END
        WHERE id = v_area_id;
    END IF;

    RETURN v_area_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
