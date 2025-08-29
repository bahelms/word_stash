defmodule WordStash.HTMLParser do
  @moduledoc """
  HTML parsing utilities for extracting content from HTML documents.
  """

  @doc """
  Extracts the title from HTML content.

  Returns `{:ok, title}` on success or `{:error, reason}` on failure.
  """
  def extract_title(html) do
    case Regex.run(~r/<title[^>]*>(.*?)<\/title>/is, html) do
      [_, title] ->
        title = String.trim(title)
        if title == "", do: {:error, "Empty title"}, else: {:ok, title}

      nil ->
        {:error, "No title found"}
    end
  end
end
