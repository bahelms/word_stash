defmodule WordStash.HTTPClientBehaviour do
  @moduledoc """
  Behaviour for HTTP clients that can fetch web page HTML content.
  """

  @callback get(url :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
end
