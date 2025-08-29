defmodule WordStashWeb.UserLive.ConfirmationTest do
  use WordStashWeb.ConnCase

  import Phoenix.LiveViewTest
  import WordStash.AccountsFixtures

  alias WordStash.Accounts

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), confirmed_user: user_fixture()}
  end

  describe "Confirm user" do
    test "renders login page for confirmed user", %{conn: conn, confirmed_user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/login/#{token}")
      refute html =~ "Confirm my account"
      assert html =~ "Keep me logged in on this device"
    end

    test "logs confirmed user in without changing confirmed_at", %{
      conn: conn,
      confirmed_user: user
    } do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/login/#{token}")

      form = form(lv, "#login_form", %{"user" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Welcome back!"

      assert Accounts.get_user!(user.id).confirmed_at == user.confirmed_at
      conn = build_conn()

      {:ok, _lv, html} =
        live(conn, ~p"/login/#{token}")
        |> follow_redirect(conn, ~p"/login")

      assert html =~ "Log in"
      assert html =~ "Don&#39;t have an account?"
    end

    test "raises error for invalid token", %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, ~p"/login/invalid-token")
        |> follow_redirect(conn, ~p"/login")

      assert html =~ "Log in"
      assert html =~ "Don&#39;t have an account?"
    end
  end
end
