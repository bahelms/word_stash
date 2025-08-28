defmodule WordStash.ArticlesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WordStash.Articles` context.
  """

  alias WordStash.Articles
  alias WordStash.AccountsFixtures

  def article_fixture(attrs \\ %{}) do
    user_id = attrs[:user_id] || AccountsFixtures.user_fixture().id

    {:ok, article} =
      attrs
      |> Enum.into(%{
        url: "https://example#{System.unique_integer()}.com",
        title: "Test Article",
        description: "Test Description",
        user_id: user_id
      })
      |> Articles.create_article()

    article
  end
end
