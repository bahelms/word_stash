defmodule WordStashWeb.WelcomeLive do
  use WordStashWeb, :live_view
  alias WordStash.Articles

  def mount(_params, _session, socket) do
    {:ok, assign(socket, url: "")}
  end

  def handle_event("stash", %{"url" => url}, socket) do
    case Articles.create_article(%{
           url: url,
           user_id: socket.assigns.current_scope.user.id
         }) do
      {:ok, article} ->
        {:noreply,
         socket
         |> push_navigate(to: "/articles/#{article.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message =
          case changeset.errors do
            [url: {"URL has already been stashed", _}] -> "This URL has already been stashed!"
            [url: {msg, _}] -> "Invalid URL: #{msg}"
            _ -> "Failed to stash article. Please check the URL format."
          end

        {:noreply,
         socket
         |> put_flash(:error, error_message)
         |> assign(url: url)}
    end
  end

  def handle_event("url-change", %{"url" => url}, socket) do
    {:noreply, assign(socket, url: url)}
  end

  def handle_event("url-change", _params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-100 via-base-200 to-base-300">
      <.app_header>
        <:actions>
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
      
    <!-- Flash Messages (Error Only) -->
      <.flash kind={:error} flash={@flash} />
      
    <!-- Main Content -->
      <main class="flex items-center justify-center p-4 sm:p-6 lg:p-8 flex-1 mt-20 sm:mt-20 lg:mt-24">
        <div class="w-full max-w-2xl">
          <div class="card bg-base-100 shadow-2xl border border-base-300 overflow-hidden backdrop-blur-sm">
            <div class="card-body p-6 sm:p-8 lg:p-12">
              
    <!-- URL Stash Form -->
              <div class="max-w-lg mx-auto">
                <.form
                  for={to_form(%{"url" => @url})}
                  phx-submit="stash"
                  id="stash-form"
                  class="space-y-4"
                >
                  <div class="form-control">
                    <.input
                      field={to_form(%{"url" => @url})[:url]}
                      type="url"
                      placeholder="URL"
                      value={@url}
                      phx-change="url-change"
                      phx-debounce="300"
                      class="input input-bordered input-lg w-full focus:input-primary transition-colors duration-200"
                      required
                      autofocus
                    />
                  </div>

                  <button
                    type="submit"
                    class="btn btn-primary btn-lg w-full group shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 active:translate-y-0"
                  >
                    <.icon
                      name="hero-bookmark"
                      class="w-5 h-5 mr-2 group-hover:scale-110 transition-transform duration-200"
                    /> Stash
                  </button>
                </.form>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
