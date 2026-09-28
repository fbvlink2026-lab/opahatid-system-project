<?php
// =========================================
// Project: Pahatid System Project
// File: includes/header.php
// Description: Global Header, SEO Metadata, Open Graph Tags, and Dynamic Sidebar Logic
// Author: AI Assistant
// Date: 2026-09-29
// Version: 1.0.0
// Usage: Include this at the top of every public-facing page.
// =========================================

// Start Session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Load Configurations
require_once __DIR__ . '/../config/constants.php';
require_once __DIR__ . '/../config/database.php'; // Initialize DB connection

// Determine Current User Role & Name for Sidebar Context
$currentRole = $_SESSION['role'] ?? 'guest';
$userName = $_SESSION['full_name'] ?? 'Guest';
$profileImg = $_SESSION['profile_img_url'] ?? ASSETS_URL . '/img/default-avatar.png';

// Define Page Title and Meta Description dynamically if passed via variable
$pageTitle = isset($pageTitle) ? $pageTitle : 'Pahatid System - Habal-Habal Transport Service';
$pageDescription = isset($pageDescription) ? $pageDescription : 'Secure, fast, and transparent habal-habal transport booking system for drivers, commuters, and administrators.';
$ogImage = isset($ogImage) ? $ogImage : BASE_PATH . '/assets/img/og-cover.jpg'; // Fallback image URL
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <!-- Primary Meta Tags -->
    <title><?php echo htmlspecialchars($pageTitle); ?></title>
    <meta name="title" content="<?php echo htmlspecialchars($pageTitle); ?>">
    <meta name="description" content="<?php echo htmlspecialchars($pageDescription); ?>">
    <meta name="keywords" content="habal habal, motorcycle taxi, transport app, pahatid system, ride sharing Philippines">
    <meta name="author" content="Pahatid Team">
    <link rel="canonical" href="<?php echo APP_URL . $_SERVER['REQUEST_URI']; ?>">

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="<?php echo APP_URL . $_SERVER['REQUEST_URI']; ?>">
    <meta property="og:title" content="<?php echo htmlspecialchars($pageTitle); ?>">
    <meta property="og:description" content="<?php echo htmlspecialchars($pageDescription); ?>">
    <meta property="og:image" content="<?php echo htmlspecialchars($ogImage); ?>">
    <meta property="og:site_name" content="Pahatid System">

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:url" content="<?php echo APP_URL . $_SERVER['REQUEST_URI']; ?>">
    <meta name="twitter:title" content="<?php echo htmlspecialchars($pageTitle); ?>">
    <meta name="twitter:description" content="<?php echo htmlspecialchars($pageDescription); ?>">
    <meta name="twitter:image" content="<?php echo htmlspecialchars($ogImage); ?>">

    <!-- Favicon -->
    <link rel="icon" href="<?php echo ASSETS_URL; ?>/img/favicon.ico" type="image/x-icon">

    <!-- CSS Libraries (Using CDN for Free Hosting Compatibility) -->
    <!-- Bootstrap 5 for Grid/Layout -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- FontAwesome for Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Leaflet CSS for Maps (Driver/Commuter Tracking) -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
    
    <!-- Custom Stylesheet -->
    <link rel="stylesheet" href="<?php echo ASSETS_URL; ?>/css/style.css">
</head>
<body class="bg-light d-flex flex-column min-vh-100">

    <!-- Navigation Bar (Top) -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary shadow-sm sticky-top">
        <div class="container-fluid">
            <!-- Brand Logo -->
            <a class="navbar-brand fw-bold" href="/public/index.php">
                <i class="fas fa-motorcycle me-2"></i>Pahatid<span class="text-warning">System</span>
            </a>

            <!-- Toggle Button for Mobile Sidebar -->
            <button class="btn btn-outline-light d-lg-none" id="sidebarToggleBtn" aria-label="Toggle Menu">
                <i class="fas fa-bars"></i>
            </button>

            <!-- Right Side Actions -->
            <div class="ms-auto d-flex align-items-center gap-3">
                <?php if ($currentRole !== 'guest'): ?>
                    <!-- User Profile Dropdown -->
                    <div class="dropdown">
                        <button class="btn btn-link text-white dropdown-toggle p-0" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="<?php echo htmlspecialchars($profileImg); ?>" alt="Profile" class="rounded-circle border border-2 border-light" style="width: 32px; height: 32px; object-fit: cover;">
                            <span class="d-none d-md-inline ms-2"><?php echo htmlspecialchars(explode(' ', $userName)[0]); ?></span>
                        </button>
                        <ul class="dropdown-menu dropdown-menu-end shadow">
                            <li><span class="dropdown-item-text small text-muted"><?php echo ucfirst(htmlspecialchars($currentRole)); ?> Account</span></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="#"><i class="fas fa-user-cog me-2"></i>Settings</a></li>
                            <li><form action="/public/logout.php" method="POST"><button type="submit" class="dropdown-item text-danger"><i class="fas fa-sign-out-alt me-2"></i>Logout</button></form></li>
                        </ul>
                    </div>
                <?php else: ?>
                    <!-- Login/Register Buttons for Guests -->
                    <a href="/public/login.php" class="btn btn-outline-light btn-sm">Login</a>
                    <a href="/public/register.php" class="btn btn-warning btn-sm fw-bold">Join Now</a>
                <?php endif; ?>
            </div>
        </div>
    </nav>

    <!-- Main Layout Container -->
    <div class="container-fluid flex-grow-1">
        <div class="row">
            
            <!-- SIDEBAR (Left Column) -->
            <!-- Hidden on mobile by default, toggled via JS -->
            <aside id="app-sidebar" class="col-lg-3 col-md-4 d-none d-md-block bg-white border-end vh-100 overflow-auto position-sticky top-0 pt-3 pb-5 sidebar-transition">
                
                <div class="p-3 mb-2 border-bottom">
                    <small class="text-uppercase text-secondary fw-bold">Menu</small>
                </div>

                <ul class="nav nav-pills flex-column p-2 gap-1">
                    
                    <?php if ($currentRole == 'admin' || $currentRole == 'dispatcher'): ?>
                        <!-- ADMIN/DISPATCHER MENU -->
                        <li class="nav-item">
                            <a class="nav-link active" href="/admin/dashboard.php"><i class="fas fa-tachometer-alt me-2"></i> Dashboard</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/admin/dispatch.php"><i class="fas fa-map-marked-alt me-2"></i> Live Dispatch Map</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/admin/drivers.php"><i class="fas fa-users me-2"></i> Manage Drivers</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/admin/commuters.php"><i class="fas fa-user-friends me-2"></i> Manage Commuters</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/admin/accounting.php"><i class="fas fa-file-invoice-dollar me-2"></i> Accounting & Payouts</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/admin/security_keys.php"><i class="fas fa-key me-2"></i> Security & Keys</a>
                        </li>
                        <li class="nav-item mt-3">
                            <small class="text-uppercase text-secondary fw-bold px-3">System</small>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/admin/settings.php"><i class="fas fa-cogs me-2"></i> Site Settings</a>
                        </li>

                    <?php elseif ($currentRole == 'driver'): ?>
                        <!-- DRIVER MENU -->
                        <li class="nav-item">
                            <a class="nav-link active" href="/driver/dashboard.php"><i class="fas fa-home me-2"></i> My Home</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/driver/rate_calculator.php"><i class="fas fa-calculator me-2"></i> Rate Calculator & GPS</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/driver/tasks.php"><i class="fas fa-list-check me-2"></i> Active Tasks</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/driver/expenses.php"><i class="fas fa-wallet me-2"></i> Expenses & Net Income</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/driver/reklamo_warnings.php"><i class="fas fa-exclamation-triangle me-2"></i> Warnings & Reklamo</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/driver/guide.php"><i class="fas fa-book-reader me-2"></i> User Guide</a>
                        </li>
                        <li class="nav-item mt-3">
                            <small class="text-uppercase text-secondary fw-bold px-3">Account</small>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/driver/profile.php"><i class="fas fa-id-card me-2"></i> My Profile & Rank</a>
                        </li>

                    <?php elseif ($currentRole == 'commuter'): ?>
                        <!-- COMMUTER MENU -->
                        <li class="nav-item">
                            <a class="nav-link active" href="/commuter/dashboard.php"><i class="fas fa-home me-2"></i> Home</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/commuter/book_ride.php"><i class="fas fa-plus-circle me-2"></i> Book Ride</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/commuter/track_order.php"><i class="fas fa-route me-2"></i> Track Order</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/commuter/favorite_drivers.php"><i class="fas fa-heart me-2"></i> Favorite Drivers</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/commuter/support_tickets.php"><i class="fas fa-life-ring me-2"></i> Support Tickets</a>
                        </li>
                        <li class="nav-item mt-3">
                            <small class="text-uppercase text-secondary fw-bold px-3">History</small>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/commuter/history.php"><i class="fas fa-history me-2"></i> Past Trips</a>
                        </li>

                    <?php else: ?>
                        <!-- GUEST MENU -->
                        <li class="nav-item">
                            <a class="nav-link active" href="/public/index.php"><i class="fas fa-info-circle me-2"></i> About Us</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/public/services.php"><i class="fas fa-shuttle-van me-2"></i> Our Services</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="/public/contact.php"><i class="fas fa-envelope me-2"></i> Contact</a>
                        </li>
                    <?php endif; ?>
                </ul>
            </aside>

            <!-- MAIN CONTENT AREA (Right Column) -->
            <main id="app-content" class="col-lg-9 col-md-8 py-4 px-3">
                <!-- Breadcrumb / Notification Area could go here -->
                <div id="flash-messages"></div> 
                
                <!-- The actual page content will be injected here by individual pages -->
                <!-- We use an opening div tag so footer.php can close it properly -->
                <div class="content-wrapper">
