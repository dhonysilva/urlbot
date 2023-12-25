defmodule UrlbotWeb.RedirectController do
  use UrlbotWeb, :controller

  alias Urlbot.Links

  def show(conn, %{"id" => id}) do
    shor_url = Links.get_short_url!(id)
    Links.increment_visits(shor_url)
    redirect(conn, external: shor_url.url)
  end
end
