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
        {:noreply,
         socket
         |> update(:batches, fn batches -> [batch | batches] end)
         |> put_flash(:info, "Batch created successfully")
         |> assign(:form, to_form(Shop.change_batch(%Batch{type: "eggs"})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
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
            options={Enum.map(@products, &{&1.name, &1.slug})}
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
        <div class="overflow-x-auto">
          <table class="table w-full">
            <thead>
              <tr class="text-base-content">
                <th>Type</th>
                <th>Amount</th>
                <th>Date</th>
                <th>Link</th>
              </tr>
            </thead>
            <tbody>
              <%= for batch <- @batches do %>
                <tr>
                  <td><%= batch.type %></td>
                  <td><%= batch.amount %></td>
                  <td><%= batch.datetime %></td>
                  <td>
                    <a href={~p"/order/#{batch.unique_reference}"} target="_blank" class="text-blue-600 hover:underline">
                      <%= url(~p"/order/#{batch.unique_reference}") %>
                    </a>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
