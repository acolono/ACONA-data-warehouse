CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
CREATE SCHEMA api;
CREATE SCHEMA internal;
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



create role api_anon;
grant usage on schema api to api_anon;
grant select ON ALL TABLES IN SCHEMA api to api_anon;

create role authenticator noinherit login password 'CHANGEME';
grant api_anon to authenticator;

create role app_user nologin;
grant app_user to authenticator;

grant usage on schema api to app_user;
grant all ON ALL TABLES IN SCHEMA api to app_user;