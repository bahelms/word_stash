defmodule WordStash.Workers.AnalyzeArticleWorker do
  @moduledoc """
  Background worker for analyzing articles with LLM.

  Fetches article HTML, analyzes it with the configured LLM client,
  and updates the article with extracted metadata.
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  alias WordStash.Articles
  alias WordStash.LLMClient

  def enqueue(args) do
    __MODULE__.new(args)
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"article_id" => article_id, "url" => url},
        attempt: attempt,
        max_attempts: max_attempts
      }) do
    http_client = Application.get_env(:word_stash, :http_client, WordStash.HTTPClient)

    with {:ok, html} <- fetch_html(url, http_client),
         {:ok, analysis} <- LLMClient.analyze_article(html, url),
         {:ok, _article} <- Articles.update_article_analysis(article_id, analysis) do
      :ok
    else
      {:error, reason} when attempt >= max_attempts ->
        error_message = format_error(reason)
        Articles.mark_article_analysis_failed(article_id, error_message)
        :ok

      {:error, reason} ->
        {:error, format_error(reason)}
    end
  end

  defp fetch_html(url, http_client) do
    case http_client.get(url) do
      {:ok, html} when is_binary(html) ->
        {:ok, html}

      {:error, error} ->
        {:error, "HTTP request failed: #{inspect(error)}"}
    end
  end

  defp format_error(reason) when is_binary(reason), do: reason

  defp format_error(reason) do
    case reason do
      {:error, msg} when is_binary(msg) -> msg
      _ -> inspect(reason)
    end
  end
end
