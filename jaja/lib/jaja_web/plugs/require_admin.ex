defmodule JajaWeb.Plugs.RequireAdmin do
  import Plug.Conn
  import Phoenix.Controller

  def init(default), do: default

  def call(conn, _opts) do
    if get_session(conn, :admin_user) do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access this page.")
      |> redirect(to: "/auth/google")
      |> halt()
    end
  end
end
