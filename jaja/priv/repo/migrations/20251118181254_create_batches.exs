defmodule Jaja.Repo.Migrations.CreateBatches do
  use Ecto.Migration

  def change do
    create table(:batches) do
      add :type, :string
      add :amount, :integer
      add :datetime, :naive_datetime
      add :unique_reference, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:batches, [:unique_reference])
  end
end
