defmodule WordStashWeb.ArticlesShowTest do
  use WordStashWeb.ConnCase
  use Oban.Testing, repo: WordStash.Repo

  import Phoenix.LiveViewTest
  import WordStash.AccountsFixtures
  import WordStash.ArticlesFixtures

  setup %{conn: conn} do
    user = user_fixture()
    scope = WordStash.Accounts.Scope.for_user(user)

    conn =
      conn
      |> log_in_user(user)
      |> assign(:current_scope, scope)

    %{conn: conn, user: user, scope: scope}
  end

  describe "Show" do
    test "displays article", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      assert has_element?(view, "#article-visit-button")
      # Reload article since background job may have updated the title
      article = WordStash.Articles.get_article!(article.id)
      assert render(view) =~ article.title
    end

    test "clicking Visit updates article last_read_at", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      assert article.last_read_at == nil

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      view
      |> element("#article-visit-button")
      |> render_click()

      updated = WordStash.Articles.get_article!(article.id)
      assert updated.last_read_at != nil
      assert DateTime.diff(DateTime.utc_now(), updated.last_read_at, :second) < 2
    end

    test "displays archive button for unarchived article", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")
      assert has_element?(view, "#article-archive-button")
    end

    test "clicking Archive sets archived_at and hides the button", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      assert article.archived_at == nil

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      view
      |> element("#article-archive-button")
      |> render_click()

      updated = WordStash.Articles.get_article!(article.id)
      assert updated.archived_at != nil

      refute has_element?(view, "#article-archive-button")
      assert render(view) =~ "Archived"
    end

    test "does not display archive button for already archived article", %{
      conn: conn,
      user: user
    } do
      article = article_fixture(%{user_id: user.id, archived_at: DateTime.utc_now()})
      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")
      refute has_element?(view, "#article-archive-button")
      assert render(view) =~ "Archived"
    end

    test "clicking Delete removes the article and redirects to articles", %{
      conn: conn,
      user: user
    } do
      article = article_fixture(%{user_id: user.id})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      view
      |> element("#article-delete-button")
      |> render_click()

      assert_redirected(view, ~p"/articles")
      assert WordStash.Repo.get(WordStash.Articles.Article, article.id) == nil
    end

    test "clicking title enters edit mode and saving updates title", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, article} = WordStash.Articles.update_article(article, %{title: "Original Title"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      assert render(view) =~ "Original Title"

      view |> element("h1") |> render_click()

      assert has_element?(view, "input[name='article[title]']")

      view
      |> form("form", article: %{title: "Updated Title"})
      |> render_submit()

      assert render(view) =~ "Updated Title"
      refute has_element?(view, "input[name='article[title]']")

      updated = WordStash.Articles.get_article!(article.id)
      assert updated.title == "Updated Title"
    end

    test "clicking cancel exits title edit mode without saving", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, article} = WordStash.Articles.update_article(article, %{title: "Original Title"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      view |> element("h1") |> render_click()

      assert has_element?(view, "input[name='article[title]']")

      view |> element("button[phx-click=cancel_title]") |> render_click()

      refute has_element?(view, "input[name='article[title]']")
      assert render(view) =~ "Original Title"

      unchanged = WordStash.Articles.get_article!(article.id)
      assert unchanged.title == "Original Title"
    end

    test "shows Analyze Article button when status is pending", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, _article} = WordStash.Articles.update_article(article, %{status: "pending"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      assert has_element?(view, "button[phx-click=analyze]")
      assert render(view) =~ "Analyze Article"
    end

    test "shows Analyze Article button when status is pending_ai", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, _article} = WordStash.Articles.update_article(article, %{status: "pending_ai"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      assert has_element?(view, "button[phx-click=analyze]")
      assert render(view) =~ "Analyze Article"
    end

    test "shows Analyze Article button when status is failed", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, _article} = WordStash.Articles.update_article(article, %{status: "failed"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      assert has_element?(view, "button[phx-click=analyze]")
      assert render(view) =~ "Analyze Article"
    end

    test "does not show Analyze Article button when status is complete", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, _article} = WordStash.Articles.update_article(article, %{status: "complete"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      refute has_element?(view, "button[phx-click=analyze]")
    end

    test "clicking Analyze Article enqueues the analysis worker", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, _article} = WordStash.Articles.update_article(article, %{status: "pending_ai"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      view
      |> element("button[phx-click=analyze]")
      |> render_click()

      assert_enqueued(
        worker: WordStash.Workers.AnalyzeArticleWorker,
        args: %{article_id: article.id, url: article.url}
      )
    end

    test "shows spinner after clicking Analyze Article", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, _article} = WordStash.Articles.update_article(article, %{status: "pending"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      refute has_element?(view, ".loading-spinner")

      view
      |> element("button[phx-click=analyze]")
      |> render_click()

      assert has_element?(view, ".loading-spinner")
      refute has_element?(view, "button[phx-click=analyze]")
    end

    test "spinner is removed when article status becomes complete", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, _article} = WordStash.Articles.update_article(article, %{status: "pending"})

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      view
      |> element("button[phx-click=analyze]")
      |> render_click()

      assert has_element?(view, ".loading-spinner")

      completed_article = %{article | status: "complete"}
      send(view.pid, {:article_updated, completed_article})

      refute has_element?(view, ".loading-spinner")
      refute has_element?(view, "button[phx-click=analyze]")
    end

    test "displays last_read_at when set", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      {:ok, updated} = WordStash.Articles.touch_article_last_read_at(article)

      {:ok, view, _html} = live(conn, ~p"/articles/#{article.id}")

      html = render(view)
      assert html =~ "Last read"
      assert html =~ Calendar.strftime(updated.last_read_at, "%B %d, %Y at %I:%M %p")
    end
  end
end
