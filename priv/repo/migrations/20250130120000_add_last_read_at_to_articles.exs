defmodule WordStash.Repo.Migrations.AddLastReadAtToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :last_read_at, :utc_datetime
    end
  end
end
