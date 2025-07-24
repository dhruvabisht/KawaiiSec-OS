-- PostgreSQL Initialization Script for KawaiiSec Lab
-- WARNING: This contains intentional vulnerabilities for educational purposes only

-- Create additional databases
CREATE DATABASE webapp;
CREATE DATABASE ecommerce;
CREATE DATABASE blog;

-- Create users with weak passwords
CREATE USER webapp_user WITH PASSWORD 'password';
CREATE USER admin WITH PASSWORD 'admin123';
CREATE USER guest WITH PASSWORD 'guest';

-- Grant excessive privileges
GRANT ALL PRIVILEGES ON DATABASE webapp TO webapp_user;
GRANT ALL PRIVILEGES ON DATABASE ecommerce TO webapp_user;
GRANT ALL PRIVILEGES ON DATABASE blog TO admin;
ALTER USER admin CREATEDB CREATEROLE;

-- Connect to webapp database
\c webapp;

-- Create vulnerable users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data with weak passwords
INSERT INTO users (username, password, email, role) VALUES 
('admin', 'admin123', 'admin@kawaiisec.com', 'admin'),
('john', 'password', 'john@example.com', 'user'),
('jane', '123456', 'jane@example.com', 'user'),
('alice', 'alice', 'alice@example.com', 'moderator'),
('bob', 'qwerty', 'bob@example.com', 'user'),
('charlie', 'password123', 'charlie@example.com', 'user'),
('david', 'admin', 'david@example.com', 'user'),
('eve', 'password1', 'eve@example.com', 'user');

-- Create products table for SQL injection testing
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    category VARCHAR(50),
    stock_quantity INTEGER DEFAULT 0
);

-- Insert sample products
INSERT INTO products (name, description, price, category, stock_quantity) VALUES 
('Laptop', 'High-performance laptop for cybersecurity professionals', 1299.99, 'Electronics', 10),
('Security Handbook', 'Comprehensive guide to penetration testing', 49.99, 'Books', 25),
('WiFi Adapter', 'USB wireless adapter for security testing', 29.99, 'Electronics', 15),
('Kali Linux USB', 'Bootable Kali Linux on USB drive', 19.99, 'Software', 20),
('Network Scanner', 'Professional network vulnerability scanner', 199.99, 'Software', 5);

-- Create orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending'
);

-- Insert sample orders
INSERT INTO orders (user_id, product_id, quantity, status) VALUES 
(2, 1, 1, 'completed'),
(3, 2, 2, 'pending'),
(4, 3, 1, 'shipped'),
(5, 4, 3, 'completed');

-- Create logs table for log injection testing
CREATE TABLE logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action VARCHAR(100),
    details TEXT,
    ip_address INET,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample log entries
INSERT INTO logs (user_id, action, details, ip_address) VALUES 
(1, 'login', 'Admin user logged in', '192.168.1.100'),
(2, 'view_product', 'Viewed laptop product page', '192.168.1.101'),
(3, 'search', 'Searched for security books', '192.168.1.102'),
(1, 'user_management', 'Added new user', '192.168.1.100');

-- Connect to ecommerce database
\c ecommerce;

-- Create customers table
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    credit_card VARCHAR(20), -- Storing credit cards in plain text (vulnerable!)
    ssn VARCHAR(11),         -- Storing SSN (vulnerable!)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample customer data (with fake but realistic-looking data)
INSERT INTO customers (first_name, last_name, email, phone, address, credit_card, ssn) VALUES 
('John', 'Doe', 'john.doe@email.com', '555-0123', '123 Main St, Anytown USA', '4532123456789012', '123-45-6789'),
('Jane', 'Smith', 'jane.smith@email.com', '555-0124', '456 Oak Ave, Somewhere USA', '5555123456789012', '987-65-4321'),
('Alice', 'Johnson', 'alice.j@email.com', '555-0125', '789 Pine Rd, Elsewhere USA', '4716123456789012', '456-78-9123');

-- Create sessions table (vulnerable session management)
CREATE TABLE user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    session_token VARCHAR(100),
    ip_address INET,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Insert sample sessions with predictable tokens
INSERT INTO user_sessions (user_id, session_token, ip_address, expires_at) VALUES 
(1, 'admin_session_12345', '192.168.1.100', CURRENT_TIMESTAMP + INTERVAL '1 day'),
(2, 'user_session_67890', '192.168.1.101', CURRENT_TIMESTAMP + INTERVAL '1 day'),
(3, 'session_abcdef123456', '192.168.1.102', CURRENT_TIMESTAMP + INTERVAL '1 day');

-- Connect to blog database
\c blog;

-- Create posts table
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200),
    content TEXT,
    author_id INTEGER,
    published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create comments table (vulnerable to XSS)
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id),
    author_name VARCHAR(100),
    email VARCHAR(100),
    content TEXT, -- No sanitization, allows XSS
    approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample blog posts
INSERT INTO posts (title, content, author_id, published) VALUES 
('Welcome to KawaiiSec Blog', 'This is our first blog post about cybersecurity education!', 1, TRUE),
('SQL Injection Basics', 'Learn about SQL injection vulnerabilities and how to prevent them.', 1, TRUE),
('XSS Prevention Guide', 'Cross-site scripting attacks and defense strategies.', 1, FALSE);

-- Insert sample comments (some with XSS payloads for testing)
INSERT INTO comments (post_id, author_name, email, content) VALUES 
(1, 'Security Student', 'student@example.com', 'Great post! Looking forward to learning more.'),
(1, 'Hacker', 'hacker@evil.com', '<script>alert("XSS Test")</script>Nice blog!'),
(2, 'Alice', 'alice@example.com', 'Very informative article about SQL injection.');

-- Grant permissions to users
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO webapp_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO webapp_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

-- Create a function that's vulnerable to SQL injection
CREATE OR REPLACE FUNCTION search_users(search_term TEXT)
RETURNS TABLE(username VARCHAR, email VARCHAR) AS $$
BEGIN
    -- Vulnerable dynamic SQL construction
    RETURN QUERY EXECUTE 'SELECT u.username, u.email FROM users u WHERE u.username LIKE ''%' || search_term || '%''';
END;
$$ LANGUAGE plpgsql;

-- Create a view that exposes sensitive data
CREATE VIEW user_info AS 
SELECT u.username, u.email, u.role, c.credit_card, c.ssn
FROM webapp.users u
LEFT JOIN ecommerce.customers c ON u.email = c.email;

-- Add some configuration that makes the database more vulnerable
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_min_messages = 'debug1';

-- Note: In a real environment, you would NEVER do these things:
-- 1. Store credit cards in plain text
-- 2. Store SSNs in plain text  
-- 3. Use predictable session tokens
-- 4. Allow SQL injection vulnerabilities
-- 5. Store XSS payloads without sanitization
-- 6. Grant excessive database privileges
--
-- This is for educational purposes only! 