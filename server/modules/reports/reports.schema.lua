--- Reports de jogador. Tabela prefixada com o nome do resource (o DB é partilhado com outros
--- scripts); jogador referenciado pelo identifier da Framework — sem FK para tabelas de terceiros.
Schema.table('boilerplate_reports', [[
CREATE TABLE IF NOT EXISTS boilerplate_reports (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    author_identifier VARCHAR(64) NOT NULL,
    author_name VARCHAR(128) NOT NULL,
    message VARCHAR(512) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'open',
    closed_by VARCHAR(128) NULL,
    closed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_boilerplate_reports_author (author_identifier, status),
    KEY idx_boilerplate_reports_status (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]])
