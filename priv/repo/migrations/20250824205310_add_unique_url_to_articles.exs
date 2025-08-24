defmodule WordStash.Repo.Migrations.AddUniqueUrlToArticles do
  use Ecto.Migration

  def change do
    drop_if_exists index(:articles, [:url])
    create unique_index(:articles, [:url])
  end
end
