defmodule WordStashWeb.UserLive.Settings do
  use WordStashWeb, :live_view

  on_mount {WordStashWeb.UserAuth, :require_sudo_mode}

  alias WordStash.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-100 via-base-200 to-base-300">
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
      
    <!-- Flash Messages -->
      <.flash kind={:error} flash={@flash} />
      
    <!-- Main Content -->
      <main class="flex items-center justify-center p-4 sm:p-6 lg:p-8 flex-1 mt-20 sm:mt-20 lg:mt-24">
        <div class="w-full max-w-2xl">
          <div class="card bg-base-100 shadow-2xl border border-base-300 overflow-hidden backdrop-blur-sm">
            <div class="card-body p-6 sm:p-8 lg:p-12">
              
    <!-- Page Header -->
              <div class="text-center mb-8">
                <h1 class="text-2xl sm:text-3xl font-bold text-base-content mb-2">
                  Account Settings
                </h1>
                <p class="text-base-content/70">
                  Manage your account email address and password settings
                </p>
              </div>
              
    <!-- Email Update Form -->
              <div class="mb-8">
                <h2 class="text-xl font-semibold text-base-content mb-4">Update Email</h2>
                <.form
                  for={@email_form}
                  id="email_form"
                  phx-submit="update_email"
                  phx-change="validate_email"
                  class="space-y-4"
                >
                  <div class="form-control">
                    <.input
                      field={@email_form[:email]}
                      type="email"
                      label="Email"
                      autocomplete="username"
                      class="input input-bordered w-full focus:input-primary transition-colors duration-200"
                      required
                    />
                  </div>
                  <button
                    type="submit"
                    class="btn btn-primary btn-lg w-full group shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 active:translate-y-0"
                    phx-disable-with="Changing..."
                  >
                    <.icon
                      name="hero-envelope"
                      class="w-5 h-5 mr-2 group-hover:scale-110 transition-transform duration-200"
                    /> Change Email
                  </button>
                </.form>
              </div>
              
    <!-- Divider -->
              <div class="divider my-8">or</div>
              
    <!-- Password Update Form -->
              <div>
                <h2 class="text-xl font-semibold text-base-content mb-4">Update Password</h2>
                <.form
                  for={@password_form}
                  id="password_form"
                  action={~p"/users/update-password"}
                  method="post"
                  phx-change="validate_password"
                  phx-submit="update_password"
                  phx-trigger-action={@trigger_submit}
                  class="space-y-4"
                >
                  <input
                    name={@password_form[:email].name}
                    type="hidden"
                    id="hidden_user_email"
                    autocomplete="username"
                    value={@current_email}
                  />

                  <div class="form-control">
                    <.input
                      field={@password_form[:password]}
                      type="password"
                      label="New password"
                      autocomplete="new-password"
                      class="input input-bordered w-full focus:input-primary transition-colors duration-200"
                      required
                    />
                  </div>

                  <div class="form-control">
                    <.input
                      field={@password_form[:password_confirmation]}
                      type="password"
                      label="Confirm new password"
                      autocomplete="new-password"
                      class="input input-bordered w-full focus:input-primary transition-colors duration-200"
                      required
                    />
                  </div>

                  <button
                    type="submit"
                    class="btn btn-primary btn-lg w-full group shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 active:translate-y-0"
                    phx-disable-with="Saving..."
                  >
                    <.icon
                      name="hero-key"
                      class="w-5 h-5 mr-2 group-hover:scale-110 transition-transform duration-200"
                    /> Save Password
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

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
