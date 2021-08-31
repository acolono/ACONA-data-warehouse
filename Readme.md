ACONA Data Warehouse

Provides persistent storage for ACONA Data, using a timescale database.

HOW TO USE
docker-compose up -d

CONFIGURATION
Postgres user “app_user”: To connect to the database
Postgres user “api_user”: For anonymous usage, e.g. to use the API.

Postgres schema: Public

LOGIN IN POSTGRES/TIMESCALE

$ docker ps
$ docker exec -it 8becccecec01 bash (timescale/timescaledb:latest-pg13 container)
$ psql -U app_user -d acona_data_warehouse -h localhost

Now you are logged in psql.


QUERY DATA VIA API 

Locally you can run the following curl commands: 
$ curl 0.0.0.0:3000/metric_d_bounces
$ curl IP:3000/metric_d_bounces?select=*&url=URL&order=time.desc&limit=30 -vv

More documentation about API usage is coming soon.
