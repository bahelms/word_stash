defmodule WordStashWeb.UserLive.Login do
  use WordStashWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-100 via-base-200 to-base-300">
      <!-- Header Section -->
      <header class="sticky top-0 z-50 bg-base-100/80 backdrop-blur-md border-b border-base-300 shadow-sm">
        <div class="px-4 py-3 sm:px-6 sm:py-4">
          <div class="flex items-center justify-between">
            <!-- Logo/Brand -->
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 sm:w-10 sm:h-10 bg-gradient-to-br from-primary to-secondary rounded-lg flex items-center justify-center">
                <.icon name="hero-book-open" class="w-5 h-5 sm:w-6 sm:h-6 text-primary-content" />
              </div>
              <span class="text-lg sm:text-xl font-bold text-base-content">Word Stash</span>
            </div>
            
    <!-- Action Buttons -->
            <div class="flex items-center space-x-2 sm:space-x-3">
              <.link
                navigate="/register"
                class="btn btn-sm sm:btn-md btn-primary btn-outline"
              >
                <.icon name="hero-user-plus" class="w-4 h-4 sm:w-5 sm:h-5 mr-1 sm:mr-2" />
                <span class="hidden sm:inline">Sign Up</span>
              </.link>
            </div>
          </div>
        </div>
      </header>
      
    <!-- Flash Messages -->
      <.flash kind={:error} flash={@flash} />
      <.flash kind={:info} flash={@flash} />
      
    <!-- Main Content -->
      <main class="flex items-center justify-center p-4 sm:p-6 lg:p-8 flex-1 mt-20 sm:mt-20 lg:mt-24">
        <div class="w-full max-w-md">
          <div class="card bg-base-100 shadow-2xl border border-base-300 overflow-hidden backdrop-blur-sm">
            <div class="card-body p-6 sm:p-8 lg:p-10">
              
    <!-- Login Form -->
              <div class="text-center mb-6">
                <h1 class="text-2xl sm:text-3xl font-bold text-base-content mb-2">Log in</h1>
                <p class="text-base-content/70">
                  Don't have an account?
                  <.link navigate={~p"/register"} class="font-semibold text-primary hover:underline">
                    Sign up
                  </.link>
                  for an account now.
                </p>
              </div>

              <.form
                :let={f}
                for={@form}
                id="login_form_password"
                action={~p"/login"}
                phx-submit="submit_password"
                phx-trigger-action={@trigger_submit}
                class="space-y-4"
              >
                <div class="form-control">
                  <.input
                    readonly={!!@current_scope}
                    field={f[:email]}
                    type="email"
                    label="Email"
                    autocomplete="username"
                    class="input input-bordered w-full focus:input-primary transition-colors duration-200"
                    required
                  />
                </div>

                <div class="form-control">
                  <.input
                    field={@form[:password]}
                    type="password"
                    label="Password"
                    autocomplete="current-password"
                    class="input input-bordered w-full focus:input-primary transition-colors duration-200"
                    required
                  />
                </div>

                <button
                  type="submit"
                  class="btn btn-primary btn-lg w-full group shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 active:translate-y-0"
                >
                  <.icon
                    name="hero-arrow-right-on-rectangle"
                    class="w-5 h-5 mr-2 group-hover:scale-110 transition-transform duration-200"
                  /> Log in and stay logged in
                </button>

                <button
                  type="submit"
                  class="btn btn-primary btn-outline btn-lg w-full group shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 active:translate-y-0"
                >
                  <.icon
                    name="hero-arrow-right-on-rectangle"
                    class="w-5 h-5 mr-2 group-hover:scale-110 transition-transform duration-200"
                  /> Log in only this time
                </button>
              </.form>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end
end
