-- Create databases and users for different applications

-- lubpicking Database
CREATE DATABASE lubpicking_db;
CREATE USER lubpicking_user WITH PASSWORD '595a45c2eebf8649bfdc35799181ad9beb519ec55e83e8d2e79873e6678ab449';
GRANT ALL PRIVILEGES ON DATABASE lubpicking_db TO lubpicking_user;

-- Grant schema privileges
\c lubpicking_db;
GRANT ALL ON SCHEMA public TO lubpicking_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO lubpicking_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO lubpicking_user;