-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 1. PROFILES TABLE
-- Roles: 'foodie' or 'truck_owner'
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('foodie', 'truck_owner')),
    phone TEXT,
    display_name TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. TRUCKS TABLE
CREATE TABLE IF NOT EXISTS public.trucks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    tagline TEXT NOT NULL DEFAULT '',
    cuisine TEXT NOT NULL,
    signature_dish TEXT NOT NULL DEFAULT '',
    price_range TEXT NOT NULL DEFAULT '$' CHECK (price_range IN ('$', '$$', '$$$')),
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    hero_image_url TEXT,
    is_sponsored BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. TRUCK_LOCATIONS TABLE
-- Tracks live broadcast pings. Pin expires 15 minutes after recorded_at if not renewed.
CREATE TABLE IF NOT EXISTS public.truck_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    truck_id UUID NOT NULL REFERENCES public.trucks(id) ON DELETE CASCADE,
    geog GEOGRAPHY(POINT, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_live BOOLEAN NOT NULL DEFAULT TRUE,
    live_until TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '15 minutes'),
    status TEXT NOT NULL DEFAULT 'serving_now' CHECK (status IN ('serving_now', 'on_the_move', 'closed'))
);

-- 4. MENUS TABLE
-- JSONB items list with menu_version increment on edit for client cache busting
CREATE TABLE IF NOT EXISTS public.menus (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    truck_id UUID NOT NULL UNIQUE REFERENCES public.trucks(id) ON DELETE CASCADE,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    menu_version INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. REVIEWS TABLE
-- verified_visit = true if reviewer was within 200m of truck live pin within +-2 hours
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    truck_id UUID NOT NULL REFERENCES public.trucks(id) ON DELETE CASCADE,
    rating NUMERIC(2,1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    text TEXT NOT NULL,
    verified_visit BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. USER_AREAS TABLE
-- Subscribed areas for live arrival push notifications
CREATE TABLE IF NOT EXISTS public.user_areas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    center GEOGRAPHY(POINT, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_km NUMERIC(5,2) NOT NULL DEFAULT 5.00,
    notify_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    quiet_hours_start TIME NOT NULL DEFAULT '22:00:00',
    quiet_hours_end TIME NOT NULL DEFAULT '08:00:00',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. NOTIFICATIONS_LOG TABLE
-- Idempotency key: hash(user_id, truck_id, area_id, date)
CREATE TABLE IF NOT EXISTS public.notifications_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dedup_key TEXT NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    truck_id UUID NOT NULL REFERENCES public.trucks(id) ON DELETE CASCADE,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- INDEXES FOR POSTGIS & PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_truck_locations_geog ON public.truck_locations USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_truck_locations_live ON public.truck_locations (truck_id, is_live, live_until);
CREATE INDEX IF NOT EXISTS idx_user_areas_center ON public.user_areas USING GIST (center);
CREATE INDEX IF NOT EXISTS idx_notifications_log_dedup ON public.notifications_log (dedup_key);
CREATE INDEX IF NOT EXISTS idx_trucks_owner ON public.trucks (owner_id);
CREATE INDEX IF NOT EXISTS idx_reviews_truck ON public.reviews (truck_id);

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trucks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.truck_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications_log ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES

-- PROFILES
CREATE POLICY "Public profiles are readable" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- TRUCKS
-- Public read for all customers
CREATE POLICY "Trucks are publicly viewable" ON public.trucks
    FOR SELECT USING (true);

-- Only truck owners can insert their own truck
CREATE POLICY "Truck owners can insert their truck" ON public.trucks
    FOR INSERT WITH CHECK (
        auth.uid() = owner_id AND
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'truck_owner')
    );

-- Only owner can update their truck
CREATE POLICY "Truck owners can update their truck" ON public.trucks
    FOR UPDATE USING (
        auth.uid() = owner_id AND
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'truck_owner')
    );

-- TRUCK_LOCATIONS
-- Foodies can view locations only if live and not expired
CREATE POLICY "Live unexpired locations are readable" ON public.truck_locations
    FOR SELECT USING (
        (is_live = true AND live_until > NOW()) OR
        EXISTS (
            SELECT 1 FROM public.trucks
            WHERE trucks.id = truck_locations.truck_id AND trucks.owner_id = auth.uid()
        )
    );

-- Only truck owner can broadcast location
CREATE POLICY "Truck owners can insert locations" ON public.truck_locations
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.trucks
            WHERE trucks.id = truck_locations.truck_id AND trucks.owner_id = auth.uid()
        )
    );

-- MENUS
CREATE POLICY "Menus are publicly readable" ON public.menus
    FOR SELECT USING (true);

CREATE POLICY "Truck owners can manage their menu" ON public.menus
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.trucks
            WHERE trucks.id = menus.truck_id AND trucks.owner_id = auth.uid()
        )
    );

-- REVIEWS
CREATE POLICY "Reviews are publicly readable" ON public.reviews
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can post reviews" ON public.reviews
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can edit own reviews" ON public.reviews
    FOR UPDATE USING (auth.uid() = user_id);

-- USER_AREAS
CREATE POLICY "Users can manage only their own areas" ON public.user_areas
    FOR ALL USING (auth.uid() = user_id);

-- NOTIFICATIONS_LOG
CREATE POLICY "Users can read own notification logs" ON public.notifications_log
    FOR SELECT USING (auth.uid() = user_id);

-- HELPER FUNCTIONS FOR HARDENED LOGIC

-- 1. Check verified visit (within 200m of live pin within +-2 hours)
CREATE OR REPLACE FUNCTION public.check_is_verified_visit(
    p_truck_id UUID,
    p_user_lat DOUBLE PRECISION,
    p_user_lng DOUBLE PRECISION,
    p_review_time TIMESTAMPTZ DEFAULT NOW()
) RETURNS BOOLEAN AS $$
DECLARE
    v_verified BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.truck_locations
        WHERE truck_id = p_truck_id
          AND recorded_at BETWEEN (p_review_time - INTERVAL '2 hours') AND (p_review_time + INTERVAL '2 hours')
          AND ST_DWithin(
                geog,
                ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
                200 -- 200 meters
          )
    ) INTO v_verified;
    RETURN COALESCE(v_verified, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Process geofenced notification arrivals with idempotency and quiet hours
CREATE OR REPLACE FUNCTION public.find_eligible_area_subscribers(
    p_truck_id UUID,
    p_truck_lat DOUBLE PRECISION,
    p_truck_lng DOUBLE PRECISION,
    p_recorded_at TIMESTAMPTZ DEFAULT NOW()
) RETURNS TABLE (
    user_id UUID,
    area_id UUID,
    dedup_key TEXT
) AS $$
DECLARE
    v_today_date TEXT := TO_CHAR(p_recorded_at, 'YYYY-MM-DD');
    v_current_time TIME := p_recorded_at::time;
BEGIN
    RETURN QUERY
    SELECT 
        ua.user_id,
        ua.id AS area_id,
        MD5(ua.user_id::text || ':' || p_truck_id::text || ':' || ua.id::text || ':' || v_today_date) AS dedup_key
    FROM public.user_areas ua
    WHERE ua.notify_enabled = true
      -- Enforce quiet hours (default 22:00 to 08:00)
      AND NOT (
          (ua.quiet_hours_start < ua.quiet_hours_end AND v_current_time BETWEEN ua.quiet_hours_start AND ua.quiet_hours_end) OR
          (ua.quiet_hours_start > ua.quiet_hours_end AND (v_current_time >= ua.quiet_hours_start OR v_current_time < ua.quiet_hours_end))
      )
      -- Within subscribed radius in meters
      AND ST_DWithin(
          ua.center,
          ST_SetSRID(ST_MakePoint(p_truck_lng, p_truck_lat), 4326)::geography,
          ua.radius_km * 1000
      )
      -- Enforce max 3 pushes per user per day
      AND (
          SELECT COUNT(*) FROM public.notifications_log nl
          WHERE nl.user_id = ua.user_id
            AND nl.sent_at >= DATE_TRUNC('day', p_recorded_at)
      ) < 3
      -- Idempotency: Not already sent today for this truck + area
      AND NOT EXISTS (
          SELECT 1 FROM public.notifications_log nl
          WHERE nl.dedup_key = MD5(ua.user_id::text || ':' || p_truck_id::text || ':' || ua.id::text || ':' || v_today_date)
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
