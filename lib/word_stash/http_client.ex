defmodule WordStash.HTTPClient do
  @moduledoc """
  HTTP client for making requests using the Req library.
  """

  @behaviour WordStash.HTTPClientBehaviour

  @doc """
  Fetches the HTML content from a given URL.

  Returns `{:ok, html}` on success or `{:error, reason}` on failure.
  """
  @impl true
  def get(url) do
    case Req.get(url) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
end
