-- Soul Project ESX: nomenclatura PT-PT para empregos essenciais.
UPDATE `jobs` SET `label` = 'Desempregado' WHERE `name` = 'unemployed';
UPDATE `jobs` SET `label` = 'Polícia' WHERE `name` = 'police';
UPDATE `jobs` SET `label` = 'Emergência Médica' WHERE `name` = 'ambulance';
UPDATE `jobs` SET `label` = 'Mecânico' WHERE `name` = 'mechanic';
UPDATE `jobs` SET `label` = 'Táxi' WHERE `name` = 'taxi';
UPDATE `jobs` SET `label` = 'Concessionário' WHERE `name` = 'cardealer';
UPDATE `jobs` SET `label` = 'Imobiliária' WHERE `name` = 'realestateagent';

UPDATE `job_grades` SET `label` = 'Recruta' WHERE `job_name` = 'police' AND `grade` = 0;
UPDATE `job_grades` SET `label` = 'Agente' WHERE `job_name` = 'police' AND `grade` = 1;
UPDATE `job_grades` SET `label` = 'Sargento' WHERE `job_name` = 'police' AND `grade` = 2;
UPDATE `job_grades` SET `label` = 'Tenente' WHERE `job_name` = 'police' AND `grade` = 3;
UPDATE `job_grades` SET `label` = 'Comandante' WHERE `job_name` = 'police' AND `grade` >= 4;

UPDATE `job_grades` SET `label` = 'Estagiário' WHERE `job_name` = 'ambulance' AND `grade` = 0;
UPDATE `job_grades` SET `label` = 'Paramédico' WHERE `job_name` = 'ambulance' AND `grade` = 1;
UPDATE `job_grades` SET `label` = 'Médico' WHERE `job_name` = 'ambulance' AND `grade` = 2;
UPDATE `job_grades` SET `label` = 'Diretor Clínico' WHERE `job_name` = 'ambulance' AND `grade` >= 3;

INSERT IGNORE INTO `sp_schema_migrations` (`version`, `description`)
VALUES ('020', 'Nomenclatura PT-PT dos empregos ESX essenciais');
