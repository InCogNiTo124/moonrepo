defmodule JajaWeb.DevLoginHTML do
  @moduledoc """
  The development login page. Rendered through the usual pipeline so it picks up
  the app's styling rather than carrying its own.
  """
  use JajaWeb, :html

  def new(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <Layouts.brand_header />
    <div class="mx-auto max-w-sm p-6 mt-16 text-base-content">
      <h1 class="text-3xl font-bold mb-2 text-center">Development login</h1>
      <p class="text-sm text-base-content/60 mb-6 text-center">
        Signs in as an admin without Google. This page exists only in development.
      </p>

      <div class="bg-base-200 p-6 rounded-lg shadow">
        <.form :let={f} for={@form} action={~p"/dev/login"} method="post" class="space-y-4">
          <.input field={f[:username]} type="text" label="Username" placeholder="admin" autofocus />
          <.input field={f[:password]} type="password" label="Password" placeholder="admin" />

          <.button type="submit" class="btn w-full btn-primary">Log in</.button>
        </.form>
      </div>
    </div>
    """
  end
end
