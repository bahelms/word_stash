defmodule WordStash.LLMClientBehaviour do
  @moduledoc """
  Behaviour for LLM clients that analyze article content.
  """

  @doc """
  Analyzes an article's HTML content and returns structured data.

  Returns a map with the following keys:
  - title: String
  - author: String (optional)
  - summary: String
  - tags: List of strings
  - published_date: DateTime (optional)
  - reading_time_minutes: Integer (optional)
  """
  @callback analyze_article(html :: String.t(), url :: String.t()) ::
              {:ok, map()} | {:error, term()}
end
