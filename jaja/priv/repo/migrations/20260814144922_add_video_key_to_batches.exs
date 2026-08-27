defmodule Jaja.Repo.Migrations.AddVideoKeyToBatches do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      # Object key in the bucket, e.g. "batches/aBc123/clip.mp4". Nil means no video.
      add :video_key, :string
    end
  end
end
