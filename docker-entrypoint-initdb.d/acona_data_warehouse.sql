CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
SET timezone = 'Europe/Vienna';
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

CREATE TABLE api.var_page_ttfb_seconds(
    url TEXT NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    value INTEGER
);
SELECT create_hypertable('api.var_page_ttfb_seconds', 'datetime', create_default_indexes=>FALSE);
CREATE INDEX ON api.var_page_ttfb_seconds (url, datetime DESC);

CREATE TABLE api.var_page_h1_number(
    url TEXT NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    value INTEGER
);
SELECT create_hypertable('api.var_page_h1_number', 'datetime', create_default_indexes=>FALSE);
CREATE INDEX ON api.var_page_h1_number(url, datetime DESC);

CREATE TABLE api.var_page_metadescription(
    url TEXT NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    value TEXT
);
SELECT create_hypertable('api.var_page_metadescription', 'datetime', create_default_indexes=>FALSE);
CREATE INDEX ON api.var_page_metadescription(url, datetime DESC);

CREATE TABLE api.var_page_word_count(
    url TEXT NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    value INTEGER
);
SELECT create_hypertable('api.var_page_word_count', 'datetime', create_default_indexes=>FALSE);
CREATE INDEX ON api.var_page_word_count(url, datetime DESC);

CREATE TABLE api.var_page_content(
    url TEXT NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    value TEXT
);
SELECT create_hypertable('api.var_page_content', 'datetime', create_default_indexes=>FALSE);
CREATE INDEX ON api.var_page_content(url, datetime DESC);

CREATE TABLE api.var_page_title(
    url TEXT NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    value TEXT
);
SELECT create_hypertable('api.var_page_title', 'datetime', create_default_indexes=>FALSE);
CREATE INDEX ON api.var_page_title(url, datetime DESC);

CREATE TABLE api.var_page_content_html(
    url TEXT NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    value TEXT
);
SELECT create_hypertable('api.var_page_content_html', 'datetime', create_default_indexes=>FALSE);
CREATE INDEX ON api.var_page_content_html(url, datetime DESC);

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

/* RULES AND SUCCESS SCORES */

CREATE TABLE api.metric_rules_eval(
    url TEXT NOT NULL,
    date DATE NOT NULL,
    result BOOLEAN,
    rule_id VARCHAR(30) NOT NULL
);
SELECT create_hypertable('api.metric_rules_eval', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON api.metric_rules_eval(rule_id, url, date DESC);

/*INTERNAL TABLES*/

CREATE TABLE internal.acona_rules(
    rule_id VARCHAR(30) NOT NULL PRIMARY KEY,
    title_en TEXT,
    title_de TEXT,
    recommendation_en TEXT,
    recommendation_de TEXT,
    variable VARCHAR(30) NOT NULL,
    category TEXT,
    relevance INTEGER, /* 1-3 */
    indication VARCHAR(10) NOT NULL, /* green, yellow, red */
    condition JSON NOT NULL,
    more_de TEXT,
    more_en TEXT
);

CREATE TABLE internal.recommendation(
    rule_id VARCHAR(30) NOT NULL,
    langcode VARCHAR(2) NOT NULL,
    title TEXT,
    recommendation_text TEXT,
    more TEXT,
    PRIMARY KEY (rule_id, langcode)
);

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

CREATE TABLE internal.var_calc_dates(
    variable VARCHAR(30) NOT NULL,
    date DATE NOT NULL,
    url TEXT NOT NULL
);
SELECT create_hypertable('internal.var_calc_dates', 'date', create_default_indexes=>FALSE);
CREATE INDEX ON internal.var_calc_dates(variable, url);

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

CREATE OR REPLACE FUNCTION api.recommendations(url TEXT, date DATE DEFAULT now(), indication TEXT DEFAULT 'red,yellow,green', langcode TEXT DEFAULT 'en')
    RETURNS table(indication text, title TEXT, recommendation TEXT, date date, more TEXT, category TEXT, relevance INTEGER) as $$
SELECT
    rules.indication,
    recommendation.title,
    recommendation.recommendation_text AS recommendation,
    eval.date,
    recommendation.more,
    rules.category,
    rules.relevance
FROM internal.acona_rules rules
    INNER JOIN api.metric_rules_eval eval
        ON (rules.rule_id = eval.rule_id
            AND eval.date=$2
            AND eval.url = $1)
    LEFT JOIN internal.recommendation
        ON (rules.rule_id = recommendation.rule_id AND
            recommendation.langcode = $4)
WHERE rules.indication = ANY(string_to_array($3, ','));
$$ LANGUAGE SQL IMMUTABLE
    SECURITY DEFINER
    SET search_path = internal, pg_temp;

CREATE OR REPLACE FUNCTION api.recommendations_last(url TEXT, indication TEXT DEFAULT 'red,yellow,green', langcode TEXT DEFAULT 'en')
    RETURNS table(indication text, title TEXT, recommendation  TEXT, date date, more TEXT, category TEXT, relevance INTEGER) as $$
SELECT
    rules.indication,
    recommendation.title,
    recommendation.recommendation_text AS recommendation,
    eval.date,
    recommendation.more,
    rules.category,
    rules.relevance
    FROM internal.acona_rules rules
    INNER JOIN api.metric_rules_eval eval
        ON (rules.rule_id = eval.rule_id
            AND eval.date=(
                SELECT max(date)
                FROM internal.var_calc_dates calc_dates
                WHERE calc_dates.url = $1
                AND calc_dates.variable = 'metric_rules_eval'
            )
        AND eval.url = $1)
    LEFT JOIN internal.recommendation
        ON (rules.rule_id = recommendation.rule_id AND
            recommendation.langcode = $3)
    WHERE rules.indication = ANY(string_to_array($2,','));
$$ LANGUAGE SQL IMMUTABLE
    SECURITY DEFINER
    SET search_path = internal, pg_temp;

CREATE OR REPLACE FUNCTION api.acona_urls_by_domain(domain TEXT)
    RETURNS table(url text, domain_id text) as $$
SELECT
    urls.url,
    urls.domain_id
FROM internal.urls urls
WHERE urls.status = 't' AND urls.domain_id = (
    SELECT domain_id
    FROM internal.domains domains
    WHERE domains.domain_name = $1
);
$$ LANGUAGE SQL IMMUTABLE
                SECURITY DEFINER
                SET search_path = internal, pg_temp;

CREATE OR REPLACE FUNCTION api.acona_urls()
    RETURNS table(url text, domain_id text) as $$
SELECT
    urls.url,
    urls.domain_id
FROM internal.urls urls
WHERE urls.status = 't';
$$ LANGUAGE SQL IMMUTABLE
                SECURITY DEFINER
                SET search_path = internal, pg_temp;

/*USERS AND ROLES*/

create role api_anon;
grant usage on schema api to api_anon;
---grant select ON ALL TABLES IN SCHEMA api to api_anon;

create role authenticator noinherit login password 'CHANGEME';
grant api_anon to authenticator;

create role app_user nologin;
grant app_user to authenticator;

grant usage on schema api to app_user;
grant all ON ALL TABLES IN SCHEMA api to app_user;

/* Add our own permission check*/
create schema auth;
grant usage on schema auth to api_anon, app_user;

create or replace function auth.check_token() returns void
    language plpgsql
as $$
begin
    -- check if jwt token is from an active user
    -- Note: For multi tenant use check also access to domain/urls here or in rpc functions.
    if current_setting('request.jwt.claim.email', true) = NULL or not exists(select user_id
        from internal.users
        where status = 't'
        and mail = current_setting('request.jwt.claim.email', true))
    then
        raise insufficient_privilege
        using hint = 'Access denied.';
    end if;
end
$$ SECURITY DEFINER
   SET search_path = internal, pg_temp;

/*EXAMPLE CONTENT*/
INSERT INTO internal.urls(url, user_id, domain_id, status, intervall, pagetype)
VALUES
       ('https://www.acona.app/about', 1, 1, TRUE, 'daily', 1),
       ('https://www.acona.app/metrics', 1, 1, TRUE, 'daily', 2),
       ('https://www.acona.app/legal', 1, 1, TRUE, 'daily', 1),
       ('https://www.acona.app/info', 1, 1, TRUE, 'daily', 2),
       ('https://www.acona.app/', 1, 1, TRUE, 'daily', 2);
INSERT INTO internal.users(user_id, user_name, status, mail) VALUES (1, 'acona_user', TRUE, 'mail@mail.com');
INSERT INTO internal.domains(domain_id, domain_name, users)
VALUES (1, 'https://www.acona.app', '{1}');
INSERT INTO api.metric_success_score_ratio(url, date, value)
VALUES
('https://www.acona.app/about', '2021-08-25', 30),
('https://www.acona.app/about', '2021-08-26', 30),
('https://www.acona.app/about', '2021-08-27', 50),
('https://www.acona.app/about', '2021-08-28', 50),
('https://www.acona.app/about', '2021-08-29', 50),
('https://www.acona.app/about', '2021-08-30', 80),
('https://www.acona.app/about', '2021-08-31', 50),
('https://www.acona.app/about', '2021-09-01', 80),
('https://www.acona.app/about', '2021-09-02', 80),
('https://www.acona.app/about', '2021-09-03', 80),
('https://www.acona.app/metrics', '2021-08-25', 30),
('https://www.acona.app/metrics', '2021-08-26', 50),
('https://www.acona.app/metrics', '2021-08-27', 60),
('https://www.acona.app/metrics', '2021-08-28', 60),
('https://www.acona.app/metrics', '2021-08-29', 60),
('https://www.acona.app/metrics', '2021-08-31', 30),
('https://www.acona.app/metrics', '2021-08-30', 70),
('https://www.acona.app/metrics', '2021-09-01', 50),
('https://www.acona.app/metrics', '2021-09-02', 60),
('https://www.acona.app/metrics', '2021-09-03', 60),
('https://www.acona.app/metrics', '2021-09-04', 60),
('https://www.acona.app/metrics', '2021-09-05', 70),
('https://www.acona.app/info', '2021-09-04', 60),
('https://www.acona.app/info', '2021-09-05', 60),
('https://www.acona.app/info', '2021-09-06', 60),
('https://www.acona.app/info', '2021-09-07', 60),
('https://www.acona.app/info', '2021-09-08', 60),
('https://www.acona.app/legal', '2021-09-04', 80),
('https://www.acona.app/legal', '2021-09-05', 80),
('https://www.acona.app/legal', '2021-09-06', 80),
('https://www.acona.app/legal', '2021-09-07', 80),
('https://www.acona.app/legal', '2021-09-08', 80),
('https://www.acona.app/', '2021-09-07', 80),
('https://www.acona.app/', '2021-09-08', 80);
INSERT INTO api.metric_d_bounces(url, date, value)
VALUES
('https://www.acona.app/about', '2021-08-25', 10),
('https://www.acona.app/about', '2021-08-26', 3),
('https://www.acona.app/about', '2021-08-27', 100),
('https://www.acona.app/about', '2021-08-28', 5);
INSERT INTO internal.acona_rules(rule_id, variable, indication, condition) VALUES
('pagetitle_red', 'page_title_char_count', 'red', '{"<" : [ { "var" : "value" }, 1 ]}'),
('pagetitle_green', 'page_title_char_count', 'green', '{"<" : [ { "var" : "value" }, 1 ]}'),
('url_words_count_yellow', 'page_url_words_count', 'yellow', '{ "and" : [
  {">" : [ { "var" : "value" }, 5 ]},
  {"<=" : [ { "var" : "value" }, 7 ] }
] }'),
('url_words_count_green', 'page_url_words_count', 'green', ' {"<=" : [ { "var" : "value" }, 5 ]}'),
('url_words_count_red', 'page_url_words_count', 'red', ' {">" : [ { "var" : "value" }, 7 ]}'),
('pagetitle_size_red', 'page_title_char_count', 'red', '{">" : [ { "var" : "value" }, 60 ]}'),
('pagetitle_size_green', 'page_title_char_count', 'green', '{"<=" : [ { "var" : "value" }, 60 ]}');

INSERT INTO internal.recommendation(rule_id, langcode, title, recommendation_text, more) VALUES
('pagetitle_red', 'en', 'Pagetitle', 'This page does not have a page title. Go and create one!', 'More info about pagetitle here: https://moz.com/learn/seo/title-tag'),
('pagetitle_green', 'en', 'Pagetitle', 'This page does have a page title. Good job!', 'More info about pagetitle here: https://moz.com/learn/seo/title-tag'),
('url_words_count_yellow', 'en', 'URL size', 'Ideally your page should not have more than 5-7 words in the url.', 'After about 5 words in your URL search engine algorithms typically will just weight those words less.'),
('url_words_count_green', 'en', 'URL size', 'Ideally your page should not have more than 5-7 words in the url.', 'After about 5 words in your URL search engine algorithms typically will just weight those words less.'),
('url_words_count_red', 'en', 'URL size', 'Ideally your page should not have more than 5-7 words in the url.', 'After about 5 words in your URL search engine algorithms typically will just weight those words less.'),
('pagetitle_size_red', 'en', 'Page title size', 'Page title should be smaller than 60 characters.', 'More info about pagetitle here: https://moz.com/learn/seo/title-tag'),
('pagetitle_size_green', 'en', 'Page title size', 'Your page title is smaller than 60 characters. :)', 'More info about pagetitle here: https://moz.com/learn/seo/title-tag'),
('pagetitle_red', 'de', 'Pagetitle', 'Diese Seite hat keinen Pagetitel. Es wird empfohlen einen Pagetitel anzulegen!', 'Mehr Infos zu pagetitle hier: https://moz.com/learn/seo/title-tag'),
('pagetitle_green', 'de', 'Pagetitle', 'Diese Seite hat einen Pagetitel. Gute Arbeit!', 'Mehr Infos zu pagetitle hier: https://moz.com/learn/seo/title-tag'),
('url_words_count_yellow', 'de', 'Länge URL', 'Idealerweise besteht die URL aus maximal 5-7 Wörtern.', 'Typischerweise werten Suchmaschinen vor allem die ersten Wörter in der URL.'),
('url_words_count_green', 'de', 'Länge URL', 'Die URL dieser Seite besteht aus maximal 5-7 Wörtern. :)', 'Typischerweise werten Suchmaschinen vor allem die ersten Wörter in der URL.'),
('url_words_count_red', 'de', 'Länge URL', 'Idealerweise besteht die URL aus maximal 5-7 Wörtern.', 'Typischerweise werten Suchmaschinen vor allem die ersten Wörter in der URL.'),
('pagetitle_size_red', 'de', 'Länge Pagetitle', 'Der Pagetitle sollte nicht länger sein als 60 Zeichen.', 'Mehr Infos zu pagetitle hier: https://moz.com/learn/seo/title-tag'),
('pagetitle_size_green', 'de', 'Länge Pagetitle', 'Der Pagetitle ist nicht länger als 60 Zeichen. :)', 'Mehr Infos zu pagetitle hier: https://moz.com/learn/seo/title-tag');


INSERT INTO api.metric_rules_eval(url, date, result, rule_id)
VALUES
('https://www.acona.app/about', '2021-09-05', TRUE, 'pagetitle_red'),
('https://www.acona.app/about', '2021-09-07', FALSE, 'pagetitle_red'),
('https://www.acona.app/about', '2021-09-08', FALSE, 'pagetitle_red'),
('https://www.acona.app/about', '2021-09-05', TRUE, 'pagetitle_green'),
('https://www.acona.app/about', '2021-09-06', TRUE, 'pagetitle_green'),
('https://www.acona.app/about', '2021-09-07', FALSE, 'pagetitle_green'),
('https://www.acona.app/about', '2021-09-08', FALSE, 'pagetitle_green'),
('https://www.acona.app/about', '2021-09-06', TRUE, 'pagetitle_size_red'),
('https://www.acona.app/about', '2021-09-07', TRUE, 'pagetitle_size_red'),
('https://www.acona.app/about', '2021-09-06', TRUE, 'url_words_count_yellow'),
('https://www.acona.app/metrics', '2021-09-06', TRUE, 'url_words_count_yellow'),
('https://www.acona.app/metrics', '2021-09-06', TRUE, 'pagetitle_size_red'),
('https://www.acona.app/metrics', '2021-09-07', TRUE, 'pagetitle_size_red'),
('https://www.acona.app/metrics', '2021-09-06', TRUE, 'pagetitle_green'),
('https://www.acona.app/metrics', '2021-09-07', FALSE, 'pagetitle_green'),
('https://www.acona.app/metrics', '2021-09-08', FALSE, 'pagetitle_green'),
('https://www.acona.app/metrics', '2021-09-06', TRUE, 'pagetitle_red'),
('https://www.acona.app/metrics', '2021-09-07', FALSE, 'pagetitle_red'),
('https://www.acona.app/metrics', '2021-09-08', FALSE, 'pagetitle_red');
INSERT INTO internal.var_calc_dates(variable, date, url)
VALUES
('metric_rules_eval', '2021-09-06', 'https://www.acona.app/about'),
('metric_rules_eval', '2021-09-06', 'https://www.acona.app/metrics');