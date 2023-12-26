defmodule UrlbotWeb.RedirectController do
  use UrlbotWeb, :controller

  alias Urlbot.Links

  def show(conn, %{"id" => id}) do
    short_url = Links.get_short_url_link!(id)
    Links.increment_visits(short_url)
    redirect(conn, external: short_url.url)
  end
end
