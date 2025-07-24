-- MySQL Initialization Script for KawaiiSec Lab
-- WARNING: This contains intentional vulnerabilities for educational purposes only

-- Create additional databases
CREATE DATABASE IF NOT EXISTS webapp;
CREATE DATABASE IF NOT EXISTS store;
CREATE DATABASE IF NOT EXISTS forum;

-- Create users with weak passwords (MySQL format)
CREATE USER IF NOT EXISTS 'webapp_user'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin123';
CREATE USER IF NOT EXISTS 'guest'@'%' IDENTIFIED BY 'guest';
CREATE USER IF NOT EXISTS 'anonymous'@'%' IDENTIFIED BY '';

-- Grant excessive privileges
GRANT ALL PRIVILEGES ON webapp.* TO 'webapp_user'@'%';
GRANT ALL PRIVILEGES ON store.* TO 'webapp_user'@'%';
GRANT ALL PRIVILEGES ON forum.* TO 'admin'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
GRANT SELECT ON *.* TO 'guest'@'%';
GRANT SELECT ON testdb.* TO 'anonymous'@'%';

-- Use webapp database
USE webapp;

-- Create vulnerable users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    role ENUM('admin', 'moderator', 'user') DEFAULT 'user',
    last_login DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users with weak passwords (MD5 hashed - weak!)
INSERT INTO users (username, password, email, role, last_login) VALUES 
('admin', MD5('admin123'), 'admin@kawaiisec.com', 'admin', NOW()),
('john', MD5('password'), 'john@example.com', 'user', NOW() - INTERVAL 1 DAY),
('jane', MD5('123456'), 'jane@example.com', 'user', NOW() - INTERVAL 2 DAY),
('alice', MD5('alice'), 'alice@example.com', 'moderator', NOW() - INTERVAL 1 HOUR),
('bob', MD5('qwerty'), 'bob@example.com', 'user', NOW() - INTERVAL 3 DAY),
('charlie', MD5('password123'), 'charlie@example.com', 'user', NULL);

-- Create products table
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    category VARCHAR(50),
    stock_quantity INT DEFAULT 0,
    image_url VARCHAR(255)
);

-- Insert sample products
INSERT INTO products (name, description, price, category, stock_quantity, image_url) VALUES 
('Penetration Testing Kit', 'Complete toolkit for ethical hacking', 299.99, 'Hardware', 5, '/images/pentesting-kit.jpg'),
('Cybersecurity Course', 'Online course on cybersecurity fundamentals', 99.99, 'Education', 100, '/images/course.jpg'),
('WiFi Pineapple', 'Wireless auditing platform', 199.99, 'Hardware', 3, '/images/pineapple.jpg'),
('Rubber Ducky', 'USB keystroke injection tool', 49.99, 'Hardware', 15, '/images/rubber-ducky.jpg');

-- Create vulnerable file uploads table
CREATE TABLE file_uploads (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255),
    original_name VARCHAR(255),
    file_path VARCHAR(500),
    file_size INT,
    mime_type VARCHAR(100),
    uploaded_by INT,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (uploaded_by) REFERENCES users(id)
);

-- Insert sample file uploads (some potentially dangerous)
INSERT INTO file_uploads (filename, original_name, file_path, file_size, mime_type, uploaded_by) VALUES 
('safe_document.pdf', 'manual.pdf', '/uploads/safe_document.pdf', 1024000, 'application/pdf', 2),
('backdoor.php', 'image.jpg', '/uploads/backdoor.php', 2048, 'application/x-php', 3),
('shell.jsp', 'report.doc', '/uploads/shell.jsp', 4096, 'application/x-jsp', 4);

-- Use store database
USE store;

-- Create customers table with PII
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    credit_card_number VARCHAR(20), -- Plain text storage (vulnerable!)
    credit_card_expiry VARCHAR(7),  -- MM/YYYY format
    credit_card_cvv VARCHAR(4),     -- Plain text CVV (very vulnerable!)
    ssn VARCHAR(11),                -- Plain text SSN (vulnerable!)
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample customer data (fake but realistic)
INSERT INTO customers (first_name, last_name, email, phone, address, city, state, zip_code, credit_card_number, credit_card_expiry, credit_card_cvv, ssn, date_of_birth) VALUES 
('John', 'Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'Anytown', 'CA', '12345', '4532123456789012', '12/2025', '123', '123-45-6789', '1985-03-15'),
('Sarah', 'Johnson', 'sarah.j@email.com', '555-0102', '456 Oak Ave', 'Somewhere', 'NY', '67890', '5555123456789012', '08/2024', '456', '987-65-4321', '1990-07-22'),
('Mike', 'Brown', 'mike.brown@email.com', '555-0103', '789 Pine Rd', 'Elsewhere', 'TX', '54321', '4716123456789012', '03/2026', '789', '456-78-9123', '1988-11-08');

-- Create orders table
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    total_amount DECIMAL(10,2),
    order_status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    payment_method VARCHAR(50),
    shipping_address TEXT,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- Insert sample orders
INSERT INTO orders (customer_id, total_amount, order_status, payment_method, shipping_address) VALUES 
(1, 299.99, 'delivered', 'Credit Card', '123 Main St, Anytown, CA 12345'),
(2, 149.98, 'processing', 'Credit Card', '456 Oak Ave, Somewhere, NY 67890'),
(3, 49.99, 'shipped', 'PayPal', '789 Pine Rd, Elsewhere, TX 54321');

-- Create payment logs (storing sensitive data in logs - vulnerable!)
CREATE TABLE payment_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    transaction_id VARCHAR(100),
    amount DECIMAL(10,2),
    credit_card_last4 VARCHAR(4),
    full_card_number VARCHAR(20), -- Should never store this!
    cvv VARCHAR(4),               -- Should never store this!
    processing_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id)
);

-- Insert payment logs with sensitive data (very bad practice!)
INSERT INTO payment_logs (order_id, transaction_id, amount, credit_card_last4, full_card_number, cvv, processing_response) VALUES 
(1, 'TXN-2024-001', 299.99, '9012', '4532123456789012', '123', 'SUCCESS: Payment processed'),
(2, 'TXN-2024-002', 149.98, '9012', '5555123456789012', '456', 'SUCCESS: Payment processed'),
(3, 'TXN-2024-003', 49.99, '9012', '4716123456789012', '789', 'SUCCESS: Payment processed');

-- Use forum database
USE forum;

-- Create posts table
CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200),
    content TEXT,
    author_id INT,
    category VARCHAR(50),
    published BOOLEAN DEFAULT TRUE,
    view_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create comments table (vulnerable to XSS)
CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT,
    author_name VARCHAR(100),
    email VARCHAR(100),
    website VARCHAR(200),
    content TEXT, -- No XSS protection
    ip_address VARCHAR(45),
    user_agent TEXT,
    approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

-- Insert sample forum posts
INSERT INTO posts (title, content, author_id, category, view_count) VALUES 
('Welcome to KawaiiSec Forum!', 'This is our community forum for cybersecurity discussions.', 1, 'General', 150),
('SQL Injection Prevention', 'Best practices for preventing SQL injection attacks in web applications.', 1, 'Security', 89),
('XSS Vulnerability Research', 'Latest research on cross-site scripting vulnerabilities.', 2, 'Research', 45),
('Password Security Tips', 'How to create and manage strong passwords.', 3, 'Tips', 120);

-- Insert comments with XSS payloads (for testing)
INSERT INTO comments (post_id, author_name, email, website, content, ip_address, user_agent) VALUES 
(1, 'Security Enthusiast', 'user@example.com', 'https://example.com', 'Great forum! Looking forward to participating.', '192.168.1.100', 'Mozilla/5.0 (compatible; Browser/1.0)'),
(1, 'Hacker', 'hacker@evil.com', 'javascript:alert("XSS")', '<script>alert("XSS Test")</script>Nice work!', '192.168.1.101', 'AttackBot/1.0'),
(2, 'Developer', 'dev@company.com', 'https://company.com', 'Thanks for the security tips!', '192.168.1.102', 'Mozilla/5.0 (compatible; Chrome/1.0)'),
(3, 'Malicious User', 'evil@bad.com', 'http://malicious.com', '<img src="x" onerror="alert(''Stored XSS'')">Interesting post!', '192.168.1.103', 'EvilBot/1.0');

-- Create admin interface logs (storing admin actions)
CREATE TABLE admin_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_id INT,
    action VARCHAR(100),
    target_table VARCHAR(50),
    target_id INT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample admin logs
INSERT INTO admin_logs (admin_id, action, target_table, target_id, old_values, new_values, ip_address) VALUES 
(1, 'DELETE_USER', 'users', 999, '{"username": "baduser", "email": "bad@example.com"}', NULL, '192.168.1.100'),
(1, 'UPDATE_POST', 'posts', 2, '{"title": "Old Title"}', '{"title": "SQL Injection Prevention"}', '192.168.1.100');

-- Create a vulnerable stored procedure
DELIMITER //
CREATE PROCEDURE GetUserByName(IN userName VARCHAR(100))
BEGIN
    -- Vulnerable to SQL injection
    SET @sql = CONCAT('SELECT * FROM webapp.users WHERE username = "', userName, '"');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END//
DELIMITER ;

-- Create a function that's vulnerable to SQL injection
DELIMITER //
CREATE FUNCTION SearchProducts(searchTerm VARCHAR(100))
RETURNS TEXT
READS SQL DATA
BEGIN
    DECLARE result TEXT DEFAULT '';
    -- Vulnerable dynamic SQL
    SET @sql = CONCAT('SELECT GROUP_CONCAT(name) FROM store.products WHERE name LIKE "%', searchTerm, '%"');
    -- In a real vulnerable app, this would be executed dynamically
    RETURN CONCAT('Search query: ', @sql);
END//
DELIMITER ;

-- Switch back to testdb (the default database)
USE testdb;

-- Create a view that exposes sensitive information across databases
CREATE VIEW sensitive_data_view AS
SELECT 
    u.username,
    u.email,
    u.role,
    c.credit_card_number,
    c.credit_card_cvv,
    c.ssn
FROM webapp.users u
LEFT JOIN store.customers c ON u.email = c.email;

-- Create a table for storing application errors (with sensitive data leakage)
CREATE TABLE error_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    error_type VARCHAR(100),
    error_message TEXT,
    stack_trace TEXT,
    user_input TEXT, -- Dangerous: might contain passwords, etc.
    user_id INT,
    session_data JSON, -- Dangerous: might contain sensitive session info
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample error logs that leak sensitive information
INSERT INTO error_logs (error_type, error_message, stack_trace, user_input, user_id, session_data) VALUES 
('AuthenticationError', 'Login failed for user', 'Stack trace here...', 'username=admin&password=admin123', 1, '{"session_id": "abc123", "user_role": "admin"}'),
('SQLError', 'SQL syntax error', 'MySQL error trace...', 'search=\'; DROP TABLE users; --', 2, '{"session_id": "def456", "csrf_token": "token123"}');

FLUSH PRIVILEGES;

-- Add MySQL-specific vulnerable configurations
-- Note: These would typically be set in my.cnf, but we're setting them here for demonstration

-- Enable general query log (logs all queries including those with passwords)
SET GLOBAL general_log = 'ON';
SET GLOBAL general_log_file = '/var/lib/mysql/general.log';

-- Enable slow query log with very low threshold (logs almost everything)
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL slow_query_log_file = '/var/lib/mysql/slow.log';
SET GLOBAL long_query_time = 0;
SET GLOBAL log_queries_not_using_indexes = 'ON';

-- WARNING: This configuration is intentionally vulnerable for educational purposes!
-- In a production environment, you should NEVER:
-- 1. Store credit card numbers, CVVs, or SSNs in plain text
-- 2. Use weak password hashing (MD5)
-- 3. Grant excessive database privileges
-- 4. Log sensitive user input
-- 5. Create SQL injection vulnerabilities
-- 6. Allow XSS in stored data
-- 7. Store full credit card details
-- 8. Use predictable or weak passwords
--
-- This is for educational purposes only! 