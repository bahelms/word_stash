defmodule WordStash.Articles.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :url, :string
    field :title, :string
    field :description, :string
    belongs_to :user, WordStash.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:url, :title, :description, :user_id])
    |> validate_required([:url])
    |> validate_format(:url, ~r/^https?:\/\//,
      message: "must be a valid URL starting with http:// or https://"
    )
    |> validate_length(:url, max: 2048)
    |> validate_length(:title, max: 255)
    |> validate_length(:description, max: 1000)
    |> unique_constraint(:url, name: :articles_url_index, message: "URL has already been stashed")
    |> assoc_constraint(:user)
  end
end
