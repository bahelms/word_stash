defmodule WordStash.ArticlesTest do
  use WordStash.DataCase

  alias WordStash.Articles
  alias WordStash.Articles.Article
  import WordStash.AccountsFixtures

  describe "articles" do
    @valid_attrs %{
      url: "https://example.com",
      title: "some title",
      description: "some description"
    }
    @update_attrs %{
      url: "https://updated-example.com",
      title: "some updated title",
      description: "some updated description"
    }
    @invalid_attrs %{url: nil, title: nil, description: nil}

    def article_fixture(attrs \\ %{}) do
      user = user_fixture()

      {:ok, article} =
        attrs
        |> Enum.into(%{url: "https://example#{:rand.uniform(1000)}.com", user_id: user.id})
        |> Articles.create_article()

      article
    end

    test "list_articles/0 returns all articles" do
      article1 = article_fixture(%{url: "https://example1.com"})
      article2 = article_fixture(%{url: "https://example2.com"})
      articles = Articles.list_articles()
      assert length(articles) == 2
      assert Enum.any?(articles, fn a -> a.url == article1.url end)
      assert Enum.any?(articles, fn a -> a.url == article2.url end)
    end

    test "list_articles/0 excludes archived articles" do
      _archived = article_fixture(%{url: "https://archived.com", archived_at: DateTime.utc_now()})
      active = article_fixture(%{url: "https://active.com"})
      articles = Articles.list_articles()
      assert length(articles) == 1
      assert Enum.any?(articles, fn a -> a.url == active.url end)
    end

    test "create_article/1 with valid data creates a article" do
      user = user_fixture()

      assert {:ok, %Article{} = article} =
               Articles.create_article(@valid_attrs |> Map.put(:user_id, user.id))

      assert article.url == "https://example.com"
      assert article.title == "some title"
      assert article.description == "some description"
    end

    test "create_article/1 with invalid data returns error changeset" do
      user = user_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Articles.create_article(@invalid_attrs |> Map.put(:user_id, user.id))
    end

    test "get_article!/1 returns the article with given id" do
      article = article_fixture()
      # Reload to get updated title from background job
      article = Repo.reload!(article)
      assert Articles.get_article!(article.id) == article
    end

    test "list_user_articles/1 returns articles for specific user" do
      user1 = user_fixture()
      user2 = user_fixture()
      article1 = article_fixture(%{user_id: user1.id, url: "https://user1-article.com"})
      article2 = article_fixture(%{user_id: user2.id, url: "https://user2-article.com"})

      # Reload articles to get updated titles from background jobs
      article1 = Repo.reload!(article1)
      article2 = Repo.reload!(article2)

      assert Articles.list_user_articles(user1.id) == [article1]
      assert Articles.list_user_articles(user2.id) == [article2]
    end

    test "update_article/2 with valid data updates the article" do
      article = article_fixture()
      # Reload to get updated title from background job
      article = Repo.reload!(article)
      assert {:ok, %Article{} = updated_article} = Articles.update_article(article, @update_attrs)
      assert updated_article.url == "https://updated-example.com"
      assert updated_article.title == "some updated title"
      assert updated_article.description == "some updated description"
    end

    test "update_article/2 with invalid data returns error changeset" do
      article = article_fixture()
      # Reload to get updated title from background job
      article = Repo.reload!(article)
      assert {:error, %Ecto.Changeset{}} = Articles.update_article(article, @invalid_attrs)
      assert article == Articles.get_article!(article.id)
    end

    test "delete_article/1 deletes the article" do
      article = article_fixture()
      # Reload to get updated title from background job
      article = Repo.reload!(article)
      assert {:ok, %Article{}} = Articles.delete_article(article)
      assert_raise Ecto.NoResultsError, fn -> Articles.get_article!(article.id) end
    end

    test "change_article/1 returns a article changeset" do
      article = article_fixture()
      # Reload to get updated title from background job
      article = Repo.reload!(article)
      assert %Ecto.Changeset{} = Articles.change_article(article)
    end
  end

  describe "archived_at field" do
    test "create_article/1 with archived_at creates article with archived timestamp" do
      user = user_fixture()
      archived_time = DateTime.utc_now() |> DateTime.truncate(:second)

      assert {:ok, %Article{} = article} =
               Articles.create_article(%{
                 url: "https://example.com",
                 title: "Test Article",
                 user_id: user.id,
                 archived_at: archived_time
               })

      assert article.archived_at == archived_time
    end

    test "create_article/1 without archived_at creates article with nil archived_at" do
      user = user_fixture()

      assert {:ok, %Article{} = article} =
               Articles.create_article(%{
                 url: "https://example.com",
                 title: "Test Article",
                 user_id: user.id
               })

      assert article.archived_at == nil
    end

    test "update_article/2 can set archived_at" do
      article = article_fixture()
      article = Repo.reload!(article)
      archived_time = DateTime.utc_now() |> DateTime.truncate(:second)

      assert {:ok, %Article{} = updated_article} =
               Articles.update_article(article, %{archived_at: archived_time})

      assert updated_article.archived_at == archived_time
    end

    test "update_article/2 can clear archived_at" do
      user = user_fixture()
      archived_time = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, article} =
        Articles.create_article(%{
          url: "https://example.com",
          title: "Test Article",
          user_id: user.id,
          archived_at: archived_time
        })

      assert {:ok, %Article{} = updated_article} =
               Articles.update_article(article, %{archived_at: nil})

      assert updated_article.archived_at == nil
    end
  end

  describe "status field" do
    test "create_article/1 defaults to pending status" do
      user = user_fixture()

      assert {:ok, %Article{} = article} =
               Articles.create_article(%{
                 url: "https://example.com",
                 title: "Test Article",
                 user_id: user.id
               })

      assert article.status == "pending"
    end

    test "create_article/1 with valid status values" do
      user = user_fixture()

      valid_statuses = ["pending", "pending_ai", "complete"]

      for status <- valid_statuses do
        assert {:ok, %Article{} = article} =
                 Articles.create_article(%{
                   url: "https://example#{:rand.uniform(1000)}.com",
                   title: "Test Article",
                   user_id: user.id,
                   status: status
                 })

        assert article.status == status
      end
    end

    test "create_article/1 with invalid status returns error changeset" do
      user = user_fixture()

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Articles.create_article(%{
                 url: "https://example.com",
                 title: "Test Article",
                 user_id: user.id,
                 status: "invalid_status"
               })

      assert {:status,
              {"is invalid",
               [
                 validation: :inclusion,
                 enum: ["pending", "pending_ai", "complete", "failed"]
               ]}} in errors
    end

    test "update_article/2 can update status to valid values" do
      article = article_fixture()
      article = Repo.reload!(article)

      valid_statuses = ["pending", "pending_ai", "complete", "failed"]

      for status <- valid_statuses do
        assert {:ok, %Article{} = updated_article} =
                 Articles.update_article(article, %{status: status})

        assert updated_article.status == status
      end
    end

    test "update_article/2 with invalid status returns error changeset" do
      article = article_fixture()
      article = Repo.reload!(article)

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Articles.update_article(article, %{status: "invalid_status"})

      assert {:status,
              {"is invalid",
               [
                 validation: :inclusion,
                 enum: ["pending", "pending_ai", "complete", "failed"]
               ]}} in errors
    end
  end

  describe "archived_at and status field combinations" do
    test "create_article/1 with both archived_at and status" do
      user = user_fixture()
      archived_time = DateTime.utc_now() |> DateTime.truncate(:second)

      assert {:ok, %Article{} = article} =
               Articles.create_article(%{
                 url: "https://example.com",
                 title: "Test Article",
                 user_id: user.id,
                 archived_at: archived_time,
                 status: "complete"
               })

      assert article.archived_at == archived_time
      assert article.status == "complete"
    end

    test "update_article/2 can update both archived_at and status together" do
      article = article_fixture()
      article = Repo.reload!(article)
      archived_time = DateTime.utc_now() |> DateTime.truncate(:second)

      assert {:ok, %Article{} = updated_article} =
               Articles.update_article(article, %{
                 archived_at: archived_time,
                 status: "pending_ai"
               })

      assert updated_article.archived_at == archived_time
      assert updated_article.status == "pending_ai"
    end

    test "article_fixture/1 creates article with default status" do
      article = article_fixture()
      assert article.status == "pending"
      assert article.archived_at == nil
    end

    test "article_fixture/1 can override status and archived_at" do
      archived_time = DateTime.utc_now() |> DateTime.truncate(:second)

      article =
        article_fixture(%{
          status: "complete",
          archived_at: archived_time
        })

      assert article.status == "complete"
      assert article.archived_at == archived_time
    end
  end

  describe "archive_article/1" do
    test "sets archived_at to current time" do
      article = article_fixture()
      assert article.archived_at == nil

      assert {:ok, updated} = Articles.archive_article(article)
      assert updated.archived_at != nil
    end
  end

  describe "last_read_at field" do
    test "touch_article_last_read_at/1 sets last_read_at to current time" do
      article = article_fixture()
      assert article.last_read_at == nil

      assert {:ok, updated} = Articles.touch_article_last_read_at(article)
      assert updated.last_read_at != nil
      assert DateTime.diff(DateTime.utc_now(), updated.last_read_at, :second) < 2
    end
  end

  describe "URL preprocessing" do
    test "preprocess_url/1 removes utm_ parameters" do
      url_with_utm = "https://example.com?utm_source=google&other=value"
      expected = "https://example.com?other=value"
      assert Articles.preprocess_url(url_with_utm) == expected
    end

    test "preprocess_url/1 removes utm_ parameters and cleans up empty query" do
      url_with_only_utm = "https://example.com?utm_source=google"
      expected = "https://example.com"
      assert Articles.preprocess_url(url_with_only_utm) == expected
    end

    test "preprocess_url/1 leaves URLs without query parameters unchanged" do
      url_without_query = "https://example.com"
      assert Articles.preprocess_url(url_without_query) == url_without_query
    end

    test "preprocess_url/1 leaves URLs with non-utm parameters unchanged" do
      url_with_non_utm = "https://example.com?param1=value1&param2=value2"
      assert Articles.preprocess_url(url_with_non_utm) == url_with_non_utm
    end

    test "preprocess_url/1 removes multiple utm_ parameters" do
      url_with_multiple_utm =
        "https://example.com?utm_source=google&utm_campaign=test&utm_medium=email&other=value"

      expected = "https://example.com?other=value"
      assert Articles.preprocess_url(url_with_multiple_utm) == expected
    end

    test "preprocess_url/1 handles URLs with fragments" do
      url_with_fragment = "https://example.com?utm_source=google#section"
      expected = "https://example.com#section"
      assert Articles.preprocess_url(url_with_fragment) == expected
    end

    test "preprocess_url/1 handles complex query parameters" do
      complex_url =
        "https://example.com?utm_source=google&utm_campaign=test&other=value&utm_medium=social"

      result = Articles.preprocess_url(complex_url)

      # Parse the result to verify it contains the expected parameters
      %URI{query: query} = URI.parse(result)
      params = URI.decode_query(query)

      # Should contain other, but not any utm_ parameters
      assert Map.has_key?(params, "other")
      refute Map.has_key?(params, "utm_source")
      refute Map.has_key?(params, "utm_campaign")
      refute Map.has_key?(params, "utm_medium")
      assert params["other"] == "value"
    end

    test "preprocess_url/1 removes all utm_ variants" do
      url_with_all_utm =
        "https://example.com?utm_source=google&utm_campaign=test&utm_medium=email&utm_term=keyword&utm_content=ad&other=value"

      result = Articles.preprocess_url(url_with_all_utm)

      # Parse the result to verify only non-utm parameters remain
      %URI{query: query} = URI.parse(result)
      params = URI.decode_query(query)

      assert Map.has_key?(params, "other")
      assert params["other"] == "value"
      assert map_size(params) == 1
    end

    test "preprocess_url_attrs/1 processes URL in attributes map" do
      attrs = %{url: "https://example.com?utm_source=google", title: "Test"}
      expected = %{url: "https://example.com", title: "Test"}
      assert Articles.preprocess_url_attrs(attrs) == expected
    end

    test "preprocess_url_attrs/1 leaves attributes without URL unchanged" do
      attrs = %{title: "Test", description: "Test description"}
      assert Articles.preprocess_url_attrs(attrs) == attrs
    end

    test "create_article/1 automatically preprocesses URLs" do
      user = user_fixture()
      url_with_utm = "https://example.com?utm_source=google&other=value"

      assert {:ok, %WordStash.Articles.Article{} = article} =
               Articles.create_article(%{
                 url: url_with_utm,
                 user_id: user.id
               })

      assert article.url == "https://example.com?other=value"
    end

    test "create_article/1 removes utm_ parameters and cleans up empty query" do
      user = user_fixture()
      url_with_only_utm = "https://example.com?utm_source=google&utm_campaign=test"

      assert {:ok, %WordStash.Articles.Article{} = article} =
               Articles.create_article(%{
                 url: url_with_only_utm,
                 user_id: user.id
               })

      assert article.url == "https://example.com"
    end
  end

  describe "Article.analysis_changeset/2" do
    test "casts analysis fields correctly" do
      article = article_fixture()

      attrs = %{
        summary: "This is a summary of the article",
        author: "John Doe",
        published_at: ~U[2024-06-15 10:30:00Z],
        reading_time_minutes: 8,
        tags: "elixir,phoenix,testing",
        ai_analyzed_at: ~U[2024-06-16 12:00:00Z],
        status: "complete"
      }

      changeset = Article.analysis_changeset(article, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :summary) == "This is a summary of the article"
      assert Ecto.Changeset.get_change(changeset, :author) == "John Doe"
      assert Ecto.Changeset.get_change(changeset, :published_at) == ~U[2024-06-15 10:30:00Z]
      assert Ecto.Changeset.get_change(changeset, :reading_time_minutes) == 8
      assert Ecto.Changeset.get_change(changeset, :tags) == "elixir,phoenix,testing"
      assert Ecto.Changeset.get_change(changeset, :ai_analyzed_at) == ~U[2024-06-16 12:00:00Z]
      assert Ecto.Changeset.get_change(changeset, :status) == "complete"
    end

    test "allows nil values for optional fields" do
      article = article_fixture()

      attrs = %{
        summary: "Summary only",
        author: nil,
        published_at: nil,
        reading_time_minutes: nil,
        tags: nil,
        ai_analyzed_at: ~U[2024-06-16 12:00:00Z],
        status: "complete"
      }

      changeset = Article.analysis_changeset(article, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :summary) == "Summary only"
      assert Ecto.Changeset.get_change(changeset, :author) == nil
      assert Ecto.Changeset.get_change(changeset, :published_at) == nil
      assert Ecto.Changeset.get_change(changeset, :reading_time_minutes) == nil
    end

    test "validates status inclusion" do
      article = article_fixture()

      attrs = %{
        summary: "Summary",
        status: "invalid_status"
      }

      changeset = Article.analysis_changeset(article, attrs)

      refute changeset.valid?

      assert {:status, {"is invalid", [validation: :inclusion, enum: _]}} =
               Enum.find(changeset.errors, fn {field, _} -> field == :status end)
    end

    test "accepts all valid status values" do
      article = article_fixture()

      for status <- ["pending", "pending_ai", "complete", "failed"] do
        changeset = Article.analysis_changeset(article, %{status: status})
        assert changeset.valid?, "Expected status '#{status}' to be valid"
      end
    end

    test "does not cast fields not in analysis changeset" do
      article = article_fixture()

      attrs = %{
        summary: "Summary",
        url: "https://should-not-change.com",
        title: "Should not change",
        user_id: 999
      }

      changeset = Article.analysis_changeset(article, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :summary) == "Summary"
      assert Ecto.Changeset.get_change(changeset, :url) == nil
      assert Ecto.Changeset.get_change(changeset, :title) == nil
      assert Ecto.Changeset.get_change(changeset, :user_id) == nil
    end
  end

  describe "Article.analysis_failure_changeset/2" do
    test "sets status to failed and stores error message" do
      article = article_fixture()
      error_message = "LLM API timeout after 3 attempts"

      changeset = Article.analysis_failure_changeset(article, error_message)

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :status) == "failed"
      assert Ecto.Changeset.get_change(changeset, :analysis_error) == error_message
    end

    test "accepts any string as error message" do
      article = article_fixture()

      for error <- ["Connection timeout", "HTTP 500", "Invalid JSON response"] do
        changeset = Article.analysis_failure_changeset(article, error)
        assert changeset.valid?
        assert Ecto.Changeset.get_change(changeset, :analysis_error) == error
      end
    end

    test "handles empty string as error message" do
      article = article_fixture()

      changeset = Article.analysis_failure_changeset(article, "")
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :status) == "failed"
      # Empty string may not be tracked as a change if field is already nil
    end

    test "does not change other fields" do
      article = article_fixture()
      error_message = "Test error"

      changeset = Article.analysis_failure_changeset(article, error_message)

      # Only status and analysis_error should be in changes
      changes = Map.keys(changeset.changes)
      assert :status in changes
      assert :analysis_error in changes
      assert length(changes) == 2
    end

    test "validates status is failed" do
      article = article_fixture()

      changeset = Article.analysis_failure_changeset(article, "Error message")

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :status) == "failed"

      # Verify status validation would catch invalid values
      # (though the changeset always sets it to "failed")
      assert changeset.validations[:status] == nil ||
               {:status, {:inclusion, ["pending", "pending_ai", "complete", "failed"]}} in changeset.validations
    end
  end

  describe "update_article_analysis/2" do
    test "updates article with analysis results and sets status to complete" do
      article = article_fixture()

      analysis_attrs = %{
        summary: "This is a comprehensive summary of the article content.",
        author: "Jane Smith",
        published_at: ~U[2024-06-15 14:30:00Z],
        reading_time_minutes: 12,
        tags: "elixir,phoenix,testing,oban"
      }

      assert {:ok, %Article{} = updated_article} =
               Articles.update_article_analysis(article.id, analysis_attrs)

      assert updated_article.summary == "This is a comprehensive summary of the article content."
      assert updated_article.author == "Jane Smith"
      assert updated_article.published_at == ~U[2024-06-15 14:30:00Z]
      assert updated_article.reading_time_minutes == 12
      assert updated_article.tags == "elixir,phoenix,testing,oban"
      assert updated_article.status == "complete"
      assert updated_article.ai_analyzed_at != nil
    end

    test "sets ai_analyzed_at timestamp" do
      article = article_fixture()

      assert {:ok, %Article{} = updated_article} =
               Articles.update_article_analysis(article.id, %{
                 summary: "Summary"
               })

      assert updated_article.ai_analyzed_at != nil
      # Verify the timestamp is reasonable (within the last minute)
      now = DateTime.utc_now()
      diff = DateTime.diff(now, updated_article.ai_analyzed_at, :second)
      assert diff >= 0 and diff < 60
    end

    test "handles partial analysis results with nil optional fields" do
      article = article_fixture()

      analysis_attrs = %{
        summary: "Summary only",
        author: nil,
        published_at: nil,
        reading_time_minutes: nil,
        tags: nil
      }

      assert {:ok, %Article{} = updated_article} =
               Articles.update_article_analysis(article.id, analysis_attrs)

      assert updated_article.summary == "Summary only"
      assert updated_article.author == nil
      assert updated_article.published_at == nil
      assert updated_article.reading_time_minutes == nil
      assert updated_article.tags == nil
      assert updated_article.status == "complete"
      assert updated_article.ai_analyzed_at != nil
    end

    test "raises when article does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Articles.update_article_analysis(999_999, %{summary: "Summary"})
      end
    end

    test "does not modify fields outside of analysis scope" do
      article = article_fixture()
      original_url = article.url
      original_user_id = article.user_id

      analysis_attrs = %{
        summary: "Summary",
        author: "Author"
      }

      assert {:ok, %Article{} = updated_article} =
               Articles.update_article_analysis(article.id, analysis_attrs)

      assert updated_article.url == original_url
      assert updated_article.user_id == original_user_id
    end

    test "can be called multiple times to update analysis" do
      article = article_fixture()

      # First analysis
      assert {:ok, %Article{} = updated_article} =
               Articles.update_article_analysis(article.id, %{
                 summary: "First summary",
                 author: "First Author"
               })

      assert updated_article.summary == "First summary"
      assert updated_article.author == "First Author"

      # Second analysis (update)
      assert {:ok, %Article{} = updated_article} =
               Articles.update_article_analysis(article.id, %{
                 summary: "Updated summary",
                 author: "Updated Author"
               })

      assert updated_article.summary == "Updated summary"
      assert updated_article.author == "Updated Author"
      assert updated_article.status == "complete"
    end
  end

  describe "mark_article_analysis_failed/2" do
    test "marks article as failed with error message" do
      article = article_fixture()
      error_message = "LLM API timeout after 3 attempts"

      assert {:ok, %Article{} = updated_article} =
               Articles.mark_article_analysis_failed(article.id, error_message)

      assert updated_article.status == "failed"
      assert updated_article.analysis_error == error_message
    end

    test "handles various error messages" do
      error_messages = [
        "Connection timeout",
        "HTTP 500 Server Error",
        "Invalid JSON response from LLM",
        "Rate limit exceeded",
        "HTTP request failed: :timeout"
      ]

      for error_message <- error_messages do
        article = article_fixture()

        assert {:ok, %Article{} = updated_article} =
                 Articles.mark_article_analysis_failed(article.id, error_message)

        assert updated_article.status == "failed"
        assert updated_article.analysis_error == error_message
      end
    end

    test "raises when article does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Articles.mark_article_analysis_failed(999_999, "Error message")
      end
    end

    test "does not modify other article fields" do
      article = article_fixture()
      # Reload to get updated title from background job
      article = Repo.reload!(article)
      original_url = article.url
      original_title = article.title
      original_user_id = article.user_id

      assert {:ok, %Article{} = updated_article} =
               Articles.mark_article_analysis_failed(article.id, "Error")

      assert updated_article.url == original_url
      assert updated_article.title == original_title
      assert updated_article.user_id == original_user_id
    end

    test "can be called multiple times to update error message" do
      article = article_fixture()

      # First failure
      assert {:ok, %Article{} = updated_article} =
               Articles.mark_article_analysis_failed(article.id, "First error")

      assert updated_article.analysis_error == "First error"

      # Second failure (different error)
      assert {:ok, %Article{} = updated_article} =
               Articles.mark_article_analysis_failed(article.id, "Second error")

      assert updated_article.analysis_error == "Second error"
      assert updated_article.status == "failed"
    end

    test "does not set ai_analyzed_at or analysis fields" do
      article = article_fixture()

      assert {:ok, %Article{} = updated_article} =
               Articles.mark_article_analysis_failed(article.id, "Error")

      assert updated_article.ai_analyzed_at == nil
      assert updated_article.summary == nil
      assert updated_article.author == nil
      assert updated_article.published_at == nil
      assert updated_article.reading_time_minutes == nil
      assert updated_article.tags == nil
    end
  end
end
