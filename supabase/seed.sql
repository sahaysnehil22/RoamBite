-- SEED DATA FOR DEMO / LOCAL DEVELOPMENT
-- Contains the 4 reference food trucks (Miami, FL & Austin, TX)

-- 1. Demo Owners (Synthetic UUIDs)
INSERT INTO auth.users (id, email, phone)
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'owner.tacotrail@roambite.com', '+13055550101'),
  ('22222222-2222-2222-2222-222222222222', 'owner.burgerbus@roambite.com', '+13055550102'),
  ('33333333-3333-3333-3333-333333333333', 'owner.brewcrew@roambite.com', '+13055550103'),
  ('44444444-4444-4444-4444-444444444444', 'owner.arepas@roambite.com', '+13055550104')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, role, phone, display_name)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'truck_owner', '+13055550101', 'Taco Trail Chef'),
  ('22222222-2222-2222-2222-222222222222', 'truck_owner', '+13055550102', 'Burger Bus Team'),
  ('33333333-3333-3333-3333-333333333333', 'truck_owner', '+13055550103', 'Brew Crew Barista'),
  ('44444444-4444-4444-4444-444444444444', 'truck_owner', '+13055550104', 'Miami Arepas Kitchen')
ON CONFLICT (id) DO NOTHING;

-- 2. Trucks
INSERT INTO public.trucks (id, owner_id, name, tagline, cuisine, signature_dish, price_range, address, city, state, hero_image_url, is_sponsored)
VALUES
  (
    'a1111111-aaaa-1111-aaaa-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'Taco Trail Express',
    'Authentic Jalisco street tacos & melted birria',
    'Mexican • Tacos',
    'Crispy Quesabirria Tacos',
    '$',
    '2407 NW 2nd Ave',
    'Miami',
    'FL',
    'https://images.unsplash.com/photo-1565123409695-7b5ef63a2efb?auto=format&fit=crop&w=1200&q=80',
    true
  ),
  (
    'a2222222-aaaa-2222-aaaa-222222222222',
    '22222222-2222-2222-2222-222222222222',
    'Burger Bus Co.',
    'Double smash burgers with butter-toasted brioche',
    'American • Burgers',
    'The Wynwood Double Smash',
    '$$',
    '2600 NW Miami Ct',
    'Miami',
    'FL',
    'https://images.unsplash.com/photo-1525164286253-04e68b9d94c6?auto=format&fit=crop&w=1200&q=80',
    false
  ),
  (
    'a3333333-aaaa-3333-aaaa-333333333333',
    '33333333-3333-3333-3333-333333333333',
    'The Brew Crew Coffee',
    'Nitro cold brews & fresh artisan churros',
    'Cafe • Coffee & Desserts',
    'Nitro Vanilla Sweet Cream Cold Brew',
    '$',
    '2215 NW 2nd Ave',
    'Miami',
    'FL',
    'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80',
    false
  ),
  (
    'a4444444-aaaa-4444-aaaa-444444444444',
    '44444444-4444-4444-4444-444444444444',
    'Miami Arepas Cart',
    'Gluten-free Venezuelan corn cakes stuffed hot',
    'Latin • Venezuelan',
    'Reina Pepiada Arepa',
    '$',
    '2801 NW 3rd Ave',
    'Miami',
    'FL',
    'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=1200&q=80',
    false
  )
ON CONFLICT (id) DO NOTHING;

-- 3. Live Locations
INSERT INTO public.truck_locations (truck_id, geog, latitude, longitude, recorded_at, is_live, live_until, status)
VALUES
  (
    'a1111111-aaaa-1111-aaaa-111111111111',
    ST_SetSRID(ST_MakePoint(-80.1986, 25.7997), 4326)::geography,
    25.7997,
    -80.1986,
    NOW(),
    true,
    NOW() + INTERVAL '15 minutes',
    'serving_now'
  ),
  (
    'a2222222-aaaa-2222-aaaa-222222222222',
    ST_SetSRID(ST_MakePoint(-80.1992, 25.8015), 4326)::geography,
    25.8015,
    -80.1992,
    NOW(),
    true,
    NOW() + INTERVAL '15 minutes',
    'serving_now'
  ),
  (
    'a3333333-aaaa-3333-aaaa-333333333333',
    ST_SetSRID(ST_MakePoint(-80.1970, 25.7981), 4326)::geography,
    25.7981,
    -80.1970,
    NOW(),
    true,
    NOW() + INTERVAL '15 minutes',
    'serving_now'
  ),
  (
    'a4444444-aaaa-4444-aaaa-444444444444',
    ST_SetSRID(ST_MakePoint(-80.2010, 25.8020), 4326)::geography,
    25.8020,
    -80.2010,
    NOW(),
    true,
    NOW() + INTERVAL '15 minutes',
    'on_the_move'
  );

-- 4. Menus (Version 1)
INSERT INTO public.menus (truck_id, items, menu_version)
VALUES
  (
    'a1111111-aaaa-1111-aaaa-111111111111',
    '[
      {"id": "m1", "name": "Crispy Quesabirria Tacos (3x)", "description": "Braised beef birria, melted Oaxaca cheese, cilantro, onions, with rich consomé broth.", "price": 13.50, "imageUrl": "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80", "isSignature": true},
      {"id": "m2", "name": "Al Pastor Street Tacos", "description": "Marinated pork shaved fresh from the trompo with grilled pineapple and salsa verde.", "price": 10.99, "imageUrl": "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80", "isSignature": false},
      {"id": "m3", "name": "Chorizo Loaded Queso Fries", "description": "Golden waffle fries topped with warm queso blanco, spiced chorizo, and jalapeños.", "price": 9.75, "imageUrl": "https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=600&q=80", "isSignature": true},
      {"id": "m4", "name": "Cinnamon Spiced Horchata", "description": "House-made rice milk with Ceylon cinnamon and Mexican vanilla.", "price": 4.50, "imageUrl": "https://images.unsplash.com/photo-1541658016709-82535e94bc69?auto=format&fit=crop&w=600&q=80", "isSignature": false}
    ]'::jsonb,
    1
  ),
  (
    'a2222222-aaaa-2222-aaaa-222222222222',
    '[
      {"id": "m5", "name": "The Wynwood Double Smash", "description": "Two smashed Angus beef patties, caramelized grilled onions, American cheese, house sauce.", "price": 12.99, "imageUrl": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80", "isSignature": true},
      {"id": "m6", "name": "Truffle Parmesan Fries", "description": "Crispy skin-on fries tossed in white truffle oil, pecorino, and fresh parsley.", "price": 7.99, "imageUrl": "https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=600&q=80", "isSignature": false}
    ]'::jsonb,
    1
  )
ON CONFLICT (truck_id) DO NOTHING;
