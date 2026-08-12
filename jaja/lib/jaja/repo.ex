defmodule Jaja.Repo do
  use Ecto.Repo,
    otp_app: :jaja,
    adapter: Ecto.Adapters.Postgres
end
