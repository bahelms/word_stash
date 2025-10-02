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
      # Create an article for this user
      article = article_fixture(%{user_id: user.id})

      # Create a new connection and view to show the new article
      scope = WordStash.Accounts.Scope.for_user(user)
      conn = conn |> log_in_user(user) |> assign(:current_scope, scope)
      {:ok, view, _html} = live(conn, ~p"/articles")

      html = render(view)
      assert html =~ "The Stash"
      assert html =~ article.url
    end

    test "displays navigation links correctly", %{view: view} do
      html = render(view)

      assert html =~ "Home"
      assert html =~ "Settings"
      assert html =~ "Logout"
    end
  end
end
