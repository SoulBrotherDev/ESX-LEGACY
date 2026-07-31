-- Soul Project ESX: itens essenciais reutilizáveis.
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    ('phone', 'Telemóvel', 1, 0, 1),
    ('radio', 'Rádio', 1, 0, 1)
ON DUPLICATE KEY UPDATE
    `label` = VALUES(`label`),
    `weight` = VALUES(`weight`),
    `rare` = VALUES(`rare`),
    `can_remove` = VALUES(`can_remove`);

INSERT IGNORE INTO `sp_schema_migrations` (`version`, `description`)
VALUES ('005', 'Itens essenciais: telemóvel e rádio');
