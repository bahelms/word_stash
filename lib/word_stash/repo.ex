defmodule WordStash.Repo do
  use Ecto.Repo,
    otp_app: :word_stash,
    adapter: Ecto.Adapters.SQLite3
end
