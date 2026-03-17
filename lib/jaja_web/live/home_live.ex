defmodule JajaWeb.HomeLive do
  use JajaWeb, :live_view

  alias Jaja.Shop

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Optional: Subscribe to updates to refresh the list automatically
      # Phoenix.PubSub.subscribe(Jaja.PubSub, "batches")
    end

    batches = Shop.list_active_batches()

    {:ok, assign(socket, :batches, batches)}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl p-4 text-base-content">
      <div class="hero min-h-[40vh] bg-base-200 rounded-box mb-8">
        <div class="hero-content text-center">
          <div class="max-w-md">
            <h1 class="text-5xl font-bold">Welcome to Eggshop</h1>
            <p class="py-6">
              Fresh produce reserved directly from the source. Check out our active batches below.
            </p>
          </div>
        </div>
      </div>

      <h2 class="text-3xl font-bold mb-6 text-center">Available Now</h2>

      <%= if @batches == [] do %>
        <div class="text-center py-10 bg-base-100 rounded-lg shadow">
          <p class="text-xl text-base-content/60">No active batches right now. Check back later!</p>
        </div>
      <% else %>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= for batch <- @batches do %>
            <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow">
              <div class="card-body">
                <h2 class="card-title capitalize">
                  {batch.type}
                  <div class="badge badge-secondary">NEW</div>
                </h2>
                <p>
                  Batch Reference: <span class="font-mono text-xs">{batch.unique_reference}</span>
                </p>
                <div class="card-actions justify-end mt-4">
                  <.link
                    navigate={~p"/order/#{batch.unique_reference}"}
                    class="btn btn-primary w-full"
                  >
                    Reserve Now
                  </.link>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
