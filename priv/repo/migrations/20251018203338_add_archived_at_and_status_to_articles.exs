defmodule WordStash.Repo.Migrations.AddArchivedAtAndStatusToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :archived_at, :utc_datetime
      add :status, :string, default: "pending"
    end
  end
end
