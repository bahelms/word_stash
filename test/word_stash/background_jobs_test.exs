defmodule WordStash.BackgroundJobsTest do
  use WordStash.DataCase, async: false
  use Oban.Testing, repo: WordStash.Repo

  alias WordStash.Articles
  alias WordStash.Workers.AnalyzeArticleWorker

  setup do
    user = WordStash.AccountsFixtures.user_fixture()
    %{user: user}
  end

  describe "fetch_article_title/2 integration" do
    test "successfully fetches and updates article title", %{user: user} do
      expect(WordStash.HTTPClientMock, :get, fn url ->
        assert url == "https://example.com"

        html = """
        <!DOCTYPE html>
        <html>
          <head> <title>Test Article Title</title> </head>
          <body> <h1>Hello World</h1> </body>
        </html>
        """

        {:ok, html}
      end)

      article_attrs = %{
        url: "https://example.com",
        user_id: user.id,
        title: nil,
        description: nil
      }

      {:ok, article} = Articles.create_article(article_attrs)

      # In test mode, background jobs run synchronously, so no need to wait for DOWN message
      updated_article = Repo.reload!(article)
      assert updated_article.title == "Test Article Title"
      assert updated_article.status == "pending_ai"

      # Verify AnalyzeArticleWorker job was enqueued
      assert_enqueued(
        worker: AnalyzeArticleWorker,
        args: %{article_id: article.id, url: article.url}
      )
    end

    test "handles HTTP errors gracefully", %{user: user} do
      # Mock the HTTP client to return an error for the automatic background task
      expect(WordStash.HTTPClientMock, :get, fn url ->
        assert url == "https://example.com"
        {:error, "HTTP 404"}
      end)

      # Create an article without a title - this will automatically spawn a background task
      article_attrs = %{
        url: "https://example.com",
        user_id: user.id,
        title: nil,
        description: nil
      }

      {:ok, article} = Articles.create_article(article_attrs)

      # In test mode, background jobs run synchronously, so no need to wait for DOWN message
      updated_article = Repo.reload!(article)
      refute updated_article.title
      assert updated_article.status == "pending"

      # Verify AnalyzeArticleWorker job was NOT enqueued on error
      refute_enqueued(
        worker: AnalyzeArticleWorker,
        args: %{article_id: article.id, url: article.url}
      )
    end

    test "handles HTML parsing errors gracefully", %{user: user} do
      expect(WordStash.HTTPClientMock, :get, fn url ->
        assert url == "https://example.com"

        html = """
        <!DOCTYPE html>
        <html>
          <head>
          </head>
          <body>
            <h1>Hello World</h1>
          </body>
        </html>
        """

        {:ok, html}
      end)

      # Create an article without a title - this will automatically spawn a background task
      article_attrs = %{
        url: "https://example.com",
        user_id: user.id,
        title: nil,
        description: nil
      }

      {:ok, article} = Articles.create_article(article_attrs)

      # In test mode, background jobs run synchronously, so no need to wait for DOWN message
      updated_article = Repo.reload!(article)
      refute updated_article.title
      assert updated_article.status == "pending"

      # Verify AnalyzeArticleWorker job was NOT enqueued on parsing error
      refute_enqueued(
        worker: AnalyzeArticleWorker,
        args: %{article_id: article.id, url: article.url}
      )
    end
  end
end
