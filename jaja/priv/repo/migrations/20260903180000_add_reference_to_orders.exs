defmodule Jaja.Repo.Migrations.AddReferenceToOrders do
  use Ecto.Migration

  import Ecto.Query

  # A public, unguessable handle for an order, so a customer can return to their
  # confirmation page. Sequential ids would let anyone page through other
  # customers' names and amounts. Existing orders are backfilled one by one.
  def up do
    alter table(:orders) do
      add :reference, :string
    end

    flush()

    for id <- repo().all(from(o in "orders", select: o.id)) do
      repo().update_all(from(o in "orders", where: o.id == ^id),
        set: [reference: Nanoid.generate()]
      )
    end

    alter table(:orders) do
      modify :reference, :string, null: false
    end

    create unique_index(:orders, [:reference])
  end

  def down do
    drop unique_index(:orders, [:reference])

    alter table(:orders) do
      remove :reference
    end
  end
end
