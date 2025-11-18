defmodule Jaja.Shop.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :batch_reference, :string
    field :name, :string
    field :amount, :integer
    field :datetime, :naive_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:batch_reference, :name, :amount, :datetime])
    |> validate_required([:batch_reference, :name, :amount])
    |> put_datetime()
  end

  defp put_datetime(changeset) do
    case get_field(changeset, :datetime) do
      nil -> put_change(changeset, :datetime, NaiveDateTime.local_now())
      _ -> changeset
    end
  end
end
