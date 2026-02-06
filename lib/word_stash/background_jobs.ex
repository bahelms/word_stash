defmodule WordStash.BackgroundJobs do
  @moduledoc """
  Background job processing for WordStash.
  """

  require Logger
  alias WordStash.{Articles, HTMLParser}

  @doc """
  Fetches and updates the title for an article in the background.
  """
  def fetch_article_title(article_id, url) do
    http_client = Application.get_env(:word_stash, :http_client, WordStash.HTTPClient)

    # In test environment, run synchronously to avoid database sandbox issues
    if Mix.env() == :test do
      fetch_article_title_sync(article_id, url, http_client)
    else
      Task.Supervisor.async_nolink(WordStash.BackgroundJobs.TaskSupervisor, fn ->
        fetch_article_title_sync(article_id, url, http_client)
      end)
    end
  end

  defp fetch_article_title_sync(article_id, url, http_client) do
    with {:get, {:ok, html}} <- {:get, http_client.get(url)},
         {:parse, {:ok, title}} <- {:parse, HTMLParser.extract_title(html)},
         {:ok, article} <- Articles.update_article_title(article_id, title),
         {:ok, _article} <- Articles.update_article(article, %{status: "pending_ai"}) do
      %{article_id: article_id, url: url}
      |> WordStash.Workers.AnalyzeArticleWorker.enqueue()

      :ok
    else
      {:get, {:error, reason}} when is_binary(reason) ->
        Logger.warning("Failed to fetch HTML for article #{article_id}: #{reason}")
        :ok

      {:parse, {:error, reason}} ->
        Logger.warning("Failed to parse title for article #{article_id}: #{reason}")
        :ok

      {:error, _changeset} ->
        Logger.warning("Failed to update article #{article_id}")
        :ok
    end
  end
end
