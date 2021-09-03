CREATE TABLE "metric_d_bounces"(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('metric_d_bounces', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON metric_d_bounces (url, date DESC);

CREATE TABLE "metric_d_page_views"(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('metric_d_page_views"', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON metric_d_page_views (url, date DESC);

CREATE TABLE "metric_d_visits"(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('metric_d_visits', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON metric_d_visits(url, date DESC);

CREATE TABLE "metric_d_unique_visits"(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('metric_d_unique_visits', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON metric_d_unique_visits(url, date DESC);

CREATE TABLE "metric_success_score_type1_ratio"(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('metric_success_score_type1_ratio', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON metric_success_score_type1_ratio (url, date DESC);

CREATE TABLE "metric_success_score_type2_ratio"(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('metric_success_score_type2_ratio', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON metric_success_score_type2_ratio (url, date DESC);

CREATE TABLE "metric_success_score_type3_ratio"(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('metric_success_score_type3_ratio', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON metric_success_score_type3_ratio (url, date DESC);

CREATE TABLE "metric_success_score_ratio"(
    url TEXT,
    date DATE NOT NULL,
    value INTEGER
    );
SELECT create_hypertable('metric_success_score_ratio', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON metric_success_score_ratio (url, date DESC);

create role api_user;
grant usage on schema public to api_user;
grant select ON ALL TABLES IN SCHEMA public to api_user;

create role authenticator noinherit login password 'CHANGEME';
grant api_user to authenticator;

create role app_user nologin;
grant app_user to authenticator;

grant usage on schema public to app_user;
grant all ON ALL TABLES IN SCHEMA public to app_user;