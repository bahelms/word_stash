defmodule WordStash.LLMClient.Groq do
  @moduledoc """
  Groq LLM client implementation for production.
  """

  @behaviour WordStash.LLMClientBehaviour

  alias WordStash.LLMClient.Prompt

  @impl true
  def analyze_article(html, url) do
    api_key = Application.get_env(:word_stash, :groq_api_key)

    if is_nil(api_key) or api_key == "" do
      {:error, "GROQ_API_KEY environment variable not set"}
    else
      make_api_request(html, url, api_key)
    end
  end

  defp make_api_request(html, url, api_key) do
    model = Application.get_env(:word_stash, :groq_model)
    endpoint = "https://api.groq.com/openai/v1/chat/completions"
    prompt = Prompt.build_analysis_prompt(html, url)

    request_body = %{
      model: model,
      messages: [
        %{
          role: "user",
          content: prompt
        }
      ],
      response_format: %{type: "json_object"},
      temperature: 0.1
    }

    headers = [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}
    ]

    case Req.post(endpoint, json: request_body, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        parse_groq_response(body)

      {:ok, %{status: 401}} ->
        {:error, "Invalid Groq API key"}

      {:ok, %{status: 429}} ->
        {:error, "Groq API rate limit exceeded"}

      {:ok, %{status: status, body: body}} ->
        {:error, "Groq API returned status #{status}: #{inspect(body)}"}

      {:error, error} ->
        {:error, "Failed to connect to Groq API: #{inspect(error)}"}
    end
  end

  defp parse_groq_response(%{"choices" => [%{"message" => %{"content" => content}} | _]}) do
    case Jason.decode(content) do
      {:ok, parsed} ->
        {:ok, normalize_analysis(parsed)}

      {:error, _} ->
        {:error, "Failed to parse JSON response from Groq"}
    end
  end

  defp parse_groq_response(body) do
    {:error, "Unexpected response format from Groq: #{inspect(body)}"}
  end

  defp normalize_analysis(raw_analysis) do
    %{
      title: raw_analysis["title"],
      author: raw_analysis["author"],
      summary: raw_analysis["summary"],
      tags: parse_tags(raw_analysis["tags"]),
      published_at: parse_datetime(raw_analysis["published_date"]),
      reading_time_minutes: raw_analysis["reading_time_minutes"]
    }
  end

  defp parse_tags(tags) when is_list(tags), do: Enum.join(tags, ",")
  defp parse_tags(_), do: nil

  defp parse_datetime(nil), do: nil
  defp parse_datetime(""), do: nil

  defp parse_datetime(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  defp parse_datetime(_), do: nil
end
