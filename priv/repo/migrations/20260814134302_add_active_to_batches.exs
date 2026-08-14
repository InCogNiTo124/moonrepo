defmodule Jaja.Repo.Migrations.AddActiveToBatches do
  use Ecto.Migration

  def up do
    alter table(:batches) do
      add :active, :boolean, default: true, null: false
    end

    # Existing batches that are already sold out start out inactive, matching the
    # automatic deactivation that now happens when the last unit is ordered.
    execute """
    UPDATE batches b
    SET active = false
    WHERE b.amount <= (
      SELECT COALESCE(SUM(o.amount), 0)
      FROM orders o
      WHERE o.batch_reference = b.unique_reference
    )
    """
  end

  def down do
    alter table(:batches) do
      remove :active
    end
  end
end
