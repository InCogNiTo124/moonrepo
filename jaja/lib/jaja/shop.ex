defmodule Jaja.Shop do
  @moduledoc """
  The Shop context.
  """

  import Ecto.Query, warn: false
  alias Jaja.Repo

  alias Jaja.Shop.Batch
  alias Jaja.Shop.Order

  @doc """
  Returns the list of batches.

  ## Examples

      iex> list_batches()
      [%Batch{}, ...]

  """
  def list_batches do
    orders_query = from(o in Order, order_by: [asc: o.inserted_at, asc: o.id])

    Repo.all(Batch)
    |> Repo.preload(orders: orders_query)
  end

  @doc """
  Gets a single batch.

  Raises `Ecto.NoResultsError` if the Batch does not exist.

  ## Examples

      iex> get_batch!(123)
      %Batch{}

      iex> get_batch!(456)
      ** (Ecto.NoResultsError)

  """
  def get_batch!(id), do: Repo.get!(Batch, id)

  @doc """
  Gets a single batch and preloads its orders.
  """
  def get_batch_with_orders!(id) do
    orders_query = from(o in Order, order_by: [asc: o.inserted_at, asc: o.id])

    Repo.get!(Batch, id)
    |> Repo.preload(orders: orders_query)
  end

  @doc """
  Creates a batch.

  ## Examples

      iex> create_batch(%{field: value})
      {:ok, %Batch{}}

      iex> create_batch(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_batch(attrs) do
    %Batch{}
    |> Batch.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a batch.

  ## Examples

      iex> update_batch(batch, %{field: new_value})
      {:ok, %Batch{}}

      iex> update_batch(batch, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_batch(%Batch{} = batch, attrs) do
    batch
    |> Batch.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a batch, provided nobody has ordered from it.

  ## Examples

      iex> delete_batch(batch)
      {:ok, %Batch{}}

      iex> delete_batch(batch_with_orders)
      {:error, :has_orders}

  """
  def delete_batch(%Batch{} = batch) do
    if has_orders?(batch) do
      {:error, :has_orders}
    else
      Repo.delete(batch)
    end
  end

  @doc """
  Whether anyone has ordered from this batch.

  Guards deletion: the orders foreign key is `on_delete: :delete_all`, so without
  this check removing a batch would take its orders down with it silently.
  """
  def has_orders?(%Batch{} = batch) do
    Repo.exists?(from o in Order, where: o.batch_reference == ^batch.unique_reference)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking batch changes.

  ## Examples

      iex> change_batch(batch)
      %Ecto.Changeset{data: %Batch{}}

  """
  def change_batch(%Batch{} = batch, attrs \\ %{}) do
    Batch.changeset(batch, attrs)
  end

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(Order)
  end

  def list_orders_for_batch(batch_reference) do
    Repo.all(
      from o in Order,
        where: o.batch_reference == ^batch_reference,
        order_by: [asc: o.inserted_at, asc: o.id]
    )
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(id), do: Repo.get!(Order, id)

  @doc """
  Gets a single order by the public reference handed to the customer.

  Raises `Ecto.NoResultsError` if no order carries it.
  """
  def get_order_by_reference!(reference) do
    Repo.get_by!(Order, reference: reference)
  end

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs) do
    with {:ok, order} <- %Order{} |> Order.changeset(attrs) |> Repo.insert() do
      deactivate_if_sold_out(order.batch_reference)
      {:ok, order}
    end
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates an order's status fields (restricted admin).
  """
  def update_order_admin(%Order{} = order, attrs) do
    order
    |> Order.admin_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def get_last_price_for_type(type) do
    from(b in Batch,
      where: b.type == ^type,
      order_by: [desc: b.inserted_at],
      limit: 1,
      select: b.price
    )
    |> Repo.one()
  end

  def get_batch_by_reference!(reference) do
    Repo.get_by!(Batch, unique_reference: reference)
  end

  @doc """
  Units still available on a batch: its amount minus everything ordered from it.

  Can go negative only if orders were created outside the ordering flow.
  """
  def available_count(%Batch{} = batch) do
    batch.amount - count_orders_for_batch(batch.unique_reference)
  end

  @doc """
  Marks a batch active.

  Refuses when nothing is left to sell, so a batch that was deactivated by
  selling out cannot be put back on the shop.
  """
  def activate_batch(%Batch{} = batch) do
    if available_count(batch) > 0 do
      batch
      |> Batch.activation_changeset(true)
      |> Repo.update()
    else
      {:error, :sold_out}
    end
  end

  @doc """
  Marks a batch inactive. Always allowed.
  """
  def deactivate_batch(%Batch{} = batch) do
    batch
    |> Batch.activation_changeset(false)
    |> Repo.update()
  end

  # Deactivates a batch once its last unit is ordered.
  defp deactivate_if_sold_out(batch_reference) do
    case Repo.get_by(Batch, unique_reference: batch_reference) do
      %Batch{active: true} = batch ->
        if available_count(batch) <= 0, do: deactivate_batch(batch)

      _ ->
        :ok
    end
  end

  def count_orders_for_batch(batch_reference) do
    from(o in Order, where: o.batch_reference == ^batch_reference)
    |> Repo.aggregate(:sum, :amount)
    |> case do
      nil -> 0
      count -> count
    end
  end

  alias Jaja.Shop.Product

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  def list_active_batches do
    from(b in Batch,
      left_join: o in assoc(b, :orders),
      where: b.active,
      group_by: b.id,
      having: b.amount > coalesce(sum(o.amount), 0),
      select: b
    )
    |> Repo.all()
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end
end
