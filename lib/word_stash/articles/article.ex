defmodule WordStash.Articles.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :url, :string
    field :title, :string
    field :description, :string
    field :archived_at, :utc_datetime
    field :last_read_at, :utc_datetime
    field :status, :string, default: "pending"

    # AI analysis fields
    field :summary, :string
    field :author, :string
    field :published_at, :utc_datetime
    field :reading_time_minutes, :integer
    field :tags, :string
    field :ai_analyzed_at, :utc_datetime
    field :analysis_error, :string

    belongs_to :user, WordStash.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:url, :title, :description, :user_id, :archived_at, :last_read_at, :status])
    |> validate_required([:url])
    |> validate_format(:url, ~r/^https?:\/\//,
      message: "must be a valid URL starting with http:// or https://"
    )
    |> validate_length(:url, max: 2048)
    |> validate_length(:title, max: 255)
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:status, ["pending", "pending_ai", "complete", "failed"])
    |> unique_constraint(:url, name: :articles_url_index, message: "URL has already been stashed")
    |> assoc_constraint(:user)
  end

  @doc """
  Changeset for updating article with AI analysis results.
  """
  def analysis_changeset(article, attrs) do
    article
    |> cast(attrs, [
      :summary,
      :author,
      :published_at,
      :reading_time_minutes,
      :tags,
      :ai_analyzed_at,
      :status
    ])
    |> validate_inclusion(:status, ["pending", "pending_ai", "complete", "failed"])
  end

  @doc """
  Changeset for marking article analysis as failed.
  """
  def analysis_failure_changeset(article, error_message) do
    article
    |> cast(%{status: "failed", analysis_error: error_message}, [:status, :analysis_error])
    |> validate_inclusion(:status, ["pending", "pending_ai", "complete", "failed"])
  end
end
