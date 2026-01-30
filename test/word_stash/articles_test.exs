defmodule WordStash.ArticlesTest do
  use WordStash.DataCase

  alias WordStash.Articles
  import WordStash.AccountsFixtures

  describe "articles" do
    alias WordStash.Articles.Article

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
    alias WordStash.Articles.Article

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
    alias WordStash.Articles.Article

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
               [validation: :inclusion, enum: ["pending", "pending_ai", "complete"]]}} in errors
    end

    test "update_article/2 can update status to valid values" do
      article = article_fixture()
      article = Repo.reload!(article)

      valid_statuses = ["pending", "pending_ai", "complete"]

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
               [validation: :inclusion, enum: ["pending", "pending_ai", "complete"]]}} in errors
    end
  end

  describe "archived_at and status field combinations" do
    alias WordStash.Articles.Article

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
end
