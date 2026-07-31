-- Soul Project ESX: controlo idempotente do kit inicial.
CREATE TABLE IF NOT EXISTS `sp_starter_claims` (
    `identifier` VARCHAR(96) NOT NULL,
    `claimed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `payload` LONGTEXT NULL,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `sp_schema_migrations` (`version`, `description`)
VALUES ('015', 'Registo idempotente do kit inicial');
