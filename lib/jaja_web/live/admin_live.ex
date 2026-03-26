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
     |> assign(:batches, batches)
     |> assign(:products, products)
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
         |> update(:batches, fn batches -> [batch | batches] end)
         |> put_flash(:info, "Batch created successfully")
         |> assign(:form, to_form(Shop.change_batch(%Batch{type: "eggs"})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
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
        <div class="space-y-4">
          <%= for batch <- @batches do %>
            <div class="border rounded-lg p-4 bg-base-200">
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

              <details class="bg-base-100 rounded p-2 border">
                <summary class="cursor-pointer font-semibold select-none">
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
                        </tr>
                      </thead>
                      <tbody>
                        <%= for order <- batch.orders do %>
                          <tr>
                            <td>{order.name}</td>
                            <td>{order.amount}</td>
                            <td>{order.datetime}</td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                <% end %>
              </details>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
