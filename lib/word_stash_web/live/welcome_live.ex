defmodule WordStashWeb.WelcomeLive do
  use WordStashWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen">
      <div class="text-center">
        <h1 class="text-4xl font-bold text-white-800">Welcome to Word Stash</h1>
      </div>
    </div>
    """
  end
end
