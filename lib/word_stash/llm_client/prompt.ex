defmodule WordStash.LLMClient.Prompt do
  @moduledoc """
  Builds prompts for LLM article analysis.
  """

  @max_html_length 15_000

  @doc """
  Builds the analysis prompt for an article.

  Returns a string with the system and user prompts combined.
  """
  def build_analysis_prompt(html, url) do
    truncated_html = truncate_html(html)

    """
    You are an article analysis assistant. Analyze the following HTML content and extract structured information.

    URL: #{url}

    HTML Content:
    #{truncated_html}

    Please provide a JSON response with the following structure:
    {
      "title": "The article title",
      "author": "Author name (or null if not found)",
      "summary": "A 2-3 sentence summary of the article",
      "tags": ["tag1", "tag2", "tag3"],
      "published_date": "ISO 8601 date string (or null if not found)",
      "reading_time_minutes": 5
    }

    Guidelines:
    - Extract the actual article title from the content, not just the page title
    - Author should be the article author, not the website name
    - Summary should capture the main points concisely
    - Tags should be relevant topics or keywords (3-5 tags)
    - published_date should be in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)
    - reading_time_minutes should be estimated based on word count (assume 200 words per minute)
    - If any field cannot be determined, use null

    Respond with ONLY the JSON object, no additional text.
    """
  end

  @doc """
  Truncates HTML to fit within context limits.

  Keeps the first ~15k characters of HTML to stay within LLM context windows.
  """
  def truncate_html(html) when is_binary(html) do
    if String.length(html) > @max_html_length do
      String.slice(html, 0, @max_html_length) <> "\n\n[Content truncated...]"
    else
      html
    end
  end

  def truncate_html(_), do: ""
end
