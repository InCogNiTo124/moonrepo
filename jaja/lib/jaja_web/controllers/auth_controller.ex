defmodule JajaWeb.AuthController do
  use JajaWeb, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    email = auth.info.email

    if email == System.get_env("ADMIN_EMAIL") do
      conn
      |> put_session(:admin_user, email)
      |> configure_session(renew: true)
      |> put_flash(:info, "Welcome back, Admin!")
      |> redirect(to: ~p"/admin")
    else
      conn
      |> put_flash(:error, "Unauthorized access.")
      |> redirect(to: ~p"/")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: ~p"/")
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out.")
    |> redirect(to: ~p"/")
  end
end
