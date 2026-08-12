defmodule Jaja.Repo.Migrations.AddStatusToOrders do
  use Ecto.Migration

  def up do
    alter table(:orders) do
      add :payment_received, :boolean, default: false, null: false
      add :delivered, :boolean, default: false, null: false
    end

    flush()

    execute("UPDATE orders SET payment_received = true, delivered = true")
  end

  def down do
    alter table(:orders) do
      remove :payment_received
      remove :delivered
    end
  end
end
