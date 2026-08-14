defmodule JajaWeb.OrderLive do
  use JajaWeb, :live_view

  alias Jaja.Shop

  alias JajaWeb.Presence

  def mount(%{"reference" => reference}, session, socket) do
    topic = "batch:#{reference}"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Jaja.PubSub, topic)
      {:ok, _} = Presence.track(self(), topic, "user_#{Nanoid.generate()}", %{})
    end

    batch = Shop.get_batch_by_reference!(reference)
    remaining = batch.amount - Shop.count_orders_for_batch(reference)

    # Pre-fill name from session (cookie)
    name = session["user_name"]
    changeset = Shop.change_order(%Jaja.Shop.Order{batch_reference: reference, name: name})

    viewers =
      if connected?(socket) do
        # Count includes self
        Presence.list(topic) |> map_size()
      else
        0
      end

    {:ok,
     socket
     |> assign(:batch, batch)
     |> assign(:remaining, remaining)
     |> assign(:viewers, viewers)
     |> assign(:reserved, false)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"order" => order_params}, socket) do
    changeset =
      %Jaja.Shop.Order{}
      |> Shop.change_order(order_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("reserve", %{"order" => order_params}, socket) do
    # Ensure we don't overbook (simple check, race condition possible but acceptable for this scope)
    if socket.assigns.batch.active and
         socket.assigns.remaining >= String.to_integer(order_params["amount"]) do
      case Shop.create_order(order_params) do
        {:ok, _order} ->
          Phoenix.PubSub.broadcast(
            Jaja.PubSub,
            "batch:#{socket.assigns.batch.unique_reference}",
            {:stock_update}
          )

          {:noreply,
           socket
           |> push_event("store_name", %{name: order_params["name"]})
           |> assign(:ordered_amount, String.to_integer(order_params["amount"]))
           |> assign(:reserved, true)}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    else
      {:noreply, put_flash(socket, :error, "Nema dovoljno zaliha!")}
    end
  end

  def handle_info({:stock_update}, socket) do
    # Reload the batch: selling out flips it to inactive, and the page has to follow.
    batch = Shop.get_batch_by_reference!(socket.assigns.batch.unique_reference)
    remaining = batch.amount - Shop.count_orders_for_batch(batch.unique_reference)

    {:noreply,
     socket
     |> assign(:batch, batch)
     |> assign(:remaining, remaining)}
  end

  def handle_info(%{event: "presence_diff", payload: _diff}, socket) do
    viewers =
      Presence.list("batch:#{socket.assigns.batch.unique_reference}")
      |> map_size()

    {:noreply, assign(socket, :viewers, viewers)}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md p-6 mt-10 text-base-content">
      <%= if @reserved do %>
        <div class="text-center">
          <h2 class="text-2xl font-bold text-success mb-4">Rezervacija potvrđena!</h2>
          <p class="mb-4">Uspješno ste rezervirali proizvod: {translate_type(@batch.type)}.</p>
          <p class="text-sm text-base-content/70">
            Molimo izvršite plaćanje putem linkova ispod.
          </p>

          <% total_eur = @ordered_amount * @batch.price %>
          <% total_cents = round(total_eur * 100) %>
          <div class="my-6 p-4 bg-base-200 rounded-lg shadow-sm border border-base-300">
            <p class="text-base font-medium opacity-80 mb-1">Iznos za uplatu:</p>
            <p class="text-3xl font-extrabold text-primary">
              {:erlang.float_to_binary(total_eur, decimals: 2)} €
            </p>
            <p class="text-sm text-base-content/60 mt-1">
              {@ordered_amount} × {format_price(@batch.price)}
            </p>
          </div>

          <div class="flex flex-col gap-3 mt-4">
            <a
              href={"https://revolut.me/smetko?currency=EUR&amount=#{total_cents}&note=Smetkova%20Jaja"}
              class="btn bg-[#A78BFA] hover:bg-[#8B5CF6] text-[#1F1B2E] border-none"
              target="_blank"
            >
              Plati putem Revoluta
            </a>
            <a
              href="https://kekspay.hr/keks?a=kekstag&tag=#marijans525"
              class="btn bg-[#00D986] hover:bg-[#00BF76] text-black border-none"
              target="_blank"
            >
              Plati putem Keks Pay-a
            </a>
          </div>
        </div>
      <% else %>
        <h1 class="text-3xl font-bold mb-2 text-center">{translate_type(@batch.type)}</h1>
        <p class="text-base-content/70 mb-6 text-center">
          <span class="text-xl font-bold text-primary">{format_price(@batch.price)}</span> po kutiji
        </p>

        <div class="mb-8 text-center">
          <div class="text-5xl font-bold text-primary">{@remaining}</div>
          <div class="text-base-content/50 uppercase tracking-wide text-sm font-semibold">
            Preostalo kutija
          </div>
          <div class="mt-2 text-sm text-base-content/60">
            <span class="inline-block w-2 h-2 bg-success rounded-full mr-1"></span>
            {@viewers} ljudi pregledava
          </div>
        </div>

        <%= if @remaining > 0 and @batch.active do %>
          <.form for={@form} phx-change="validate" phx-submit="reserve" class="space-y-4">
            <input type="hidden" name={@form[:batch_reference].name} value={@batch.unique_reference} />

            <.input
              field={@form[:name]}
              type="text"
              label="Vaše ime"
              required
              placeholder="Ivan Horvat"
            />
            <.input
              field={@form[:amount]}
              type="number"
              label="Broj paketa"
              min="1"
              max={@remaining}
              required
            />

            <.button
              type="submit"
              class={"btn w-full #{if @form.source.valid?, do: "btn-primary", else: "btn-neutral"}"}
              disabled={!@form.source.valid?}
            >
              Rezerviraj
            </.button>
          </.form>
        <% else %>
          <div class="bg-error/10 text-error p-4 rounded text-center font-bold">
            {if @remaining > 0, do: "Ponuda je zatvorena!", else: "Rasprodano!"}
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
