defmodule WordStashWeb.PageController do
  use WordStashWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
