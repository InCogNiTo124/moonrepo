defmodule Jaja.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :batch_reference, references(:batches, column: :unique_reference, type: :string, on_delete: :delete_all)
      add :name, :string
      add :amount, :integer
      add :datetime, :naive_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
