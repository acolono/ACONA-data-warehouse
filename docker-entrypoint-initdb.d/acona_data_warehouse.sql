CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
CREATE SCHEMA api;
CREATE SCHEMA internal;

/*PERFORMANCE METRICS*/

CREATE TABLE api.metric_d_bounces(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('api.metric_d_bounces', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON api.metric_d_bounces (url, date DESC);

CREATE TABLE api.metric_d_page_views(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('api.metric_d_page_views', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON api.metric_d_page_views (url, date DESC);

CREATE TABLE api.metric_d_visits(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('api.metric_d_visits', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON api.metric_d_visits(url, date DESC);

CREATE TABLE api.metric_d_unique_visits(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('api.metric_d_unique_visits', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON api.metric_d_unique_visits(url, date DESC);

/*PAGE VARIABLES*/

/*SUCCESS SCORES*/

CREATE TABLE api.metric_success_score_type1_ratio(
    url TEXT,
    date DATE NOT NULL,
    value DECIMAL
    );
SELECT create_hypertable('api.metric_success_score_type1_ratio', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON api.metric_success_score_type1_ratio (url, date DESC);

CREATE TABLE api.metric_success_score_type2_ratio(
    url TEXT,
    date DATE NOT NULL,
    value DECIMAL
    );
SELECT create_hypertable('api.metric_success_score_type2_ratio', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON api.metric_success_score_type2_ratio (url, date DESC);

CREATE TABLE api.metric_success_score_type3_ratio(
    url TEXT,
    date DATE NOT NULL,
    value DECIMAL
    );
SELECT create_hypertable('api.metric_success_score_type3_ratio', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON api.metric_success_score_type3_ratio (url, date DESC);

CREATE TABLE api.metric_success_score_ratio(
    url TEXT,
    date DATE NOT NULL,
    value DECIMAL
    );
SELECT create_hypertable('api.metric_success_score_ratio', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON api.metric_success_score_ratio (url, date DESC);

/*INTERNAL TABLES*/

CREATE TABLE internal.urls(
    url TEXT NOT NULL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    domain_id INTEGER,
    status BOOLEAN,
    intervall TEXT DEFAULT 'daily',
    pagetype INTEGER,
    first DATE,
    Last DATE
);

CREATE TABLE internal.users(
    user_id INTEGER NOT NULL PRIMARY KEY,
    user_name TEXT,
    status BOOLEAN,
    mail TEXT
);

CREATE TABLE internal.domains(
    domain_id INTEGER NOT NULL PRIMARY KEY,
    domain_name TEXT,
    users INTEGER[],
    synonyms TEXT[]
);

/*FUNCTIONS*/

CREATE OR REPLACE FUNCTION api.acona_success_scores(url TEXT, from_date DATE DEFAULT now() - INTERVAL '7 days', to_date DATE DEFAULT now())
    RETURNS table(date date, url text, value decimal) as $$
SELECT
    date,
    url,
    value
FROM api.metric_success_score_ratio s
WHERE s.url = $1
  AND s.date >= $2
  AND s.date <= $3
ORDER BY s.date DESC
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION api.acona_urls_success(domain TEXT)
    RETURNS table(url text, date date, value decimal) as $$
SELECT
    urls.url,
    scores.date,
    scores.value
FROM internal.urls urls
    LEFT JOIN api.metric_success_score_ratio scores
        ON (urls.url = scores.url)
           AND scores.date=(select max(date) from api.metric_success_score_ratio where url = urls.url)
WHERE urls.domain_id = (
    SELECT domain_id
    FROM internal.domains domains
    WHERE domains.domain_name = $1
);
$$ LANGUAGE SQL IMMUTABLE
    SECURITY DEFINER
    SET search_path = internal, pg_temp;

/*USERS AND ROLES*/

create role api_anon;
grant usage on schema api to api_anon;
grant select ON ALL TABLES IN SCHEMA api to api_anon;

create role authenticator noinherit login password 'CHANGEME';
grant api_anon to authenticator;

create role app_user nologin;
grant app_user to authenticator;

grant usage on schema api to app_user;
grant all ON ALL TABLES IN SCHEMA api to app_user;

/*EXAMPLE CONTENT*/
INSERT INTO internal.urls(url, user_id, domain_id, status, intervall, pagetype)
VALUES
       ('https://www.acona.app/about', 1, 1, TRUE, 'daily', 1),
       ('https://www.acona.app/metrics', 1, 1, TRUE, 'daily', 2);
INSERT INTO internal.users(user_id, user_name, status, mail) VALUES (1, 'acona_user', TRUE, 'mail@mail.com');
INSERT INTO internal.domains(domain_id, domain_name, users)
VALUES (1, 'https://www.acona.app', '{1}');
INSERT INTO api.metric_success_score_ratio(url, date, value)
VALUES
('https://www.acona.app/about', '2021-08-25', 0.3),
('https://www.acona.app/about', '2021-08-26', 0.3),
('https://www.acona.app/about', '2021-08-27', 0.5),
('https://www.acona.app/about', '2021-08-28', 0.5),
('https://www.acona.app/about', '2021-08-29', 0.5),
('https://www.acona.app/about', '2021-08-30', 0.8),
('https://www.acona.app/about', '2021-08-31', 0.5),
('https://www.acona.app/about', '2021-09-01', 0.8),
('https://www.acona.app/about', '2021-09-02', 0.8),
('https://www.acona.app/about', '2021-09-03', 0.8),
('https://www.acona.app/metrics', '2021-08-25', 0.3),
('https://www.acona.app/metrics', '2021-08-26', 0.5),
('https://www.acona.app/metrics', '2021-08-27', 0.6),
('https://www.acona.app/metrics', '2021-08-28', 0.6),
('https://www.acona.app/metrics', '2021-08-29', 0.6),
('https://www.acona.app/metrics', '2021-08-31', 0.3),
('https://www.acona.app/metrics', '2021-08-30', 0.7),
('https://www.acona.app/metrics', '2021-09-01', 0.5),
('https://www.acona.app/metrics', '2021-09-02', 0.6),
('https://www.acona.app/metrics', '2021-09-03', 0.6),
('https://www.acona.app/metrics', '2021-09-04', 0.6),
('https://www.acona.app/metrics', '2021-09-05', 0.7);
INSERT INTO api.metric_d_bounces(url, date, value)
VALUES
('https://www.acona.app/about', '2021-08-25', 10),
('https://www.acona.app/about', '2021-08-26', 3),
('https://www.acona.app/about', '2021-08-27', 100),
('https://www.acona.app/about', '2021-08-28', 5);