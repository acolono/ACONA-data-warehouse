# ACONA Data Warehouse

Provides persistent storage for ACONA Data, using a timescale database.

It uses postgREST to turn the database into a RESTful API.

https://www.timescale.com/

https://postgrest.org/

## HOW TO USE
Rename .env_template to .env and set your passwords and secrets there.
See https://postgrest.org/en/v8.0/tutorials/tut1.html about authentication
process and token generation.

Then run
`docker-compose up -d`.

Delete the pgdata folder and run
`docker-compose up --build --force-recreate`
when you want to start from scratch again.

## CONFIGURATION
Postgres user "acona_admin": Will be created by docker for administration purpose.

Postgres user "app_user": For authenticated queries, e.g. writing data via API.

Postgres user "api_anon": For anonymous usage, e.g. for public API queries.

Postgres user "authenticator": A user with limited permissions. It's a chameleon whose job is to “become” other users to service authenticated HTTP requests.

See more about Postgrest authentication here: https://postgrest.org/en/v4.3/auth.html

Postgres schema for API usage: api

## LOGIN IN POSTGRES/TIMESCALE

```
docker ps
docker exec -it CONTAINER bash (timescale/timescaledb:latest-pg13 container)
psql -U acona_admin -d acona_data_warehouse -h localhost
```

Now you are logged in psql.

## Schema Cache Reloading

Sometimes needed when you create new functions.
```
docker kill -s SIGUSR1 CONTAINER (postgrest/postgrest container)
```
## GET YOUR JWT TOKEN
For using the api you need to have your personal JWT Token with the following payload:
```
{
  "role": "app_user",
  "email": "mail@mail.com"
}
```
Of course you can change the internal.users table accordingly. 
More: https://postgrest.org/en/v4.3/auth.html

## QUERY DATA VIA API 

Locally you can run a curl command like this for all api tables:

```
export TOKEN="<paste your token here>"
curl -G "localhost:3000/rpc/acona_urls_success" -d domain=https://www.acona.app -H "Authorization: Bearer $TOKEN";
```

## WRITE DATA VIA API 

```
export TOKEN="<paste your token here>"
curl http://localhost:3000/metric_d_bounces -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"url": "https://acona.app", "value": "10", "date": "2021-08-19"}'
 ```

More documentation about table structure and API usage is coming soon.
