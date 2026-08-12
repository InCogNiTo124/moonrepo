defmodule Jaja.Shop.Batch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "batches" do
    field :type, :string
    field :amount, :integer
    field :datetime, :naive_datetime
    field :unique_reference, :string
    field :price, :float
    field :active, :boolean, default: true

    has_many :orders, Jaja.Shop.Order,
      foreign_key: :batch_reference,
      references: :unique_reference

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(batch, attrs) do
    batch
    |> cast(attrs, [:type, :amount, :datetime, :unique_reference, :price],
      message: &cast_error_message/2
    )
    |> validate_required([:type, :amount, :price])
    |> put_datetime()
    |> put_unique_reference()
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> unique_constraint(:unique_reference)
    |> unique_constraint(:id, name: "batches_pkey", message: "already taken, retry")
  end

  @doc """
  Changeset for flipping a batch between active and inactive.

  Kept separate from `changeset/2` so the create form can never mass-assign `:active`.
  """
  def activation_changeset(batch, active) when is_boolean(active) do
    change(batch, active: active)
  end

  # Replaces Ecto's generic "is invalid" for values that fail to cast to the field type.
  defp cast_error_message(:amount, _meta), do: "must be a whole number, for example 20"
  defp cast_error_message(:price, _meta), do: "must be a number, for example 3.50"
  defp cast_error_message(:type, _meta), do: "must be text"
  defp cast_error_message(:datetime, _meta), do: "must be a date and time"
  defp cast_error_message(:unique_reference, _meta), do: "must be text"
  defp cast_error_message(_field, %{type: type}), do: "must be a valid #{inspect(type)} value"

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
