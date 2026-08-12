# Jaja

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Local Development & Database Access

By default, running `mix phx.server` will connect to your local PostgreSQL database (which you can start with `docker compose up db -d`).

### Connecting Local Server to Remote (Exoscale) Database
If you want to run the server locally on your laptop (with live-reloading!) but connected to the **remote Exoscale database**, run this exact command:

```bash
DEV_DATABASE_HOST=postgres4a-exoscale-3f1ca88f-2ed3-4886-8817-f8ce726f9357.j.aivencloud.com \
DEV_DATABASE_PORT=21699 \
DEV_DATABASE_USER=your_db_username \
DEV_DATABASE_PASSWORD=your_db_password \
DEV_DATABASE_NAME=jaja \
DEV_DATABASE_SSL=true \
mix phx.server
```

*(You might want to save that as an alias in your shell or a script file like `run_remote.sh` so you don't have to type it out every time!)*

### Running the Entire App via Docker (Local Database)
To sync your production data to your machine and boot up a pure local instance (which doesn't affect production data):

1. Pull your production data into a local container volume:
   ```bash
   DATABASE_USER=your_db_username DATABASE_PASSWORD=your_db_password ./scripts/pull_prod_data.sh
   ```

2. Start the local Database and the local Application together:
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.local.yml up --build
   ```

Then visit [`localhost:4000`](http://localhost:4000).

### Running the Entire App via Docker (Connected to Production Database)
If you want to run the local Docker Application natively connected directly to the **remote Exoscale database** (caution, this modifies live data!):

```bash
DATABASE_USER=your_db_username DATABASE_PASSWORD=your_db_password docker compose -f docker-compose.yml -f docker-compose.prod-db.yml up --build
```
Then visit [`localhost:4000`](http://localhost:4000).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
