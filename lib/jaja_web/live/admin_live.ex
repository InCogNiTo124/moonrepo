defmodule JajaWeb.AdminLive do
  use JajaWeb, :live_view

  alias Jaja.Shop
  alias Jaja.Shop.Batch

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to updates if needed later
    end

    batches = Shop.list_batches()
    products = Shop.list_products()
    changeset = Shop.change_batch(%Batch{type: "eggs"})

    {:ok,
     socket
     |> stream(:batches, batches)
     |> assign(:products, products)
     |> assign(:open_batches, MapSet.new())
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"batch" => batch_params}, socket) do
    changeset =
      %Batch{}
      |> Shop.change_batch(batch_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"batch" => batch_params}, socket) do
    case Shop.create_batch(batch_params) do
      {:ok, batch} ->
        batch = Map.put(batch, :orders, [])

        {:noreply,
         socket
         |> stream_insert(:batches, batch, at: 0)
         |> put_flash(:info, "Batch created successfully")
         |> assign(:form, to_form(Shop.change_batch(%Batch{type: "eggs"})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("toggle_status", %{"id" => id, "field" => field}, socket) do
    order = Shop.get_order!(id)
    current_val = Map.get(order, String.to_existing_atom(field))

    case Shop.update_order_admin(order, %{field => !current_val}) do
      {:ok, updated_order} ->
        # Fetch the full preloaded batch rather than walking whole list in memory
        batch = Shop.get_batch_by_reference!(updated_order.batch_reference)
        batch_with_orders = Shop.get_batch_with_orders!(batch.id)

        {:noreply, stream_insert(socket, :batches, batch_with_orders)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update status.")}
    end
  end

  def handle_event("toggle_details", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    open_batches = socket.assigns.open_batches

    new_open_batches =
      if MapSet.member?(open_batches, id) do
        MapSet.delete(open_batches, id)
      else
        MapSet.put(open_batches, id)
      end

    {:noreply, assign(socket, open_batches: new_open_batches)}
  end

  defp translate_type(type) do
    case String.downcase(type) do
      "eggs" -> "Jaja"
      "turkey" -> "Puretina"
      other -> other
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl p-4">
      <h1 class="text-2xl font-bold mb-4 text-base-content">Admin Dashboard</h1>

      <div class="bg-base-100 p-6 rounded-lg shadow mb-8 text-base-content">
        <h2 class="text-xl font-semibold mb-4">Create New Batch</h2>
        <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
          <.input
            field={@form[:type]}
            type="select"
            label="Product Type"
            options={Enum.map(@products, &{translate_type(&1.name), &1.slug})}
            required
          />
          <.input field={@form[:amount]} type="number" label="Amount" min="1" required />

          <.button
            type="submit"
            class={"btn w-full #{if @form.source.valid?, do: "btn-primary", else: "btn-neutral"}"}
            disabled={!@form.source.valid?}
          >
            Create Batch
          </.button>
        </.form>
      </div>

      <div class="bg-base-100 p-6 rounded-lg shadow text-base-content">
        <h2 class="text-xl font-semibold mb-4">Active Batches</h2>
        <div class="space-y-4" id="batches" phx-update="stream">
          <div
            :for={{dom_id, batch} <- @streams.batches}
            id={dom_id}
            class="border rounded-lg p-4 bg-base-200"
          >
            <div class="flex justify-between items-center mb-2">
              <div>
                <span class="font-bold text-lg">{translate_type(batch.type)}</span>
                <span class="ml-2 badge badge-neutral">{batch.amount} total qty</span>
              </div>
              <div class="text-sm">
                <span>{batch.datetime}</span>
                <a
                  href={~p"/order/#{batch.unique_reference}"}
                  target="_blank"
                  class="text-blue-600 hover:underline ml-4"
                >
                  Link
                </a>
              </div>
            </div>

            <details
              id={"batch-details-#{batch.id}"}
              class="bg-base-100 rounded p-2 border"
              open={MapSet.member?(@open_batches, batch.id)}
            >
              <summary
                class="cursor-pointer font-semibold select-none"
                phx-click="toggle_details"
                phx-value-id={batch.id}
              >
                Orders ({length(batch.orders)})
              </summary>
              <%= if is_nil(batch.orders) or batch.orders == [] do %>
                <p class="mt-2 text-sm italic opacity-70">No orders yet.</p>
              <% else %>
                <div class="overflow-x-auto mt-2">
                  <table class="table table-sm w-full">
                    <thead>
                      <tr>
                        <th>Nick</th>
                        <th>Amount</th>
                        <th>Time</th>
                        <th>Paid</th>
                        <th>Delivered</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for order <- batch.orders do %>
                        <tr id={"order-row-#{order.id}"}>
                          <td>{order.name}</td>
                          <td>{order.amount}</td>
                          <td>{order.datetime}</td>
                          <td>
                            <input
                              type="checkbox"
                              class="checkbox checkbox-sm"
                              checked={order.payment_received}
                              phx-click="toggle_status"
                              phx-value-id={order.id}
                              phx-value-field="payment_received"
                            />
                          </td>
                          <td>
                            <input
                              type="checkbox"
                              class="checkbox checkbox-sm"
                              checked={order.delivered}
                              disabled={!order.payment_received}
                              phx-click="toggle_status"
                              phx-value-id={order.id}
                              phx-value-field="delivered"
                            />
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            </details>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
