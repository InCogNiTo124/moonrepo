defmodule JajaWeb.PageController do
  use JajaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
