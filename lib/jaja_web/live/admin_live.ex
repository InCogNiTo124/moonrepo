defmodule JajaWeb.AdminLive do
  use JajaWeb, :live_view

  alias Jaja.Shop
  alias Jaja.Shop.Batch

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to updates if needed later
    end

    {active, inactive} = Enum.split_with(Shop.list_batches(), & &1.active)
    products = Shop.list_products()
    last_price = Shop.get_last_price_for_type("eggs")
    changeset = Shop.change_batch(%Batch{type: "eggs", price: last_price})

    {:ok,
     socket
     |> stream(:active_batches, active)
     |> stream(:inactive_batches, inactive)
     |> assign(:products, products)
     |> assign(:open_batches, MapSet.new())
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"batch" => batch_params}, socket) do
    current_type = socket.assigns.form.params["type"]
    new_type = batch_params["type"]

    batch_params =
      if new_type != current_type do
        last_price = Shop.get_last_price_for_type(new_type)
        current_price = batch_params["price"]
        prev_type_last_price = current_type && Shop.get_last_price_for_type(current_type)

        if last_price &&
             (current_price == "" || is_nil(current_price) ||
                (prev_type_last_price && current_price == to_string(prev_type_last_price))) do
          Map.put(batch_params, "price", last_price)
        else
          batch_params
        end
      else
        batch_params
      end

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
        last_price = Shop.get_last_price_for_type("eggs")

        {:noreply,
         socket
         |> stream_insert(:active_batches, batch, at: 0)
         |> put_flash(:info, "Batch created successfully")
         |> assign(:form, to_form(Shop.change_batch(%Batch{type: "eggs", price: last_price})))}

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

        {:noreply, put_batch_in_stream(socket, batch_with_orders)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update status.")}
    end
  end

  def handle_event("toggle_active", %{"id" => id}, socket) do
    batch = Shop.get_batch!(id)

    result =
      if batch.active, do: Shop.deactivate_batch(batch), else: Shop.activate_batch(batch)

    case result do
      {:ok, updated} ->
        {:noreply,
         socket
         |> move_batch_between_streams(Shop.get_batch_with_orders!(updated.id))
         |> put_flash(
           :info,
           "Batch #{if updated.active, do: "activated", else: "deactivated"}."
         )}

      {:error, :sold_out} ->
        {:noreply, put_flash(socket, :error, "Batch is sold out and cannot be activated again.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to change batch status.")}
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

  # Flattens changeset errors into {label, message} pairs, so errors on fields that
  # have no input in the form (unique_reference, datetime, id) are still visible.
  defp form_errors(form) do
    case form.source.errors do
      [] ->
        [{"Error:", "the batch could not be saved, please try again."}]

      errors ->
        for {field, error} <- errors do
          {"#{Phoenix.Naming.humanize(field)}:", translate_error(error)}
        end
    end
  end

  # Re-renders a batch in whichever list it belongs to now.
  defp put_batch_in_stream(socket, batch) do
    stream_insert(socket, stream_for(batch), batch)
  end

  # Toggling active moves a batch between the two lists, so it has to be removed
  # from the old stream — stream_insert alone would leave a stale copy behind.
  defp move_batch_between_streams(socket, batch) do
    {from, to} =
      if batch.active,
        do: {:inactive_batches, :active_batches},
        else: {:active_batches, :inactive_batches}

    socket
    |> stream_delete(from, batch)
    |> stream_insert(to, batch, at: 0)
  end

  defp stream_for(%{active: true}), do: :active_batches
  defp stream_for(%{active: false}), do: :inactive_batches

  # Units left on a batch, from the preloaded orders, so rendering the list costs no extra queries.
  defp available(batch) do
    ordered = batch.orders |> Enum.map(& &1.amount) |> Enum.sum()
    batch.amount - ordered
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl p-4">
      <h1 class="w-full text-center text-2xl font-bold mb-6 text-base-content">Admin Dashboard</h1>
      <%!-- items-start keeps the columns auto-height, which is what lets the left one stick --%>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
        <div class="bg-base-100 p-6 rounded-lg shadow text-base-content lg:sticky lg:top-4">
          <h2 class="text-xl font-semibold mb-4">Create New Batch</h2>
          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
            <div
              :if={@form.source.action == :insert}
              id="batch-form-errors"
              role="alert"
              class="alert alert-error items-start"
            >
              <.icon name="hero-exclamation-circle" class="size-5 shrink-0" />
              <div>
                <p class="font-semibold">Batch could not be created.</p>
                <ul class="list-disc list-inside text-sm">
                  <li :for={{label, message} <- form_errors(@form)}>{label} {message}</li>
                </ul>
              </div>
            </div>

            <.input
              field={@form[:type]}
              type="select"
              label="Product Type"
              options={Enum.map(@products, &{translate_type(&1.name), &1.slug})}
              required
            />
            <%!-- text inputs, not number: <input type="number"> blanks out invalid content in the
               browser, so the server would only ever see "" and report it as blank. --%>
            <.input
              field={@form[:amount]}
              type="text"
              inputmode="numeric"
              label="Amount"
              placeholder="20"
              required
            />
            <.input
              field={@form[:price]}
              type="text"
              inputmode="decimal"
              label="Price (EUR)"
              placeholder="3.50"
              required
            />

            <.button
              type="submit"
              class={"btn w-full #{if @form.source.valid?, do: "btn-primary", else: "btn-neutral"}"}
              disabled={!@form.source.valid?}
            >
              Create Batch
            </.button>
          </.form>
        </div>

        <div class="lg:col-span-2 space-y-8">
          <div class="bg-base-100 p-6 rounded-lg shadow text-base-content">
            <h2 class="text-xl font-semibold mb-4">Active Batches</h2>
            <div class="space-y-4" id="active-batches" phx-update="stream">
              <p id="no-active-batches" class="hidden only:block text-sm italic opacity-70">
                No active batches.
              </p>
              <.batch_card
                :for={{dom_id, batch} <- @streams.active_batches}
                id={dom_id}
                batch={batch}
                open_batches={@open_batches}
              />
            </div>
          </div>

          <div class="bg-base-100 p-6 rounded-lg shadow text-base-content">
            <h2 class="text-xl font-semibold mb-4">Inactive Batches</h2>
            <div class="space-y-4" id="inactive-batches" phx-update="stream">
              <p id="no-inactive-batches" class="hidden only:block text-sm italic opacity-70">
                No inactive batches.
              </p>
              <.batch_card
                :for={{dom_id, batch} <- @streams.inactive_batches}
                id={dom_id}
                batch={batch}
                open_batches={@open_batches}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :batch, Jaja.Shop.Batch, required: true
  attr :open_batches, :any, required: true, doc: "MapSet of batch ids whose order list is open"

  defp batch_card(assigns) do
    ~H"""
    <div id={@id} class="border rounded-lg p-4 bg-base-200">
      <div class="flex justify-between items-center gap-4 mb-2">
        <div class="flex items-center gap-2">
          <span class="font-bold text-lg">{translate_type(@batch.type)}</span>
          <span class={"badge #{if @batch.active, do: "badge-success", else: "badge-error"}"}>
            {if @batch.active, do: "Active", else: "Inactive"}
          </span>
        </div>
        <a href={~p"/order/#{@batch.unique_reference}"} target="_blank" class="btn btn-sm btn-info">
          View
        </a>
      </div>

      <div class="flex justify-between items-center gap-4 mb-2">
        <span class="badge badge-outline">{format_price(@batch.price)}</span>
        <span class="text-sm">{format_datetime(@batch.datetime)}</span>
      </div>

      <div class="flex justify-between items-center gap-4 mb-2">
        <div class="flex items-center gap-2">
          <span class="badge badge-neutral">{@batch.amount} total qty</span>
          <span class="badge badge-ghost">{available(@batch)} available</span>
        </div>
        <.button
          type="button"
          phx-click="toggle_active"
          phx-value-id={@batch.id}
          disabled={not @batch.active and available(@batch) <= 0}
          class={"btn btn-sm #{if @batch.active, do: "btn-outline btn-error", else: "btn-outline btn-success"}"}
          title={
            if not @batch.active and available(@batch) <= 0,
              do: "Sold out — cannot be activated again",
              else: nil
          }
        >
          {if @batch.active, do: "Deactivate", else: "Activate"}
        </.button>
      </div>

      <details
        id={"batch-details-#{@batch.id}"}
        class="bg-base-200 rounded p-2 border"
        open={MapSet.member?(@open_batches, @batch.id)}
      >
        <summary
          class="cursor-pointer font-semibold select-none"
          phx-click="toggle_details"
          phx-value-id={@batch.id}
        >
          Orders ({length(@batch.orders)})
        </summary>
        <%= if is_nil(@batch.orders) or @batch.orders == [] do %>
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
                <%= for order <- @batch.orders do %>
                  <tr id={"order-row-#{order.id}"}>
                    <td>{order.name}</td>
                    <td>{order.amount}</td>
                    <td>{format_datetime(order.datetime)}</td>
                    <td>
                      <input
                        type="checkbox"
                        class="checkbox checkbox-sm checkbox-error"
                        checked={order.payment_received}
                        phx-click="toggle_status"
                        phx-value-id={order.id}
                        phx-value-field="payment_received"
                      />
                    </td>
                    <td>
                      <input
                        type="checkbox"
                        class="checkbox checkbox-sm checkbox-error"
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
    """
  end
end
