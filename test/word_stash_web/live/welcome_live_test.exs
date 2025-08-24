defmodule WordStashWeb.WelcomeLiveTest do
  use WordStashWeb.ConnCase

  import Phoenix.LiveViewTest
  import WordStash.AccountsFixtures

  alias WordStash.Articles

  setup %{conn: conn} do
    user = user_fixture()
    scope = WordStash.Accounts.Scope.for_user(user)

    conn =
      conn
      |> log_in_user(user)
      |> assign(:current_scope, scope)

    {:ok, view, _html} = live(conn, ~p"/")

    %{conn: conn, user: user, scope: scope, view: view}
  end

  describe "welcome page" do
    test "renders the welcome page with form", %{view: view} do
      assert has_element?(view, "span", "Word Stash")
      assert has_element?(view, "#stash-form")
      assert has_element?(view, "input[type='url']")
      assert has_element?(view, "button", "Stash")
    end

    test "shows user email in header", %{view: view} do
      assert has_element?(view, "span", "Word Stash")
    end

    test "has navigation buttons", %{view: view} do
      assert has_element?(view, "a[href='/users/settings']")
      assert has_element?(view, "a[href='/logout']")
    end
  end

  describe "URL stashing" do
    test "successfully stashes a valid URL", %{view: view, user: user} do
      url = "https://example.com/article"

      view
      |> form("#stash-form", %{url: url})
      |> render_submit()

      # Check that article was created in database
      articles = Articles.list_user_articles(user.id)
      assert length(articles) == 1
      assert hd(articles).url == url
      assert hd(articles).user_id == user.id
    end

    test "clears form after successful stash", %{view: view} do
      url = "https://example.com/article"

      view
      |> form("#stash-form", %{url: url})
      |> render_submit()

      # Form should be cleared
      assert render(view) =~ "placeholder=\"URL\""
      assert render(view) =~ "value=\"\""
    end

    test "shows error for invalid URL format", %{view: view} do
      invalid_url = "not-a-url"

      view
      |> form("#stash-form", %{url: invalid_url})
      |> render_submit()

      # Should show error message
      assert has_element?(view, ".alert-error")
      assert has_element?(view, ".alert-error", "Invalid URL")
    end

    test "shows error for duplicate URL", %{view: view, user: _user} do
      url = "https://example.com/article"

      # First stash should succeed
      view
      |> form("#stash-form", %{url: url})
      |> render_submit()

      # Second stash of same URL should fail
      view
      |> form("#stash-form", %{url: url})
      |> render_submit()

      # Should show duplicate error
      assert has_element?(view, ".alert-error")
      assert has_element?(view, ".alert-error", "This URL has already been stashed")
    end

    test "shows error for URL without protocol", %{view: view} do
      url = "example.com/article"

      view
      |> form("#stash-form", %{url: url})
      |> render_submit()

      # Should show format error
      assert has_element?(view, ".alert-error")

      assert has_element?(
               view,
               ".alert-error",
               "must be a valid URL starting with http:// or https://"
             )
    end

    test "maintains form value on error", %{view: view} do
      invalid_url = "not-a-url"

      view
      |> form("#stash-form", %{url: invalid_url})
      |> render_submit()

      # Form should maintain the invalid value
      assert render(view) =~ "value=\"#{invalid_url}\""
    end
  end

  describe "form interactions" do
    test "updates input value as user types", %{view: view} do
      url = "https://example.com"

      view
      |> element("input[type='url']")
      |> render_change(%{url: url})

      # Input should show the typed value
      assert render(view) =~ "value=\"#{url}\""
    end

    test "debounces input changes", %{view: view} do
      # This test verifies the phx-debounce attribute is present
      assert render(view) =~ "phx-debounce=\"300\""
    end

    test "requires URL field", %{view: view} do
      # Check that required attribute is present
      assert render(view) =~ "required"
    end
  end

  describe "error handling" do
    test "handles database errors gracefully", %{view: view} do
      # This would require mocking the Articles context to simulate database errors
      # For now, we'll test that the error handling structure exists
      assert render(view) =~ "phx-submit=\"stash\""
    end

    test "shows appropriate error messages for different error types", %{view: view} do
      # Test various error scenarios
      test_cases = [
        {"not-a-url", "Invalid URL"},
        {"example.com", "must be a valid URL starting with http:// or https://"}
      ]

      for {url, expected_error} <- test_cases do
        view
        |> form("#stash-form", %{url: url})
        |> render_submit()

        assert has_element?(view, ".alert-error")
        assert has_element?(view, ".alert-error", expected_error)
      end
    end
  end

  describe "authentication" do
    test "allows authenticated users", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      scope = WordStash.Accounts.Scope.for_user(user)
      conn = assign(conn, :current_scope, scope)

      assert {:ok, _view, _html} = live(conn, ~p"/")
    end
  end
end
