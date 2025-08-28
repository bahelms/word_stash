defmodule WordStashWeb.UserLive.Registration do
  use WordStashWeb, :live_view

  alias WordStash.Accounts
  alias WordStash.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-100 via-base-200 to-base-300">
      <.app_header>
        <:actions>
          <.link
            navigate="/login"
            class="btn btn-sm sm:btn-md btn-primary btn-outline"
          >
            <.icon
              name="hero-arrow-right-on-rectangle"
              class="w-4 h-4 sm:w-5 sm:h-5 mr-1 sm:mr-2"
            />
            <span class="hidden sm:inline">Log In</span>
          </.link>
        </:actions>
      </.app_header>
      
    <!-- Main Content -->
      <main class="flex items-center justify-center p-4 sm:p-6 lg:p-8 flex-1 mt-20 sm:mt-20 lg:mt-24">
        <div class="w-full max-w-md">
          <div class="card bg-base-100 shadow-2xl border border-base-300 overflow-hidden backdrop-blur-sm">
            <div class="card-body p-6 sm:p-8 lg:p-10">
              
    <!-- Registration Form -->
              <div class="text-center mb-6">
                <h1 class="text-2xl sm:text-3xl font-bold text-base-content mb-2">
                  Create an account
                </h1>
                <p class="text-base-content/70">
                  Already have an account?
                  <.link navigate={~p"/login"} class="font-semibold text-primary hover:underline">
                    Log in
                  </.link>
                  to your account now.
                </p>
              </div>

              <.form
                for={@form}
                id="registration_form"
                phx-submit="save"
                phx-change="validate"
                class="space-y-4"
              >
                <div class="form-control">
                  <.input
                    field={@form[:email]}
                    type="email"
                    label="Email"
                    autocomplete="username"
                    class="input input-bordered w-full focus:input-primary transition-colors duration-200"
                    required
                    phx-mounted={JS.focus()}
                  />
                </div>

                <div class="form-control">
                  <.input
                    field={@form[:password]}
                    type="password"
                    label="Password"
                    autocomplete="new-password"
                    class="input input-bordered w-full focus:input-primary transition-colors duration-200"
                    required
                  />
                </div>

                <button
                  type="submit"
                  class="btn btn-primary btn-lg w-full group shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 active:translate-y-0"
                  phx-disable-with="Creating account..."
                >
                  <.icon
                    name="hero-user-plus"
                    class="w-5 h-5 mr-2 group-hover:scale-110 transition-transform duration-200"
                  /> Create an account
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
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: WordStashWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = User.registration_changeset(%User{}, %{})

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Account created successfully! You can now log in."
         )
         |> push_navigate(to: ~p"/login")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = User.registration_changeset(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
