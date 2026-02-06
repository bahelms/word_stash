defmodule WordStash.Repo.Migrations.AddAiFieldsToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :summary, :text
      add :author, :string
      add :published_at, :utc_datetime
      add :reading_time_minutes, :integer
      add :tags, :text
      add :ai_analyzed_at, :utc_datetime
      add :analysis_error, :text
    end
  end
end
