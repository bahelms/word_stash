defmodule WordStash.LLMClient.Prompt do
  @moduledoc """
  Builds prompts for LLM article analysis.
  """

  @max_html_length 15_000
  @removable_tags ~w(script style nav header footer aside iframe noscript svg)

  @doc """
  Builds the analysis prompt for an article.

  Returns a string with the system and user prompts combined.
  """
  def build_analysis_prompt(html, url) do
    truncated_html =
      html
      |> clean_html()
      |> truncate_html()

    """
    You are an article analysis assistant. Analyze the following HTML content and extract structured information.

    URL: #{url}

    HTML Content:
    #{truncated_html}

    Please provide a JSON response with the following structure:
    {
      "author": "Author name (or null if not found)",
      "summary": "A 4-5 sentence summary of the article",
      "tags": ["tag1", "tag2", "tag3"],
      "published_date": "ISO 8601 date string (or null if not found)",
      "reading_time_minutes": 5
    }

    Guidelines:
    - Author should be the article author, not the website name
    - Summary should capture the main points concisely without directly copy and pasting content
    - Tags should be relevant topics or keywords (3-5 tags)
    - published_date should be in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)
    - reading_time_minutes should be estimated based on word count (assume 200 words per minute)
    - If any field cannot be determined, use null

    Respond with ONLY the JSON object, no additional text.
    """
  end

  @doc """
  Cleans HTML by removing tags that don't contribute to article analysis.

  Removes:
  - Scripts and styles (JavaScript/CSS code)
  - Navigation, headers, footers, sidebars (site structure)
  - Iframes, noscript tags (embedded/fallback content)
  - HTML comments
  - SVG graphics (often large, not useful for text analysis)

  Keeps:
  - Article content tags (article, main, section, div, p)
  - Headings (h1-h6)
  - Metadata tags (meta, title, time)
  - Text formatting (strong, em, span, a)
  """
  def clean_html(html) when is_binary(html) do
    html
    |> remove_tags(@removable_tags)
    |> remove_comments()
    |> collapse_whitespace()
  end

  def clean_html(_), do: ""

  defp remove_tags(html, tags) do
    Enum.reduce(tags, html, &remove_tag_and_content(&2, &1))
  end

  # Remove a tag and all its content
  defp remove_tag_and_content(html, tag) do
    # Match opening tag, content, and closing tag (case-insensitive, multiline, non-greedy)
    Regex.replace(~r/<#{tag}[^>]*>.*?<\/#{tag}>/is, html, "")
  end

  # Remove HTML comments
  defp remove_comments(html) do
    Regex.replace(~r/<!--.*?-->/s, html, "")
  end

  # Collapse multiple whitespace/newlines into single spaces
  defp collapse_whitespace(html) do
    html
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
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
