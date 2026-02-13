defmodule WordStashWeb.UserSessionControllerTest do
  use WordStashWeb.ConnCase

  import WordStash.AccountsFixtures

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), user: user_fixture()}
  end

  describe "POST /login - email and password" do
    test "logs the user in", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/login", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ "Word Stash"
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/logout"
    end

    test "sets last_login_at on successful login", %{conn: conn, user: user} do
      user = set_password(user)
      assert is_nil(WordStash.Repo.get!(WordStash.Accounts.User, user.id).last_login_at)

      post(conn, ~p"/login", %{
        "user" => %{"email" => user.email, "password" => valid_user_password()}
      })

      updated_user = WordStash.Repo.get!(WordStash.Accounts.User, user.id)
      assert updated_user.last_login_at
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/login", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_word_stash_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/login", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "redirects to login page with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login?mode=password", %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "POST /login - magic link" do
    test "logs the user in", %{conn: conn, user: user} do
      {token, _hashed_token} = generate_user_magic_link_token(user)

      conn =
        post(conn, ~p"/login", %{
          "user" => %{"token" => token}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ "Word Stash"
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/logout"
    end

    test "sets last_login_at on successful magic link login", %{conn: conn, user: user} do
      assert is_nil(WordStash.Repo.get!(WordStash.Accounts.User, user.id).last_login_at)
      {token, _hashed_token} = generate_user_magic_link_token(user)

      post(conn, ~p"/login", %{
        "user" => %{"token" => token}
      })

      updated_user = WordStash.Repo.get!(WordStash.Accounts.User, user.id)
      assert updated_user.last_login_at
    end

    test "redirects to login page when magic link is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{"token" => "invalid"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "The link is invalid or it has expired."

      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "DELETE /logout" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
