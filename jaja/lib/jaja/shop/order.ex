defmodule Jaja.Shop.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :batch_reference, :string
    field :reference, :string
    field :name, :string
    field :amount, :integer
    field :datetime, :naive_datetime
    field :payment_received, :boolean, default: false
    field :delivered, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:batch_reference, :name, :amount, :datetime])
    |> validate_required([:batch_reference, :name, :amount])
    |> put_datetime()
    |> put_reference()
    |> unique_constraint(:reference)
  end

  # Server-minted and never cast from params: it is the only key to the
  # customer's confirmation page.
  defp put_reference(changeset) do
    case get_field(changeset, :reference) do
      nil -> put_change(changeset, :reference, Nanoid.generate())
      _ -> changeset
    end
  end

  defp put_datetime(changeset) do
    case get_field(changeset, :datetime) do
      nil -> put_change(changeset, :datetime, NaiveDateTime.local_now())
      _ -> changeset
    end
  end

  @doc false
  def admin_changeset(order, attrs) do
    order
    |> cast(attrs, [:payment_received, :delivered])
  end
end
