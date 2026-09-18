defmodule JajaWeb.DevLoginController do
  @moduledoc """
  Dev-only admin login (admin/admin), bypassing Google OAuth.

  Only routed when `:dev_routes` is enabled (see the router), so it is
  compiled out of production builds entirely.
  """
  use JajaWeb, :controller

  def new(conn, _params) do
    form = Phoenix.Component.to_form(%{}, as: :dev_login)

    render(conn, :new, form: form, page_title: "Development login")
  end

  def create(conn, %{"dev_login" => %{"username" => "admin", "password" => "admin"}}) do
    conn
    |> put_session(:admin_user, "admin@dev.local")
    |> configure_session(renew: true)
    |> put_flash(:info, "Logged in as dev admin.")
    |> redirect(to: ~p"/admin")
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Invalid credentials.")
    |> redirect(to: "/dev/login")
  end
end
