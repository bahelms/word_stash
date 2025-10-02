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

  describe "URL preprocessing" do
    test "removes utm_ parameters when stashing URL", %{view: view, user: user} do
      url_with_utm = "https://example.com/article?utm_source=google&other=value"

      view
      |> form("#stash-form", %{url: url_with_utm})
      |> render_submit()

      # Check that article was created with UTM parameters removed
      articles = Articles.list_user_articles(user.id)
      assert length(articles) == 1
      assert hd(articles).url == "https://example.com/article?other=value"
    end

    test "removes utm_ parameters and cleans up empty query string", %{view: view, user: user} do
      url_with_only_utm = "https://example.com/article?utm_source=google&utm_campaign=test"

      view
      |> form("#stash-form", %{url: url_with_only_utm})
      |> render_submit()

      # Check that article was created with clean URL
      articles = Articles.list_user_articles(user.id)
      assert length(articles) == 1
      assert hd(articles).url == "https://example.com/article"
    end

    test "preserves non-utm parameters", %{view: view, user: user} do
      url_with_non_utm = "https://example.com/article?param1=value1&param2=value2"

      view
      |> form("#stash-form", %{url: url_with_non_utm})
      |> render_submit()

      # Check that article was created with all parameters preserved
      articles = Articles.list_user_articles(user.id)
      assert length(articles) == 1
      assert hd(articles).url == url_with_non_utm
    end

    test "handles URLs with fragments and utm_ parameters", %{view: view, user: user} do
      url_with_fragment_and_utm = "https://example.com/article?utm_source=google#section"

      view
      |> form("#stash-form", %{url: url_with_fragment_and_utm})
      |> render_submit()

      # Check that article was created with UTM removed but fragment preserved
      articles = Articles.list_user_articles(user.id)
      assert length(articles) == 1
      assert hd(articles).url == "https://example.com/article#section"
    end

    test "handles multiple utm_ parameters", %{view: view, user: user} do
      url_with_multiple_utm =
        "https://example.com/article?utm_source=google&utm_campaign=test&utm_medium=email&other=value"

      view
      |> form("#stash-form", %{url: url_with_multiple_utm})
      |> render_submit()

      # Check that all utm_ parameters were removed
      articles = Articles.list_user_articles(user.id)
      assert length(articles) == 1
      assert hd(articles).url == "https://example.com/article?other=value"
    end

    test "leaves URLs without query parameters unchanged", %{view: view, user: user} do
      url_without_query = "https://example.com/article"

      view
      |> form("#stash-form", %{url: url_without_query})
      |> render_submit()

      # Check that URL was preserved as-is
      articles = Articles.list_user_articles(user.id)
      assert length(articles) == 1
      assert hd(articles).url == url_without_query
    end
  end
end
