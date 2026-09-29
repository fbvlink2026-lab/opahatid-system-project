-- =========================================
-- Project: Pahatid System Project
-- File: database/schema_telemetry.sql
-- Description: Adds tables for Vehicle Profiles, Trip Logs, and Stored Procedures for Rate Calculation
-- Author: AI Assistant
-- Date: 2026-09-30
-- Version: 2.1.0 (Server-Side Logic Implementation)
-- =========================================

-- --------------------------------------------------------
-- 1. VEHICLE_PROFILES TABLE
-- Stores standardized vehicle specs so drivers don't have to type them every time.
-- Admins can manage these here.
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.vehicle_profiles (
    profile_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE, -- e.g., "Honda Beat", "Tricycle Standard"
    category TEXT CHECK (category IN ('motor', 'tricycle', 'jeepney', 'car', 'van', 'custom')) DEFAULT 'motor',
    
    -- Technical Specs
    fuel_efficiency_km_per_liter DECIMAL(5, 2) NOT NULL DEFAULT 35.00,
    average_speed_kmh DECIMAL(5, 2) NOT NULL DEFAULT 30.00,
    
    -- Financial Baselines (Per Day)
    daily_rental_fee DECIMAL(10, 2) DEFAULT 0.00,
    daily_maintenance_cost DECIMAL(10, 2) DEFAULT 20.00,
    
    -- Reference Earnings (For Admin Monitoring)
    min_hourly_target DECIMAL(10, 2) DEFAULT 100.00,
    max_hourly_target DECIMAL(10, 2) DEFAULT 200.00,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert Default Vehicles (Based on Martodosko v11.0 Data)
INSERT INTO public.vehicle_profiles (name, category, fuel_efficiency_km_per_liter, average_speed_kmh, daily_rental_fee, daily_maintenance_cost, min_hourly_target, max_hourly_target) VALUES
('Standard Motor', 'motor', 35.00, 35.00, 0.00, 20.00, 100.00, 180.00),
('Heavy Duty Motor', 'motor', 25.00, 40.00, 0.00, 35.00, 120.00, 200.00),
('Tricycle', 'tricycle', 22.00, 25.00, 150.00, 50.00, 80.00, 150.00),
('Jeepney', 'jeepney', 8.00, 30.00, 300.00, 100.00, 150.00, 250.00),
('Private Car', 'car', 12.00, 45.00, 0.00, 50.00, 180.00, 300.00)
ON CONFLICT (name) DO NOTHING;

-- --------------------------------------------------------
-- 2. DRIVER_SETTINGS TABLE
-- Personalized settings per driver (overrides global defaults if needed)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.driver_settings (
    driver_profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    preferred_vehicle_id INT REFERENCES public.vehicle_profiles(profile_id),
    custom_gas_price DECIMAL(10, 2), -- If they track specific pump prices
    expected_work_hours_per_day DECIMAL(4, 2) DEFAULT 8.00,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.vehicle_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_settings ENABLE ROW LEVEL SECURITY;

-- Policies: Everyone can read vehicles, only owners edit their settings
CREATE POLICY "Public read vehicles" ON public.vehicle_profiles FOR SELECT USING (is_active = true);
CREATE POLICY "Owner manages own settings" ON public.driver_settings FOR ALL USING (driver_profile_id = auth.uid());

-- --------------------------------------------------------
-- 3. TRIP_LOGS TABLE
-- The heart of monitoring. Saves EVERY calculated trip for Admin analysis.
-- This replaces localStorage saving in the previous version.
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.trip_logs (
    log_id BIGSERIAL PRIMARY KEY,
    driver_profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    booking_id INT REFERENCES public.bookings(booking_id) ON DELETE SET NULL, -- Optional link to actual order
    
    -- Route Data
    pickup_lat DECIMAL(10, 8),
    pickup_lng DECIMAL(11, 8),
    dropoff_lat DECIMAL(10, 8),
    dropoff_lng DECIMAL(11, 8),
    distance_km DECIMAL(8, 2) NOT NULL,
    duration_hours DECIMAL(6, 2) NOT NULL,
    
    -- Financial Breakdown (Calculated Server-Side or Client-Side but stored here)
    gross_fare DECIMAL(10, 2) NOT NULL,
    fuel_cost DECIMAL(10, 2) NOT NULL,
    rental_prorated_cost DECIMAL(10, 2) NOT NULL,
    maintenance_prorated_cost DECIMAL(10, 2) NOT NULL,
    total_expenses DECIMAL(10, 2) NOT NULL,
    net_income DECIMAL(10, 2) NOT NULL,
    
    -- Metadata
    vehicle_used_name VARCHAR(50),
    notes TEXT,
    is_synced BOOLEAN DEFAULT TRUE,
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for fast Admin queries
CREATE INDEX idx_trip_logs_driver_date ON public.trip_logs(driver_profile_id, logged_at DESC);
CREATE INDEX idx_trip_logs_booking ON public.trip_logs(booking_id);

-- Enable RLS
ALTER TABLE public.trip_logs ENABLE ROW LEVEL SECURITY;

-- Policies: Drivers see their own logs, Admins see all
CREATE POLICY "Drivers view own logs" ON public.trip_logs FOR SELECT USING (driver_profile_id = auth.uid());
CREATE POLICY "Admins view all logs" ON public.trip_logs FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Drivers insert own logs" ON public.trip_logs FOR INSERT WITH CHECK (driver_profile_id = auth.uid());


-- --------------------------------------------------------
-- 4. STORED FUNCTION: CALCULATE_TRIP_FINANCIALS
-- This moves the MATH LOGIC out of JavaScript and into PostgreSQL.
-- Benefits: Consistent results, harder to hack, easier to update formulas globally.
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_trip_financials(
    p_distance_km DECIMAL,
    p_duration_hours DECIMAL,
    p_gross_fare DECIMAL,
    p_gas_price_per_liter DECIMAL,
    p_vehicle_efficiency_km_per_liter DECIMAL,
    p_daily_rental_fee DECIMAL,
    p_daily_maintenance_cost DECIMAL,
    p_expected_work_hours DECIMAL
)
RETURNS JSONB AS $$
DECLARE
    v_liters_needed DECIMAL(10, 4);
    v_fuel_cost DECIMAL(10, 2);
    v_hourly_fixed_cost DECIMAL(10, 2);
    v_rental_prorated DECIMAL(10, 2);
    v_maintenance_prorated DECIMAL(10, 2);
    v_total_expenses DECIMAL(10, 2);
    v_net_income DECIMAL(10, 2);
    v_profit_margin DECIMAL(5, 2);
    v_hourly_rate DECIMAL(10, 2);
BEGIN
    -- 1. Calculate Fuel Usage & Cost
    IF p_vehicle_efficiency_km_per_liter > 0 THEN
        v_liters_needed := p_distance_km / p_vehicle_efficiency_km_per_liter;
    ELSE
        v_liters_needed := 0;
    END IF;
    
    v_fuel_cost := ROUND(v_liters_needed * p_gas_price_per_liter, 2);

    -- 2. Prorate Fixed Costs (Rental + Maintenance) based on time worked vs expected day
    -- Formula: (Daily Cost / Expected Daily Hours) * Actual Trip Duration
    IF p_expected_work_hours > 0 THEN
        v_hourly_fixed_cost := (p_daily_rental_fee + p_daily_maintenance_cost) / p_expected_work_hours;
        
        v_rental_prorated := ROUND((p_daily_rental_fee / p_expected_work_hours) * p_duration_hours, 2);
        v_maintenance_prorated := ROUND((p_daily_maintenance_cost / p_expected_work_hours) * p_duration_hours, 2);
    ELSE
        v_rental_prorated := 0;
        v_maintenance_prorated := 0;
    END IF;

    -- 3. Total Expenses
    v_total_expenses := v_fuel_cost + v_rental_prorated + v_maintenance_prorated;

    -- 4. Net Income
    v_net_income := p_gross_fare - v_total_expenses;

    -- 5. Metrics for Reporting
    IF p_gross_fare > 0 THEN
        v_profit_margin := ROUND((v_net_income / p_gross_fare) * 100, 2);
    ELSE
        v_profit_margin := 0;
    END IF;

    IF p_duration_hours > 0 THEN
        v_hourly_rate := ROUND(v_net_income / p_duration_hours, 2);
    ELSE
        v_hourly_rate := 0;
    END IF;

    RETURN jsonb_build_object(
        'fuel_cost', v_fuel_cost,
        'rental_prorated_cost', v_rental_prorated,
        'maintenance_prorated_cost', v_maintenance_prorated,
        'total_expenses', v_total_expenses,
        'net_income', v_net_income,
        'profit_margin_percent', v_profit_margin,
        'effective_hourly_rate', v_hourly_rate
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Grant execute permission to authenticated users (Drivers)
GRANT EXECUTE ON FUNCTION public.calculate_trip_financials TO authenticated;

COMMIT;
