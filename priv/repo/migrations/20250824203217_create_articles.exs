defmodule WordStash.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :url, :text, null: false
      add :title, :string
      add :description, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:articles, [:user_id])
    create index(:articles, [:url])
  end
end
