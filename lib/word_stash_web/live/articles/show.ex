defmodule WordStashWeb.Live.Articles.Show do
  use WordStashWeb, :live_view
  alias WordStash.Articles

  defp utc_to_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp utc_to_iso8601(%NaiveDateTime{} = ndt),
    do: NaiveDateTime.to_iso8601(ndt) |> String.replace(" ", "T") |> Kernel.<>("Z")

  def mount(%{"id" => id}, _session, socket) do
    article = Articles.get_article!(id)
    if connected?(socket), do: Articles.subscribe(article.id)
    {:ok, assign(socket, article: article, editing_title: false, title_form: nil)}
  end

  def handle_info({:article_updated, article}, socket) do
    {:noreply, assign(socket, article: article)}
  end

  def handle_event("archive", _params, socket) do
    case Articles.archive_article(socket.assigns.article) do
      {:ok, updated} -> {:noreply, assign(socket, :article, updated)}
      {:error, _} -> {:noreply, socket}
    end
  end

  def handle_event("delete", _params, socket) do
    Articles.delete_article(socket.assigns.article)
    {:noreply, push_navigate(socket, to: "/articles")}
  end

  def handle_event("edit_title", _params, socket) do
    form =
      socket.assigns.article
      |> Articles.change_article(%{})
      |> to_form()

    {:noreply, assign(socket, editing_title: true, title_form: form)}
  end

  def handle_event("save_title", %{"article" => %{"title" => title}}, socket) do
    case Articles.update_article(socket.assigns.article, %{title: title}) do
      {:ok, updated} ->
        {:noreply, assign(socket, article: updated, editing_title: false, title_form: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, title_form: to_form(changeset))}
    end
  end

  def handle_event("cancel_title", _params, socket) do
    {:noreply, assign(socket, editing_title: false, title_form: nil)}
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
            <span class="hidden sm:inline">Stash</span>
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
                      Stashed on
                      <span data-utc-datetime={utc_to_iso8601(@article.inserted_at)}>
                        {Calendar.strftime(@article.inserted_at, "%B %d, %Y at %I:%M %p")}
                      </span>
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

              <%= if @editing_title do %>
                <.form for={@title_form} phx-submit="save_title" class="mb-6">
                  <div class="flex items-center gap-2">
                    <input
                      type="text"
                      name={@title_form[:title].name}
                      value={@title_form[:title].value}
                      class="input input-bordered text-lg sm:text-xl lg:text-2xl font-bold w-full h-auto py-3 sm:py-4"
                      autofocus
                      phx-key="Escape"
                      phx-keydown="cancel_title"
                    />
                    <button type="submit" class="btn btn-success btn-sm flex-shrink-0" title="Save">
                      <.icon name="hero-check" class="w-5 h-5" />
                    </button>
                    <button
                      type="button"
                      phx-click="cancel_title"
                      class="btn btn-error btn-sm flex-shrink-0"
                      title="Cancel"
                    >
                      <.icon name="hero-x-mark" class="w-5 h-5" />
                    </button>
                  </div>
                </.form>
              <% else %>
                <h1
                  class="text-3xl sm:text-4xl lg:text-5xl font-bold text-base-content mb-6 cursor-pointer hover:text-primary transition-colors"
                  phx-click="edit_title"
                  title="Click to edit title"
                >
                  <%= if @article.title && @article.title != "" do %>
                    {@article.title}
                  <% else %>
                    <span class="text-base-content/70 italic">Untitled Article</span>
                  <% end %>
                </h1>
              <% end %>

              <%= if @article.description && @article.description != "" do %>
                <div class="mb-6">
                  <p class="text-lg text-base-content/80 leading-relaxed">
                    {@article.description}
                  </p>
                </div>
              <% end %>

              <%= if @article.author || @article.published_at || @article.reading_time_minutes do %>
                <div class="mb-2 flex items-center flex-wrap gap-x-4 gap-y-1 text-sm text-base-content/70">
                  <%= if @article.author do %>
                    <span class="flex items-center space-x-1">
                      <.icon name="hero-user" class="w-4 h-4" />
                      <span class="font-medium">{@article.author}</span>
                    </span>
                  <% end %>
                  <%= if @article.published_at do %>
                    <span class="flex items-center space-x-1">
                      <.icon name="hero-calendar" class="w-4 h-4" />
                      <span>
                        <span data-utc-datetime={utc_to_iso8601(@article.published_at)}>
                          {Calendar.strftime(@article.published_at, "%B %d, %Y")}
                        </span>
                      </span>
                    </span>
                  <% end %>
                  <%= if @article.reading_time_minutes do %>
                    <span class="flex items-center space-x-1">
                      <.icon name="hero-clock" class="w-4 h-4" />
                      <span>{@article.reading_time_minutes} min read</span>
                    </span>
                  <% end %>
                </div>
              <% end %>

              <%= if @article.tags && @article.tags != "" do %>
                <div class="mt-1 mb-4 flex flex-wrap gap-2">
                  <%= for tag <- String.split(@article.tags, ",") do %>
                    <span class="badge badge-soft badge-primary badge-sm">
                      {String.trim(tag)}
                    </span>
                  <% end %>
                </div>
              <% end %>

              <%= if @article.summary && @article.summary != "" do %>
                <div class="p-4 bg-base-200/50 rounded-lg border border-base-300">
                  <label class="text-sm font-semibold text-base-content/60 uppercase tracking-wide mb-2 block">
                    Summary
                  </label>
                  <p class="text-base-content/80 leading-relaxed">
                    {@article.summary}
                  </p>
                </div>
              <% end %>

              <div class="divider"></div>

              <div class="flex items-center flex-wrap gap-4">
                <div class="flex items-center gap-x-4 gap-y-1 flex-wrap">
                  <%= if @article.archived_at do %>
                    <div class="flex items-center space-x-2 text-sm">
                      <span class="font-semibold text-base-content/60 uppercase tracking-wide">
                        Archived
                      </span>
                      <span
                        class="text-base-content"
                        data-utc-datetime={utc_to_iso8601(@article.archived_at)}
                      >
                        {Calendar.strftime(@article.archived_at, "%B %d, %Y at %I:%M %p")}
                      </span>
                    </div>
                  <% end %>

                  <%= if @article.last_read_at do %>
                    <div class="flex items-center space-x-2 text-sm">
                      <span class="font-semibold text-base-content/60 uppercase tracking-wide">
                        Last read
                      </span>
                      <span
                        class="text-base-content"
                        data-utc-datetime={utc_to_iso8601(@article.last_read_at)}
                      >
                        {Calendar.strftime(@article.last_read_at, "%B %d, %Y at %I:%M %p")}
                      </span>
                    </div>
                  <% end %>
                </div>

                <div class="flex items-center space-x-2 ml-auto">
                  <button
                    type="button"
                    phx-click="visit"
                    class="btn btn-primary btn-sm flex-shrink-0"
                    id="article-visit-button"
                  >
                    <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4 mr-1" /> Visit
                  </button>
                  <%= if @article.archived_at == nil do %>
                    <button
                      type="button"
                      phx-click="archive"
                      class="btn btn-warning btn-sm flex-shrink-0"
                      id="article-archive-button"
                    >
                      <.icon name="hero-archive-box-arrow-down" class="w-4 h-4 mr-1" /> Archive
                    </button>
                  <% end %>
                  <button
                    type="button"
                    phx-click="delete"
                    phx-confirm="Are you sure you want to delete this article? This cannot be undone."
                    class="btn btn-error btn-sm flex-shrink-0"
                    id="article-delete-button"
                  >
                    <.icon name="hero-trash" class="w-4 h-4 mr-1" /> Delete
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
