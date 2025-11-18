defmodule Jaja.Shop.Batch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "batches" do
    field :type, :string
    field :amount, :integer
    field :datetime, :naive_datetime
    field :unique_reference, :string

    has_many :orders, Jaja.Shop.Order, foreign_key: :batch_reference, references: :unique_reference

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(batch, attrs) do
    batch
    |> cast(attrs, [:type, :amount, :datetime, :unique_reference])
    |> validate_required([:type, :amount])
    |> put_datetime()
    |> put_unique_reference()
    |> unique_constraint(:unique_reference)
  end

  defp put_datetime(changeset) do
    case get_field(changeset, :datetime) do
      nil -> put_change(changeset, :datetime, NaiveDateTime.local_now())
      _ -> changeset
    end
  end

  defp put_unique_reference(changeset) do
    case get_field(changeset, :unique_reference) do
      nil -> put_change(changeset, :unique_reference, Nanoid.generate())
      _ -> changeset
    end
  end
end
