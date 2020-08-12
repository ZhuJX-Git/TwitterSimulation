use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :proj5, Proj5Web.Endpoint,
  secret_key_base: "1sYq7521DwaQsYgKdupH+bM79MjQogt7N19WKpaKmqlmEotx6JEX1a+JCQR5zDrM"

# Configure your database
config :proj5, Proj5.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "proj5_prod",
  pool_size: 15
