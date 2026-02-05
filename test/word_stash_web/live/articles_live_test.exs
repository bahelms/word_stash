defmodule WordStashWeb.ArticlesLiveTest do
  use WordStashWeb.ConnCase

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

    {:ok, view, _html} = live(conn, ~p"/articles")

    %{conn: conn, user: user, scope: scope, view: view}
  end

  describe "Index" do
    test "shows empty state when no articles exist", %{view: view} do
      html = render(view)

      assert html =~ "No articles yet"
      assert html =~ "Start stashing articles to see them here"
      assert html =~ "Stash Your First Article"
    end

    test "lists articles when user is logged in", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})

      scope = WordStash.Accounts.Scope.for_user(user)
      conn = conn |> log_in_user(user) |> assign(:current_scope, scope)
      {:ok, view, _html} = live(conn, ~p"/articles")

      html = render(view)
      assert html =~ "The Stash"
      assert has_element?(view, "#article-visit-#{article.id}")
    end

    test "displays navigation links correctly", %{view: view} do
      html = render(view)

      assert html =~ "Home"
      assert html =~ "Settings"
      assert html =~ "Logout"
    end

    test "does not display archived articles", %{conn: conn, user: user} do
      active = article_fixture(%{user_id: user.id, url: "https://active.com"})

      archived =
        article_fixture(%{
          user_id: user.id,
          url: "https://archived.com",
          archived_at: DateTime.utc_now()
        })

      scope = WordStash.Accounts.Scope.for_user(user)
      conn = conn |> log_in_user(user) |> assign(:current_scope, scope)
      {:ok, view, _html} = live(conn, ~p"/articles")

      assert has_element?(view, "#article-visit-#{active.id}")
      refute has_element?(view, "#article-visit-#{archived.id}")
    end

    test "clicking Visit updates article last_read_at", %{conn: conn, user: user} do
      article = article_fixture(%{user_id: user.id})
      assert article.last_read_at == nil

      scope = WordStash.Accounts.Scope.for_user(user)
      conn = conn |> log_in_user(user) |> assign(:current_scope, scope)
      {:ok, view, _html} = live(conn, ~p"/articles")

      view
      |> element("#article-visit-#{article.id}")
      |> render_click()

      updated = WordStash.Articles.get_article!(article.id)
      assert updated.last_read_at != nil
      assert DateTime.diff(DateTime.utc_now(), updated.last_read_at, :second) < 2
    end
  end
end
