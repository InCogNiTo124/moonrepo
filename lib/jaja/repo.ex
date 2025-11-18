defmodule Jaja.Repo do
  use Ecto.Repo,
    otp_app: :jaja,
    adapter: Ecto.Adapters.SQLite3
end
