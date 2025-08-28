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
      assert Articles.get_article!(article.id) == article
    end

    test "list_user_articles/1 returns articles for specific user" do
      user1 = user_fixture()
      user2 = user_fixture()
      article1 = article_fixture(%{user_id: user1.id, url: "https://user1-article.com"})
      article2 = article_fixture(%{user_id: user2.id, url: "https://user2-article.com"})
      assert Articles.list_user_articles(user1.id) == [article1]
      assert Articles.list_user_articles(user2.id) == [article2]
    end

    test "update_article/2 with valid data updates the article" do
      article = article_fixture()
      assert {:ok, %Article{} = updated_article} = Articles.update_article(article, @update_attrs)
      assert updated_article.url == "https://updated-example.com"
      assert updated_article.title == "some updated title"
      assert updated_article.description == "some updated description"
    end

    test "update_article/2 with invalid data returns error changeset" do
      article = article_fixture()
      assert {:error, %Ecto.Changeset{}} = Articles.update_article(article, @invalid_attrs)
      assert article == Articles.get_article!(article.id)
    end

    test "delete_article/1 deletes the article" do
      article = article_fixture()
      assert {:ok, %Article{}} = Articles.delete_article(article)
      assert_raise Ecto.NoResultsError, fn -> Articles.get_article!(article.id) end
    end

    test "change_article/1 returns a article changeset" do
      article = article_fixture()
      assert %Ecto.Changeset{} = Articles.change_article(article)
    end
  end
end
