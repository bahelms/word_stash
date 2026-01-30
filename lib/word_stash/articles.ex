defmodule WordStash.Articles do
  @moduledoc """
  The Articles context.
  """

  import Ecto.Query, warn: false
  alias WordStash.Repo
  alias WordStash.Articles.Article
  alias WordStash.BackgroundJobs

  @doc """
  Creates an article.

  ## Examples

      iex> create_article(%{field: value})
      {:ok, %Article{}}

      iex> create_article(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_article(attrs \\ %{}) do
    attrs = preprocess_url_attrs(attrs)

    case %Article{}
         |> Article.changeset(attrs)
         |> Repo.insert() do
      {:ok, article} = result ->
        BackgroundJobs.fetch_article_title(article.id, article.url)
        result

      error ->
        error
    end
  end

  @doc """
  Gets a single article.

  Raises `Ecto.NoResultsError` if the Article does not exist.

  ## Examples

      iex> get_article!(123)
      %Article{}

      iex> get_article!(456)
      ** (Ecto.NoResultsError)

  """
  def get_article!(id), do: Repo.get!(Article, id)

  @doc """
  Lists articles for a specific user.

  ## Examples

      iex> list_user_articles(user_id)
      [%Article{}, ...]

  """
  def list_user_articles(user_id) do
    Article
    |> where(user_id: ^user_id)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists all articles.

  ## Examples

      iex> list_articles()
      [%Article{}, ...]

  """
  def list_articles do
    Article
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end

  @doc """
  Updates an article.

  ## Examples

      iex> update_article(article, %{field: new_value})
      {:ok, %Article{}}

      iex> update_article(article, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_article(%Article{} = article, attrs) do
    article
    |> Article.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an article.

  ## Examples

      iex> delete_article(article)
      {:ok, %Article{}}

      iex> delete_article(article)
      {:error, %Ecto.Changeset{}}

  """
  def delete_article(%Article{} = article) do
    Repo.delete(article)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking article changes.

  ## Examples

      iex> change_article(article)
      %Ecto.Changeset{data: %Article{}}

  """
  def change_article(%Article{} = article, attrs \\ %{}) do
    Article.changeset(article, attrs)
  end

  @doc """
  Sets the article's last_read_at to the current time.

  ## Examples

      iex> touch_article_last_read_at(article)
      {:ok, %Article{}}

  """
  def touch_article_last_read_at(%Article{} = article) do
    update_article(article, %{last_read_at: DateTime.utc_now()})
  end

  @doc """
  Updates just the title of an article.

  ## Examples

      iex> update_article_title(article, "New Title")
      {:ok, %Article{}}

  """
  def update_article_title(article_id, title) do
    article = get_article!(article_id)
    update_article(article, %{title: title})
  end

  @doc """
  Preprocesses URL attributes to remove UTM parameters.

  Removes query parameters that start with 'utm_' and cleans up
  the URL by removing the '?' if no query parameters remain.

  ## Examples

      iex> preprocess_url_attrs(%{url: "https://example.com?utm_source=google&other=value"})
      %{url: "https://example.com?other=value"}

      iex> preprocess_url_attrs(%{url: "https://example.com?utm_source=google&utm_campaign=test"})
      %{url: "https://example.com"}

      iex> preprocess_url_attrs(%{url: "https://example.com"})
      %{url: "https://example.com"}

  """
  def preprocess_url_attrs(attrs) do
    case Map.get(attrs, :url) do
      nil -> attrs
      url -> Map.put(attrs, :url, preprocess_url(url))
    end
  end

  @doc """
  Preprocesses a single URL to remove UTM parameters.

  ## Examples

      iex> preprocess_url("https://example.com?utm_source=google&other=value")
      "https://example.com?other=value"

      iex> preprocess_url("https://example.com?utm_source=google&utm_campaign=test")
      "https://example.com"

      iex> preprocess_url("https://example.com")
      "https://example.com"

  """
  def preprocess_url(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{query: nil} ->
        url

      %URI{query: query} = uri ->
        filtered_params = filter_utm_params(query)
        rebuild_url_with_query(uri, filtered_params)

      _ ->
        url
    end
  end

  defp filter_utm_params(query) when is_binary(query) do
    query
    |> URI.decode_query()
    |> Enum.reject(fn {key, _value} -> String.starts_with?(key, "utm_") end)
  end

  defp rebuild_url_with_query(uri, []) do
    base_url = %{uri | query: nil}
    URI.to_string(base_url)
  end

  defp rebuild_url_with_query(uri, params) do
    query_string = URI.encode_query(params)
    updated_uri = %{uri | query: query_string}
    URI.to_string(updated_uri)
  end
end
