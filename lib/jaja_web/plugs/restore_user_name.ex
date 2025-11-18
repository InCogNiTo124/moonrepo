defmodule JajaWeb.Plugs.RestoreUserName do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn)
    case conn.cookies["user_name"] do
      nil -> conn
      name -> put_session(conn, "user_name", name)
    end
  end
end
