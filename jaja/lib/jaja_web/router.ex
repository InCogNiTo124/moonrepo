defmodule JajaWeb.Router do
  use JajaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JajaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug JajaWeb.Plugs.RestoreUserName
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", JajaWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/order/:reference", OrderLive
    live "/reservation/:reference", ReservationLive
  end

  scope "/auth", JajaWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  scope "/admin", JajaWeb do
    pipe_through [:browser, JajaWeb.Plugs.RequireAdmin]

    live "/", AdminLive
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:jaja, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: JajaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
