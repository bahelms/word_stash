defmodule WordStash.BackgroundJobs do
  @moduledoc """
  Background job processing for WordStash.
  """

  require Logger
  alias WordStash.{Articles, HTMLParser}

  @http_client Application.compile_env(:word_stash, :http_client, WordStash.HTTPClient)

  @doc """
  Fetches and updates the title for an article in the background.
  """
  def fetch_article_title(article_id, url) do
    Task.Supervisor.async_nolink(WordStash.BackgroundJobs.TaskSupervisor, fn ->
      with {:get, {:ok, html}} <- {:get, @http_client.get(url)},
           {:parse, {:ok, title}} <- {:parse, HTMLParser.extract_title(html)} do
        Articles.update_article_title(article_id, title)
      else
        {:get, {:error, reason}} when is_binary(reason) ->
          Logger.warning("Failed to fetch HTML for article #{article_id}: #{reason}")
          :ok

        {:parse, {:error, reason}} ->
          Logger.warning("Failed to parse title for article #{article_id}: #{reason}")
          :ok
      end
    end)
  end
end
