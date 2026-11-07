defmodule JajaWeb.HomeLive do
  use JajaWeb, :live_view

  alias Jaja.Shop

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Optional: Subscribe to updates to refresh the list automatically
      # Phoenix.PubSub.subscribe(Jaja.PubSub, "batches")
    end

    batches = Shop.list_active_batches()
    # Ordered oldest -> newest left-to-right so starting on the newest (rightmost)
    # slide lets the left `<` button step backward in time through older videos.
    videos = Shop.list_batches_with_videos() |> Enum.reverse()
    latest_index = max(length(videos) - 1, 0)

    {:ok,
     socket
     |> assign(:batches, batches)
     |> assign(:videos, videos)
     |> assign(:video_index, latest_index)}
  end

  def handle_event("older_video", _params, socket) do
    {:noreply, assign(socket, :video_index, max(socket.assigns.video_index - 1, 0))}
  end

  def handle_event("newer_video", _params, socket) do
    max_idx = max(length(socket.assigns.videos) - 1, 0)
    {:noreply, assign(socket, :video_index, min(socket.assigns.video_index + 1, max_idx))}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl p-4 text-base-content">
      <div class="text-center mb-8 pt-10">
        <h1 class="text-5xl font-bold">Smetkova jaja</h1>
        <p class="py-6 max-w-md mx-auto">
          Svježa domaća jaja direktno s farme. Pogledajte aktivne ponude ispod.
        </p>
      </div>

      <section :if={@videos != []} id="video-carousel" class="mb-12">
        <div class="relative max-w-2xl mx-auto flex items-center gap-3">
          <button
            :if={length(@videos) > 1}
            id="older-video-btn"
            type="button"
            phx-click={JS.dispatch("phx:pause-videos") |> JS.push("older_video")}
            disabled={@video_index == 0}
            aria-label="Stariji video"
            title="Stariji video"
            class="btn btn-circle btn-primary shadow-lg shrink-0 disabled:opacity-25 transition-opacity"
          >
            <.icon name="hero-chevron-left" class="size-6" />
          </button>

          <div class="card bg-base-300 shadow-xl overflow-hidden w-full">
            <div
              id="video-carousel-track"
              class="flex transition-transform duration-500 ease-in-out"
              style={"transform: translateX(-#{@video_index * 100}%)"}
            >
              <div
                :for={{video_batch, idx} <- Enum.with_index(@videos)}
                id={"video-slide-#{video_batch.id}"}
                class="w-full shrink-0 flex flex-col justify-between"
              >
                <video
                  src={Jaja.Storage.public_url(video_batch.video_key)}
                  class="w-full max-h-[32rem] bg-black"
                  controls
                  playsinline
                  preload={if abs(idx - @video_index) <= 1, do: "metadata", else: "none"}
                ></video>
                <div class="card-body py-3 px-4 flex-row items-center justify-between">
                  <span
                    :if={idx == length(@videos) - 1}
                    class="badge badge-primary"
                  >
                    Najnoviji
                  </span>
                  <span
                    :if={idx < length(@videos) - 1}
                    class="badge badge-ghost"
                  >
                    Arhiva
                  </span>
                  <span class="text-sm text-base-content/60">
                    {format_date(video_batch.datetime)}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <button
            :if={length(@videos) > 1}
            id="newer-video-btn"
            type="button"
            phx-click={JS.dispatch("phx:pause-videos") |> JS.push("newer_video")}
            disabled={@video_index >= length(@videos) - 1}
            aria-label="Noviji video"
            title="Noviji video"
            class="btn btn-circle btn-primary shadow-lg shrink-0 disabled:opacity-25 transition-opacity"
          >
            <.icon name="hero-chevron-right" class="size-6" />
          </button>
        </div>
      </section>

      <h2 class="text-3xl font-bold mb-6 text-center">Dostupno odmah</h2>

      <%= if @batches == [] do %>
        <div class="text-center py-10 bg-base-100 rounded-lg shadow">
          <p class="text-xl text-base-content/60">
            Trenutno nema aktivnih ponuda. Navratite kasnije!
          </p>
        </div>
      <% else %>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= for batch <- @batches do %>
            <div class="card bg-base-300 shadow-xl hover:shadow-2xl transition-shadow">
              <div class="card-body">
                <h2 class="card-title">
                  {translate_type(batch.type)}
                  <div class="badge badge-secondary">NOVO</div>
                </h2>
                <p class="text-2xl font-bold text-primary">
                  {format_price(batch.price)}
                  <span class="text-sm font-normal text-base-content/60">po kutiji</span>
                </p>
                <div class="card-actions justify-end mt-4">
                  <.link
                    navigate={~p"/order/#{batch.unique_reference}"}
                    class="btn btn-primary w-full"
                  >
                    Rezerviraj
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
