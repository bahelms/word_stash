defmodule WordStash.Workers.AnalyzeArticleWorkerTest do
  use WordStash.DataCase, async: true
  use Oban.Testing, repo: WordStash.Repo

  import Mox

  alias WordStash.Workers.AnalyzeArticleWorker
  alias WordStash.Articles

  setup :verify_on_exit!

  describe "perform/1" do
    setup do
      user = WordStash.AccountsFixtures.user_fixture()

      {:ok, article} =
        Articles.create_article(%{
          url: "https://example.com/article",
          user_id: user.id,
          status: "pending_ai"
        })

      %{article: article, user: user}
    end

    test "successfully analyzes article and updates fields", %{article: article} do
      expect(WordStash.HTTPClientMock, :get, fn _url ->
        {:ok, "<html><body>Article content</body></html>"}
      end)

      expect(WordStash.LLMClientMock, :analyze_article, fn _html, _url ->
        {:ok,
         %{
           title: "AI Generated Title",
           author: "Jane Doe",
           summary: "This is a summary of the article.",
           tags: "ai,testing,elixir",
           published_at: ~U[2024-06-15 10:30:00Z],
           reading_time_minutes: 8
         }}
      end)

      assert :ok =
               perform_job(AnalyzeArticleWorker, %{
                 article_id: article.id,
                 url: article.url
               })

      updated_article = Articles.get_article!(article.id)
      assert updated_article.status == "complete"
      assert updated_article.summary == "This is a summary of the article."
      assert updated_article.author == "Jane Doe"
      assert updated_article.tags == "ai,testing,elixir"
      assert updated_article.published_at == ~U[2024-06-15 10:30:00Z]
      assert updated_article.reading_time_minutes == 8
      assert updated_article.ai_analyzed_at != nil
    end

    test "handles partial analysis results (missing optional fields)", %{article: article} do
      expect(WordStash.HTTPClientMock, :get, fn _url ->
        {:ok, "<html><body>Article content</body></html>"}
      end)

      expect(WordStash.LLMClientMock, :analyze_article, fn _html, _url ->
        {:ok,
         %{
           title: "AI Generated Title",
           author: nil,
           summary: "This is a summary.",
           tags: "ai",
           published_at: nil,
           reading_time_minutes: nil
         }}
      end)

      assert :ok =
               perform_job(AnalyzeArticleWorker, %{
                 article_id: article.id,
                 url: article.url
               })

      updated_article = Articles.get_article!(article.id)
      assert updated_article.status == "complete"
      assert updated_article.summary == "This is a summary."
      assert updated_article.author == nil
      assert updated_article.published_at == nil
      assert updated_article.reading_time_minutes == nil
    end

    test "retries on intermediate failures", %{article: article} do
      expect(WordStash.HTTPClientMock, :get, fn _url ->
        {:error, "Connection timeout"}
      end)

      # Create a job with attempt = 1 (not final)
      args = %{"article_id" => article.id, "url" => article.url}
      job = %Oban.Job{args: args, attempt: 1, max_attempts: 3}

      assert {:error, _reason} = AnalyzeArticleWorker.perform(job)

      # Article should not be marked as failed yet
      updated_article = Articles.get_article!(article.id)
      assert updated_article.status == "pending_ai"
      assert updated_article.analysis_error == nil
    end

    test "marks article as failed when LLM analysis fails on final attempt", %{article: article} do
      expect(WordStash.HTTPClientMock, :get, fn _url ->
        {:ok, "<html><body>Article content</body></html>"}
      end)

      expect(WordStash.LLMClientMock, :analyze_article, fn _html, _url ->
        {:error, "LLM API timeout"}
      end)

      # Create a job with attempt = 3 (final attempt)
      args = %{"article_id" => article.id, "url" => article.url}
      job = %Oban.Job{args: args, attempt: 3, max_attempts: 3}

      assert :ok = AnalyzeArticleWorker.perform(job)

      # Article should be marked as failed
      updated_article = Articles.get_article!(article.id)
      assert updated_article.status == "failed"
      assert updated_article.analysis_error == "LLM API timeout"
    end

    test "handles HTTP request failure", %{article: article} do
      # First attempt should retry
      expect(WordStash.HTTPClientMock, :get, fn _url ->
        {:error, :timeout}
      end)

      args = %{"article_id" => article.id, "url" => article.url}
      job = %Oban.Job{args: args, attempt: 1, max_attempts: 3}

      assert {:error, _reason} = AnalyzeArticleWorker.perform(job)

      # Final attempt should mark as failed
      expect(WordStash.HTTPClientMock, :get, fn _url ->
        {:error, :timeout}
      end)

      job_final = %Oban.Job{args: args, attempt: 3, max_attempts: 3}
      assert :ok = AnalyzeArticleWorker.perform(job_final)

      updated_article = Articles.get_article!(article.id)
      assert updated_article.status == "failed"
      assert updated_article.analysis_error =~ "HTTP request failed"
    end
  end
end
