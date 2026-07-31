CREATE TABLE IF NOT EXISTS `sp_schema_migrations` (
  `id` varchar(100) NOT NULL,
  `description` varchar(255) NOT NULL,
  `checksum` char(64) DEFAULT NULL,
  `applied_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `sp_schema_migrations` (`id`, `description`)
VALUES ('000_sp_base', 'Inicialização da base Soul Project ESX Legacy');
