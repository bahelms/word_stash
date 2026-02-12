defmodule WordStash.HTTPClient do
  @moduledoc """
  HTTP client for making requests using the Req library.
  """

  @behaviour WordStash.HTTPClientBehaviour

  require Logger

  @doc """
  Fetches the HTML content from a given URL.

  Returns `{:ok, html}` on success or `{:error, reason}` on failure.
  """
  @impl true
  def get(url) do
    case Req.get(url,
           headers: [
             {"user-agent",
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"}
           ]
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("HTTP non-200: #{inspect(body)}")
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
end
