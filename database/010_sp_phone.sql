-- Soul Project ESX: telefone, contactos, mensagens, chamadas e pedidos de serviço.
CREATE TABLE IF NOT EXISTS `sp_phone_numbers` (
    `identifier` VARCHAR(96) NOT NULL,
    `phone_number` VARCHAR(20) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    UNIQUE KEY `uq_sp_phone_number` (`phone_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sp_phone_contacts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_identifier` VARCHAR(96) NOT NULL,
    `display_name` VARCHAR(64) NOT NULL,
    `phone_number` VARCHAR(20) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sp_phone_contact` (`owner_identifier`, `phone_number`),
    KEY `idx_sp_phone_contacts_owner` (`owner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sp_phone_messages` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sender_number` VARCHAR(20) NOT NULL,
    `receiver_number` VARCHAR(20) NOT NULL,
    `body` VARCHAR(500) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `read_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sp_phone_messages_sender` (`sender_number`, `created_at`),
    KEY `idx_sp_phone_messages_receiver` (`receiver_number`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sp_phone_calls` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `caller_number` VARCHAR(20) NOT NULL,
    `receiver_number` VARCHAR(20) NOT NULL,
    `status` ENUM('missed', 'declined', 'completed', 'failed') NOT NULL,
    `duration_seconds` INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_sp_phone_calls_caller` (`caller_number`, `created_at`),
    KEY `idx_sp_phone_calls_receiver` (`receiver_number`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sp_phone_service_messages` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `service` VARCHAR(32) NOT NULL,
    `sender_identifier` VARCHAR(96) NOT NULL,
    `sender_number` VARCHAR(20) NOT NULL,
    `message` VARCHAR(500) NOT NULL,
    `coords` LONGTEXT NULL,
    `status` ENUM('open', 'accepted', 'closed') NOT NULL DEFAULT 'open',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_sp_phone_service_status` (`service`, `status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `sp_schema_migrations` (`version`, `description`)
VALUES ('010', 'Telefone Soul Project: números, contactos, SMS, chamadas e serviços');
