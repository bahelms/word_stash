defmodule WordStash.LLMClient.Ollama do
  @moduledoc """
  Ollama LLM client implementation for local development.
  """

  @behaviour WordStash.LLMClientBehaviour

  alias WordStash.LLMClient.Prompt

  @impl true
  def analyze_article(html, url) do
    model = Application.get_env(:word_stash, :ollama_model)
    endpoint = Application.get_env(:word_stash, :ollama_endpoint)

    prompt = Prompt.build_analysis_prompt(html, url)

    request_body = %{
      model: model,
      prompt: prompt,
      stream: false,
      format: "json"
    }

    case Req.post("#{endpoint}/api/generate", json: request_body) do
      {:ok, %{status: 200, body: body}} ->
        parse_ollama_response(body)

      {:ok, %{status: status, body: body}} ->
        {:error, "Ollama API returned status #{status}: #{inspect(body)}"}

      {:error, error} ->
        {:error, "Failed to connect to Ollama: #{inspect(error)}"}
    end
  end

  # defp parse_ollama_response(%{"response" => response_text, "eval_count" => output_token_count, "prompt_eval_count" => input_token_count}) do
  defp parse_ollama_response(%{"response" => response_text}) do
    case Jason.decode(response_text) do
      {:ok, parsed} ->
        {:ok, normalize_analysis(parsed)}

      {:error, _} ->
        {:error, "Failed to parse JSON response from Ollama"}
    end
  end

  defp parse_ollama_response(body) do
    {:error, "Unexpected response format from Ollama: #{inspect(body)}"}
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
