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
    if socket.assigns.remaining >= String.to_integer(order_params["amount"]) do
      case Shop.create_order(order_params) do
        {:ok, _order} ->
          Phoenix.PubSub.broadcast(Jaja.PubSub, "batch:#{socket.assigns.batch.unique_reference}", {:stock_update})
          {:noreply, 
           socket 
           |> push_event("store_name", %{name: order_params["name"]})
           |> assign(:reserved, true)}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    else
      {:noreply, put_flash(socket, :error, "Not enough stock!")}
    end
  end

  def handle_info({:stock_update}, socket) do
    orders_count = Shop.count_orders_for_batch(socket.assigns.batch.unique_reference)
    remaining = socket.assigns.batch.amount - orders_count
    {:noreply, assign(socket, :remaining, remaining)}
  end

  def handle_info(%{event: "presence_diff", payload: _diff}, socket) do
    viewers = 
      Presence.list("batch:#{socket.assigns.batch.unique_reference}") 
      |> map_size()
    
    {:noreply, assign(socket, :viewers, viewers)}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md p-6 bg-base-100 rounded-lg shadow-lg mt-10 text-base-content">
      <%= if @reserved do %>
        <div class="text-center">
          <h2 class="text-2xl font-bold text-success mb-4">Reservation Confirmed!</h2>
          <p class="mb-4">You have successfully reserved your <%= @batch.type %>.</p>
          <p class="text-sm text-base-content/70">Please proceed to payment via the link below (if applicable).</p>
          <!-- Custom message/link placeholder -->
          <a href="#" class="btn btn-primary mt-4">Complete Purchase</a>
        </div>
      <% else %>
        <h1 class="text-3xl font-bold mb-2"><%= @batch.type %></h1>
        <p class="text-base-content/70 mb-6">Batch Reference: <span class="font-mono"><%= @batch.unique_reference %></span></p>

        <div class="mb-8 text-center">
          <div class="text-5xl font-bold text-primary"><%= @remaining %></div>
          <div class="text-base-content/50 uppercase tracking-wide text-sm font-semibold">Remaining Boxes</div>
          <div class="mt-2 text-sm text-base-content/60">
            <span class="inline-block w-2 h-2 bg-success rounded-full mr-1"></span>
            <%= @viewers %> people viewing
          </div>
        </div>

        <%= if @remaining > 0 do %>
          <.form for={@form} phx-change="validate" phx-submit="reserve" class="space-y-4">
            <input type="hidden" name={@form[:batch_reference].name} value={@batch.unique_reference} />
            
            <.input field={@form[:name]} type="text" label="Your Name" required placeholder="John Doe" />
            <.input field={@form[:amount]} type="number" label="Amount" min="1" max={@remaining} required />

            <.button
              type="submit"
              class={"btn w-full #{if @form.source.valid?, do: "btn-primary", else: "btn-neutral"}"}
              disabled={!@form.source.valid?}
            >
              Reserve Now
            </.button>
          </.form>
        <% else %>
          <div class="bg-error/10 text-error p-4 rounded text-center font-bold">
            Sold Out!
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
