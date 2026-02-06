defmodule WordStash.LLMClient do
  @moduledoc """
  Main dispatcher for LLM client operations.

  Delegates to the configured LLM client implementation based on the environment.
  """

  @behaviour WordStash.LLMClientBehaviour

  @impl true
  def analyze_article(html, url) do
    client = Application.get_env(:word_stash, :llm_client)

    if is_nil(client) do
      raise "LLM client not configured. Set :llm_client in config."
    end

    client.analyze_article(html, url)
  end
end
