-- -----------------------------------------------------------------------------
-- PAHATID SYSTEM — Habal-Habal Transport Services Platform
-- FILE: schema.sql
-- TYPE: Database Schema
-- VERSION: 1.0.0
-- LAST UPDATED: 2026-09-28
-- STATUS: Active — Ready for Implementation
-- SECURITY: NO CREDENTIALS INCLUDED | Structure-Only | Placeholder Values
-- DEPLOYMENT: GitHub-Safe — No Live Keys/Secrets Committed
-- -----------------------------------------------------------------------------
--  ⚠️  IMPORTANT SECURITY NOTES:
-- - Card numbers, CVV, full PAN NEVER stored — TOKENS only in cards_tokenized
-- - Passwords/Secrets stored as HASHED values only, never plain text
-- - Sensitive connection data in .env or config file — EXCLUDED from repo
-- - All user inputs must be SANITIZED before queries to prevent injection
-- - Use HTTPS in production — enforce secure cookie flags
-- -----------------------------------------------------------------------------
--  DATABASE PURPOSE:
--  Unified backend data layer for Commuter ↔ Driver ↔ Admin ecosystem
--  Tracks accounts, rides, fares, payments, expenses, feedback, security
-- -----------------------------------------------------------------------------

-- =============================================
-- DATABASE INITIALIZATION
-- =============================================
-- CREATE DATABASE IF NOT EXISTS pahatid_system;
-- USE pahatid_system;
-- SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
-- START TRANSACTION;

-- =============================================
-- TABLE 1: users — Base Accounts (All Roles)
-- =============================================
CREATE TABLE IF NOT EXISTS `users` (
  `user_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role` ENUM('admin','driver','commuter') NOT NULL,
  `full_name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(150) DEFAULT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL COMMENT 'Never store plain password',
  `status` ENUM('pending','active','suspended','blocked') DEFAULT 'pending',
  `preferred_language` ENUM('en','tl') DEFAULT 'tl',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_email` (`email`),
  UNIQUE KEY `uk_phone` (`phone`),
  KEY `idx_role_status` (`role`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Base user accounts';

-- =============================================
-- TABLE 2: admins — Admin Panel Profiles
-- =============================================
CREATE TABLE IF NOT EXISTS `admins` (
  `admin_id` BIGINT UNSIGNED NOT NULL,
  `permissions` SET('dispatch','accounts','finance','moderation','settings','all') DEFAULT 'dispatch',
  `department` VARCHAR(50) DEFAULT NULL,
  `last_login` DATETIME DEFAULT NULL,
  PRIMARY KEY (`admin_id`),
  FOREIGN KEY (`admin_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Admin-specific data';

-- =============================================
-- TABLE 3: drivers — Driver Portal Profiles
-- =============================================
CREATE TABLE IF NOT EXISTS `drivers` (
  `driver_id` BIGINT UNSIGNED NOT NULL,
  `application_status` ENUM('applicant','approved','rejected','suspended') DEFAULT 'applicant',
  `rank_id` INT UNSIGNED DEFAULT 1,
  `motor_plate` VARCHAR(20) DEFAULT NULL,
  `motor_brand` VARCHAR(50) DEFAULT NULL,
  `motor_model` VARCHAR(50) DEFAULT NULL,
  `motor_year` SMALLINT DEFAULT NULL,
  `motor_color` VARCHAR(30) DEFAULT NULL,
  `fuel_type` ENUM('gasoline','diesel') DEFAULT 'gasoline',
  `base_fare_rate` DECIMAL(10,4) DEFAULT NULL COMMENT 'Per km rate',
  `total_rides` INT UNSIGNED DEFAULT 0,
  `total_km` DECIMAL(10,2) DEFAULT 0.00,
  `avg_rating` DECIMAL(3,2) DEFAULT 5.00,
  `secret_key_issued` VARCHAR(64) DEFAULT NULL COMMENT 'Admin-generated login token',
  `secret_key_expiry` DATETIME DEFAULT NULL,
  `boundary_rental_daily` DECIMAL(10,2) DEFAULT 0.00 COMMENT 'Boundary/rent cost',
  PRIMARY KEY (`driver_id`),
  FOREIGN KEY (`driver_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  KEY `idx_rank` (`rank_id`),
  KEY `idx_status` (`application_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Driver profile & vehicle data';

-- =============================================
-- TABLE 4: driver_ranks — Rank/Promotion System
-- =============================================
CREATE TABLE IF NOT EXISTS `driver_ranks` (
  `rank_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rank_name` VARCHAR(30) NOT NULL COMMENT 'Newbie/Bronze/Silver/Gold/Platinum',
  `min_rides` INT UNSIGNED DEFAULT 0,
  `min_rating` DECIMAL(3,2) DEFAULT 4.50,
  `commission_rate` DECIMAL(5,4) DEFAULT 0.9000 COMMENT 'Earnings share to driver',
  `bonus_multiplier` DECIMAL(4,2) DEFAULT 1.00,
  `description` TEXT,
  PRIMARY KEY (`rank_id`),
  UNIQUE KEY `uk_rank_name` (`rank_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Rank definitions & benefits';

-- =============================================
-- TABLE 5: commuters — Commuter Portal Profiles
-- =============================================
CREATE TABLE IF NOT EXISTS `commuters` (
  `commuter_id` BIGINT UNSIGNED NOT NULL,
  `default_pickup` VARCHAR(255) DEFAULT NULL,
  `saved_locations` JSON DEFAULT NULL COMMENT 'Frequently used places',
  `total_rides` INT UNSIGNED DEFAULT 0,
  PRIMARY KEY (`commuter_id`),
  FOREIGN KEY (`commuter_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Commuter-specific data';

-- =============================================
-- TABLE 6: favorites — Favorite Drivers
-- =============================================
CREATE TABLE IF NOT EXISTS `favorites` (
  `favorite_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `commuter_id` BIGINT UNSIGNED NOT NULL,
  `driver_id` BIGINT UNSIGNED NOT NULL,
  `notes` VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`favorite_id`),
  UNIQUE KEY `uk_commuter_driver` (`commuter_id`,`driver_id`),
  FOREIGN KEY (`commuter_id`) REFERENCES `commuters`(`commuter_id`) ON DELETE CASCADE,
  FOREIGN KEY (`driver_id`) REFERENCES `drivers`(`driver_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Favorite driver bookmarks';

-- =============================================
-- TABLE 7: rides — Bookings & Trip Records
-- =============================================
CREATE TABLE IF NOT EXISTS `rides` (
  `ride_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `commuter_id` BIGINT UNSIGNED NOT NULL,
  `driver_id` BIGINT UNSIGNED DEFAULT NULL,
  `pickup_lat` DECIMAL(10,7) DEFAULT NULL,
  `pickup_lng` DECIMAL(10,7) DEFAULT NULL,
  `pickup_address` VARCHAR(255) NOT NULL,
  `destination_lat` DECIMAL(10,7) DEFAULT NULL,
  `destination_lng` DECIMAL(10,7) DEFAULT NULL,
  `destination_address` VARCHAR(255) NOT NULL,
  `distance_km` DECIMAL(10,3) DEFAULT NULL,
  `estimated_fare` DECIMAL(10,2) DEFAULT NULL,
  `final_fare` DECIMAL(10,2) DEFAULT NULL,
  `passengers` TINYINT UNSIGNED DEFAULT 1,
  `status` ENUM('pending','accepted','en_route','arrived','completed','cancelled') DEFAULT 'pending',
  `cancelled_by` ENUM('commuter','driver','admin','system') DEFAULT NULL,
  `cancellation_reason` TEXT,
  `requested_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `accepted_at` DATETIME DEFAULT NULL,
  `started_at` DATETIME DEFAULT NULL,
  `completed_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ride_id`),
  KEY `idx_commuter` (`commuter_id`),
  KEY `idx_driver` (`driver_id`),
  KEY `idx_status` (`status`),
  KEY `idx_dates` (`requested_at`,`completed_at`),
  FOREIGN KEY (`commuter_id`) REFERENCES `commuters`(`commuter_id`),
  FOREIGN KEY (`driver_id`) REFERENCES `drivers`(`driver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ride/booking master records';

-- =============================================
-- TABLE 8: payment_methods — Active Payment Options
-- =============================================
CREATE TABLE IF NOT EXISTS `payment_methods` (
  `method_id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL COMMENT 'cash/card_visa/card_mc/gcash/maya/bank_insta etc',
  `name` VARCHAR(50) NOT NULL,
  `type` ENUM('cash','card','ewallet','bank') NOT NULL,
  `is_active` BOOLEAN DEFAULT TRUE,
  `fee_percent` DECIMAL(5,4) DEFAULT 0.0000,
  `fee_fixed` DECIMAL(10,2) DEFAULT 0.00,
  `instructions` TEXT,
  `icon` VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (`method_id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Supported payment types';

-- =============================================
-- TABLE 9: cards_tokenized — SECURED Card Storage (TOKENS ONLY)
-- =============================================
CREATE TABLE IF NOT EXISTS `cards_tokenized` (
  `card_token` VARCHAR(64) NOT NULL COMMENT 'System-generated token — NOT card number',
  `commuter_id` BIGINT UNSIGNED NOT NULL,
  `masked_number` VARCHAR(20) NOT NULL COMMENT 'e.g. 4111-****-****-1234',
  `card_network` VARCHAR(20) NOT NULL COMMENT 'Visa/Mastercard',
  `expiry_month` TINYINT UNSIGNED DEFAULT NULL,
  `expiry_year` SMALLINT UNSIGNED DEFAULT NULL,
  `is_default` BOOLEAN DEFAULT FALSE,
  `token_provider` VARCHAR(50) DEFAULT 'internal',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`card_token`),
  KEY `idx_commuter` (`commuter_id`),
  FOREIGN KEY (`commuter_id`) REFERENCES `commuters`(`commuter_id`) ON DELETE CASCADE,
  CONSTRAINT `chk_no_plain_card` CHECK (
    `masked_number` NOT REGEXP '^[0-9]{16}$'
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Card-on-File — TOKENS ONLY, never full PAN/CVV';

-- =============================================
-- TABLE 10: payments — Transaction Records
-- =============================================
CREATE TABLE IF NOT EXISTS `payments` (
  `payment_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ride_id` BIGINT UNSIGNED NOT NULL,
  `commuter_id` BIGINT UNSIGNED NOT NULL,
  `driver_id` BIGINT UNSIGNED DEFAULT NULL,
  `method_id` TINYINT UNSIGNED NOT NULL,
  `card_token` VARCHAR(64) DEFAULT NULL COMMENT 'Links to cards_tokenized',
  `amount_subtotal` DECIMAL(10,2) NOT NULL,
  `amount_fee` DECIMAL(10,2) DEFAULT 0.00,
  `amount_total` DECIMAL(10,2) NOT NULL,
  `driver_share` DECIMAL(10,2) DEFAULT NULL COMMENT 'After commission deduction',
  `status` ENUM('pending','processing','paid','failed','refunded','partial') DEFAULT 'pending',
  `reference_no` VARCHAR(100) DEFAULT NULL,
  `transaction_proof` VARCHAR(255) DEFAULT NULL,
  `paid_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`payment_id`),
  UNIQUE KEY `uk_reference` (`reference_no`),
  KEY `idx_ride` (`ride_id`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`ride_id`) REFERENCES `rides`(`ride_id`),
  FOREIGN KEY (`commuter_id`) REFERENCES `commuters`(`commuter_id`),
  FOREIGN KEY (`driver_id`) REFERENCES `drivers`(`driver_id`),
  FOREIGN KEY (`method_id`) REFERENCES `payment_methods`(`method_id`),
  FOREIGN KEY (`card_token`) REFERENCES `cards_tokenized`(`card_token`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='All payment transactions';

-- =============================================
-- TABLE 11: payouts — Driver Settlements
-- =============================================
CREATE TABLE IF NOT EXISTS `payouts` (
  `payout_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `driver_id` BIGINT UNSIGNED NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `payment_method` VARCHAR(30) DEFAULT NULL,
  `recipient_ref` VARCHAR(100) DEFAULT NULL COMMENT 'Account no — MASKED',
  `status` ENUM('requested','approved','sent','received','failed') DEFAULT 'requested',
  `scheduled_date` DATE DEFAULT NULL,
  `processed_at` DATETIME DEFAULT NULL,
  `remarks` TEXT,
  PRIMARY KEY (`payout_id`),
  KEY `idx_driver` (`driver_id`),
  FOREIGN KEY (`driver_id`) REFERENCES `drivers`(`driver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Driver earnings disbursement';

-- =============================================
-- TABLE 12: fuel_records — Fuel & Consumption Tracking
-- =============================================
CREATE TABLE IF NOT EXISTS `fuel_records` (
  `log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `driver_id` BIGINT UNSIGNED NOT NULL,
  `ride_id` BIGINT UNSIGNED DEFAULT NULL,
  `liters` DECIMAL(10,3) NOT NULL,
  `price_per_liter` DECIMAL(10,2) NOT NULL,
  `total_cost` DECIMAL(10,2) GENERATED ALWAYS AS (`liters` * `price_per_liter`) STORED,
  `distance_km` DECIMAL(10,3) DEFAULT NULL,
  `consumption_lkm` DECIMAL(10,4) DEFAULT NULL COMMENT 'Liters per km',
  `station_name` VARCHAR(100) DEFAULT NULL,
  `refuel_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `idx_driver` (`driver_id`),
  FOREIGN KEY (`driver_id`) REFERENCES `drivers`(`driver_id`),
  FOREIGN KEY (`ride_id`) REFERENCES `rides`(`ride_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Fuel consumption logs';

-- =============================================
-- TABLE 13: expense_logs — Driver Expense Tracking
-- =============================================
CREATE TABLE IF NOT EXISTS `expense_logs` (
  `expense_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `driver_id` BIGINT UNSIGNED NOT NULL,
  `ride_id` BIGINT UNSIGNED DEFAULT NULL,
  `category` ENUM('rental','fuel','maintenance','parts','food','other') NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `receipt_ref` VARCHAR(100) DEFAULT NULL,
  `recorded_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`expense_id`),
  KEY `idx_driver_cat` (`driver_id`,`category`),
  FOREIGN KEY (`driver_id`) REFERENCES `drivers`(`driver_id`),
  FOREIGN KEY (`ride_id`) REFERENCES `rides`(`ride_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='All driver expenses breakdown';

-- =============================================
-- TABLE 14: feedback — Ratings & Testimonials
-- =============================================
CREATE TABLE IF NOT EXISTS `feedback` (
  `feedback_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ride_id` BIGINT UNSIGNED NOT NULL,
  `commuter_id` BIGINT UNSIGNED NOT NULL,
  `driver_id` BIGINT UNSIGNED NOT NULL,
  `rating_stars` TINYINT UNSIGNED DEFAULT NULL COMMENT '1-5',
  `comment_text` TEXT,
  `is_public` BOOLEAN DEFAULT TRUE,
  `is_verified` BOOLEAN DEFAULT FALSE,
  `moderation_status` ENUM('pending','approved','rejected') DEFAULT 'pending',
  `moderated_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`feedback_id`),
  UNIQUE KEY `uk_ride` (`ride_id`),
  KEY `idx_driver` (`driver_id`),
  KEY `idx_verified` (`is_verified`),
  FOREIGN KEY (`ride_id`) REFERENCES `rides`(`ride_id`),
  FOREIGN KEY (`commuter_id`) REFERENCES `commuters`(`commuter_id`),
  FOREIGN KEY (`driver_id`) REFERENCES `drivers`(`driver_id`),
  FOREIGN KEY (`moderated_by`) REFERENCES `admins`(`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ratings, reviews, testimonials';

-- =============================================
-- TABLE 15: warnings_reklamo — Reports & Discipline
-- =============================================
CREATE TABLE IF NOT EXISTS `warnings_reklamo` (
  `report_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `reporter_id` BIGINT UNSIGNED DEFAULT NULL,
  `subject_type` ENUM('driver','commuter','admin') NOT NULL,
  `subject_id` BIGINT UNSIGNED NOT NULL,
  `related_ride_id` BIGINT UNSIGNED DEFAULT NULL,
  `category` VARCHAR(50) NOT NULL,
  `details` TEXT NOT NULL,
  `severity` ENUM('notice','warning','serious','critical') DEFAULT 'notice',
  `status` ENUM('filed','reviewing','resolved','closed') DEFAULT 'filed',
  `action_taken` TEXT,
  `issued_by` BIGINT UNSIGNED DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`report_id`),
  KEY `idx_subject` (`subject_type`,`subject_id`),
  FOREIGN KEY (`related_ride_id`) REFERENCES `rides`(`ride_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Complaints, warnings, disciplinary records';

-- =============================================
-- TABLE 16: auth_keys — Secret Key Management
-- =============================================
CREATE TABLE IF NOT EXISTS `auth_keys` (
  `key_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `secret_key_hash` VARCHAR(255) NOT NULL,
  `issued_by` BIGINT UNSIGNED DEFAULT NULL,
  `purpose` VARCHAR(50) DEFAULT 'login',
  `is_active` BOOLEAN DEFAULT TRUE,
  `expires_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`key_id`),
  KEY `idx_user` (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  FOREIGN KEY (`issued_by`) REFERENCES `admins`(`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Admin-issued authentication keys';

-- =============================================
-- TABLE 17: system_settings — Configurable Values
-- =============================================
CREATE TABLE IF NOT EXISTS `system_settings` (
  `setting_key` VARCHAR(100) NOT NULL,
  `setting_value` TEXT DEFAULT NULL,
  `setting_type` ENUM('string','number','boolean','json') DEFAULT 'string',
  `description` VARCHAR(255) DEFAULT NULL,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Global site config — fares, limits, options';

-- =============================================
-- TABLE 18: activity_logs — Audit Trail
-- =============================================
CREATE TABLE IF NOT EXISTS `activity_logs` (
  `log_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `actor_id` BIGINT UNSIGNED DEFAULT NULL,
  `actor_role` VARCHAR(20) DEFAULT NULL,
  `action` VARCHAR(100) NOT NULL,
  `target_type` VARCHAR(50) DEFAULT NULL,
  `target_id` VARCHAR(100) DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `user_agent` VARCHAR(255) DEFAULT NULL,
  `occurred_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `idx_actor` (`actor_id`),
  KEY `idx_action` (`action`),
  KEY `idx_date` (`occurred_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Audit trail — track all system changes';

-- =============================================
-- END OF SCHEMA
-- -----------------------------------------------------------------------------
-- FILE STATUS: COMPLETE
-- NEXT FILE: frontend/index.html — Homepage + Feedback Section
-- -----------------------------------------------------------------------------
