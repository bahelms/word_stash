defmodule WordStashWeb.Live.Articles.Show do
  use WordStashWeb, :live_view
  alias WordStash.Articles

  defp utc_to_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp utc_to_iso8601(%NaiveDateTime{} = ndt),
    do: NaiveDateTime.to_iso8601(ndt) |> String.replace(" ", "T") |> Kernel.<>("Z")

  def mount(%{"id" => id}, _session, socket) do
    article = Articles.get_article!(id)
    {:ok, assign(socket, article: article)}
  end

  def handle_event("visit", _params, socket) do
    case Articles.touch_article_last_read_at(socket.assigns.article) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:article, updated)
         |> push_event("open_url", %{url: socket.assigns.article.url})}

      {:error, _} ->
        {:noreply, push_event(socket, "open_url", %{url: socket.assigns.article.url})}
    end
  end

  def render(assigns) do
    ~H"""
    <div
      id="article-show-root"
      class="min-h-screen bg-gradient-to-br from-base-100 via-base-200 to-base-300"
      phx-hook="OpenUrl"
    >
      <.app_header>
        <:actions>
          <.link
            navigate="/"
            class="btn btn-sm sm:btn-md btn-primary btn-outline"
          >
            <.icon name="hero-home" class="w-4 h-4 sm:w-5 sm:h-5 mr-1 sm:mr-2" />
            <span class="hidden sm:inline">Home</span>
          </.link>

          <.link
            navigate="/articles"
            class="btn btn-sm sm:btn-md btn-primary btn-outline"
          >
            <.icon name="hero-book-open" class="w-4 h-4 sm:w-5 sm:h-5 mr-1 sm:mr-2" />
            <span class="hidden sm:inline">Articles</span>
          </.link>

          <.link
            navigate="/users/settings"
            class="btn btn-sm sm:btn-md btn-primary btn-outline"
          >
            <.icon name="hero-cog-6-tooth" class="w-4 h-4 sm:w-5 sm:h-5 mr-1 sm:mr-2" />
            <span class="hidden sm:inline">Settings</span>
          </.link>

          <.link
            method="delete"
            href="/logout"
            class="btn btn-sm sm:btn-md btn-outline btn-error"
          >
            <.icon
              name="hero-arrow-right-on-rectangle"
              class="w-4 h-4 sm:w-5 sm:h-5 mr-1 sm:mr-2"
            />
            <span class="hidden sm:inline">Logout</span>
          </.link>
        </:actions>
      </.app_header>

      <main class="p-4 sm:p-6 lg:p-8 mt-4 sm:mt-20 lg:mt-24">
        <div id="article-show-content" phx-hook="LocalTime" class="max-w-4xl mx-auto">
          <div class="card bg-base-100 shadow-2xl border border-base-300 overflow-hidden backdrop-blur-sm">
            <div class="card-body p-6 sm:p-8 lg:p-12">
              <div class="flex items-start justify-between mb-6">
                <div class="flex items-center space-x-4">
                  <div class="w-12 h-12 bg-gradient-to-br from-primary to-secondary rounded-lg flex items-center justify-center flex-shrink-0">
                    <.icon name="hero-bookmark" class="w-6 h-6 text-primary-content" />
                  </div>
                  <div>
                    <div class="text-sm text-base-content/60 mb-1">
                      Stashed on <span data-utc-datetime={utc_to_iso8601(@article.inserted_at)}>{Calendar.strftime(@article.inserted_at, "%B %d, %Y at %I:%M %p")}</span>
                    </div>
                    <%= if @article.status do %>
                      <div class="badge badge-outline badge-sm">
                        {String.replace(@article.status, "_", " ")
                        |> String.split(" ")
                        |> Enum.map_join(" ", &String.capitalize(&1, :ascii))}
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>

              <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-base-content mb-6">
                <%= if @article.title && @article.title != "" do %>
                  {@article.title}
                <% else %>
                  <span class="text-base-content/70 italic">Untitled Article</span>
                <% end %>
              </h1>

              <%= if @article.description && @article.description != "" do %>
                <div class="mb-6">
                  <p class="text-lg text-base-content/80 leading-relaxed">
                    {@article.description}
                  </p>
                </div>
              <% end %>

              <div class="divider"></div>

              <div class="space-y-4">
                <div>
                  <label class="text-sm font-semibold text-base-content/60 uppercase tracking-wide mb-2 block">
                    URL
                  </label>
                  <div class="flex items-center space-x-2">
                    <a
                      href={@article.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      class="text-primary hover:text-primary-focus break-all flex-1"
                    >
                      {@article.url}
                    </a>
                    <button
                      type="button"
                      phx-click="visit"
                      class="btn btn-primary btn-sm flex-shrink-0"
                      id="article-visit-button"
                    >
                      <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4 mr-1" /> Visit
                    </button>
                  </div>
                </div>

                <%= if @article.archived_at do %>
                  <div>
                    <label class="text-sm font-semibold text-base-content/60 uppercase tracking-wide mb-2 block">
                      Archived
                    </label>
                    <p class="text-base-content">
                      <span data-utc-datetime={utc_to_iso8601(@article.archived_at)}>{Calendar.strftime(@article.archived_at, "%B %d, %Y at %I:%M %p")}</span>
                    </p>
                  </div>
                <% end %>

                <%= if @article.last_read_at do %>
                  <div>
                    <label class="text-sm font-semibold text-base-content/60 uppercase tracking-wide mb-2 block">
                      Last read
                    </label>
                    <p class="text-base-content">
                      <span data-utc-datetime={utc_to_iso8601(@article.last_read_at)}>{Calendar.strftime(@article.last_read_at, "%B %d, %Y at %I:%M %p")}</span>
                    </p>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
