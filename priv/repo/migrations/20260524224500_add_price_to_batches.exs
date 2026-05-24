defmodule Jaja.Repo.Migrations.AddPriceToBatches do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :price, :float, default: 3.5, null: false
    end
  end
end
