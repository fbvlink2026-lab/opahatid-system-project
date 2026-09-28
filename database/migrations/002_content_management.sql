-- =========================================
-- Project: Pahatid System Project
-- File: database/migrations/002_content_management.sql
-- Description: Adds tables for Dynamic Website Content Management (CMS)
-- Author: AI Assistant
-- Date: 2026-09-29
-- Version: 2.0.1
-- =========================================

-- 1. SITE_SETTINGS_TABLE
-- Stores global key-value pairs for easy editing (e.g., Company Name, Support Email, Social Links)
CREATE TABLE IF NOT EXISTS public.site_settings (
    setting_key VARCHAR(50) PRIMARY KEY,
    setting_value TEXT NOT NULL,
    data_type TEXT CHECK (data_type IN ('string', 'number', 'boolean', 'json')) DEFAULT 'string',
    description VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert Default Settings
INSERT INTO public.site_settings (setting_key, setting_value, data_type, description) VALUES
('company_name', 'Pahatid System', 'string', 'Official company name'),
('support_email', 'help@pahatidsystem.com', 'string', 'Primary support contact'),
('facebook_url', '#', 'string', 'Facebook Page Link'),
('twitter_url', '#', 'string', 'Twitter/X Profile Link'),
('instagram_url', '#', 'string', 'Instagram Profile Link'),
('homepage_hero_title', 'Ride Smart, Ride Safe.', 'string', 'Main headline on landing page'),
('homepage_hero_subtitle', 'The most comprehensive Habal-Habal management system.', 'string', 'Sub-headline on landing page')
ON CONFLICT (setting_key) DO NOTHING;

-- 2. PAGES_CONTENT_TABLE
-- Stores large blocks of HTML/Markdown for specific pages (About, Terms, Privacy, Guide)
CREATE TABLE IF NOT EXISTS public.pages_content (
    page_slug VARCHAR(50) PRIMARY KEY, -- e.g., 'about-us', 'terms-of-service'
    page_title VARCHAR(100) NOT NULL,
    content_html TEXT NOT NULL, -- The actual body content
    meta_description TEXT,
    is_published BOOLEAN DEFAULT TRUE,
    last_edited_by UUID REFERENCES public.profiles(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed Initial Pages
INSERT INTO public.pages_content (page_slug, page_title, content_html, meta_description) VALUES
('about-us', 'About Pahatid System', '<h3>Our Mission</h3><p>To revolutionize local transport...</p>', 'Learn about our journey.'),
('terms-of-service', 'Terms of Service', '<h3>Agreement</h3><p>By using this service...</p>', 'Legal terms and conditions.'),
('privacy-policy', 'Privacy Policy', '<h3>Data Protection</h3><p>We value your privacy...</p>', 'How we handle your data.')
ON CONFLICT (page_slug) DO NOTHING;

-- 3. FAQ_ITEMS_TABLE
-- Frequently Asked Questions for the Help Center
CREATE TABLE IF NOT EXISTS public.faq_items (
    faq_id SERIAL PRIMARY KEY,
    category VARCHAR(50) DEFAULT 'General', -- General, Driver, Commuter
    question_text TEXT NOT NULL,
    answer_text TEXT NOT NULL,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for these new tables
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pages_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faq_items ENABLE ROW LEVEL SECURITY;

-- Policies: Only Admins can Edit, Everyone can Read Published Content
CREATE POLICY "Public read site settings" ON public.site_settings FOR SELECT USING (true);
CREATE POLICY "Admin manage site settings" ON public.site_settings FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Public read published pages" ON public.pages_content FOR SELECT USING (is_published = true);
CREATE POLICY "Admin manage pages" ON public.pages_content FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Public read active FAQs" ON public.faq_items FOR SELECT USING (is_active = true);
CREATE POLICY "Admin manage FAQs" ON public.faq_items FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
