CREATE DATABASE IF NOT EXISTS `${DB_NAME}` CHARACTER SET utf8mb4;

-- Usuari de la pràctica (accés complet a la base de dades)
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON `${DB_NAME}`.* TO '${DB_USER}'@'%';

FLUSH PRIVILEGES;
