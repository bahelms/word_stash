defmodule WordStashWeb.ArticlesLive do
  use WordStashWeb, :live_view
  alias WordStash.Articles

  def mount(_params, _session, socket) do
    articles = Articles.list_articles()
    {:ok, assign(socket, articles: articles)}
  end

  def handle_event("visit", %{"id" => id}, socket) do
    article = Articles.get_article!(id)
    Articles.touch_article_last_read_at(article)
    {:noreply, push_event(socket, "open_url", %{url: article.url})}
  end

  def render(assigns) do
    ~H"""
    <div
      id="articles-live-root"
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
            <span class="hidden sm:inline">Stash</span>
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
        <div class="max-w-6xl mx-auto">
          <div class="text-center mb-8">
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-base-content mb-4">
              The Stash
            </h1>
          </div>

          <%= if Enum.empty?(@articles) do %>
            <div class="text-center py-12">
              <div class="w-24 h-24 mx-auto mb-4 text-base-content/30">
                <.icon name="hero-book-open" class="w-full h-full" />
              </div>
              <h3 class="text-xl font-semibold text-base-content mb-2">No articles yet</h3>
              <p class="text-base-content/70 mb-6">Start stashing articles to see them here</p>
              <.link
                navigate="/"
                class="btn btn-primary"
              >
                <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Stash Your First Article
              </.link>
            </div>
          <% else %>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <%= for article <- @articles do %>
                <div class="card bg-base-100 shadow-xl border border-base-300 hover:shadow-2xl transition-all duration-300 hover:-translate-y-1">
                  <div class="card-body">
                    <div class="flex items-start justify-between mb-3">
                      <div class="w-10 h-10 bg-gradient-to-br from-primary to-secondary rounded-lg flex items-center justify-center flex-shrink-0">
                        <.icon name="hero-bookmark" class="w-5 h-5 text-primary-content" />
                      </div>
                      <div class="text-sm text-base-content/60">
                        {Calendar.strftime(article.inserted_at, "%b %d, %Y")}
                      </div>
                    </div>

                    <h3 class="card-title text-lg mb-2 line-clamp-2">
                      <.link
                        navigate={"/articles/#{article.id}"}
                        class="text-base-content/70 mb-4 line-clamp-3 hover:text-primary cursor-pointer"
                      >
                        <%= if article.title && article.title != "" do %>
                          {article.title}
                        <% else %>
                          <span class="text-base-content/70 italic">Untitled Article</span>
                        <% end %>
                      </.link>
                    </h3>

                    <%= if article.description && article.description != "" do %>
                      {article.description}
                    <% end %>

                    <div class="card-actions justify-end">
                      <button
                        type="button"
                        phx-click="visit"
                        phx-value-id={article.id}
                        class="btn btn-primary btn-sm"
                        id={"article-visit-#{article.id}"}
                      >
                        <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4 mr-1" /> Visit
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </main>
    </div>
    """
  end
end
