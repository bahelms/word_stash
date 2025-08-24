defmodule WordStashWeb.WelcomeLive do
  use WordStashWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen">
      <div class="text-center">
        <h1 class="text-4xl font-bold text-gray-800 mb-4">Welcome to Word Stash</h1>
        <p class="text-xl text-gray-600 mb-6">Hello, {@current_scope.user.email}!</p>
        <div class="space-y-4">
          <a
            href="/users/settings"
            class="inline-block bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Account Settings
          </a>
          <br />
          <.link
            method="delete"
            href="/logout"
            class="inline-block bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded cursor-pointer"
          >
            Log Out
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
