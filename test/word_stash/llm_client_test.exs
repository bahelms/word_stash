defmodule WordStash.LLMClientTest do
  use ExUnit.Case, async: true

  alias WordStash.LLMClient.Prompt

  describe "Prompt.build_analysis_prompt/2" do
    test "includes URL and HTML content" do
      html = "<html><body>Test content</body></html>"
      url = "https://example.com/article"

      prompt = Prompt.build_analysis_prompt(html, url)

      assert prompt =~ url
      assert prompt =~ html
      assert prompt =~ "JSON"
    end

    test "truncates long HTML content" do
      long_html = String.duplicate("a", 20_000)
      url = "https://example.com/article"

      prompt = Prompt.build_analysis_prompt(long_html, url)

      assert prompt =~ "[Content truncated...]"
      assert String.length(prompt) < 20_000
    end
  end

  describe "Prompt.truncate_html/1" do
    test "returns HTML as-is if under limit" do
      short_html = String.duplicate("a", 1000)
      assert Prompt.truncate_html(short_html) == short_html
    end

    test "truncates HTML if over limit" do
      long_html = String.duplicate("a", 20_000)
      result = Prompt.truncate_html(long_html)

      assert result =~ "[Content truncated...]"
      assert String.length(result) < String.length(long_html)
    end

    test "handles non-string input" do
      assert Prompt.truncate_html(nil) == ""
      assert Prompt.truncate_html(123) == ""
    end
  end
end
