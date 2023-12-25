defmodule UrlbotWeb.LinkController do
  use UrlbotWeb, :controller

  alias Urlbot.Links
  alias Urlbot.Links.Link

  def index(conn, _params) do
    current_account = conn.assigns.current_account
    links = Links.list_links(current_account)
    render(conn, :index, links: links)
  end

  def new(conn, _params) do
    changeset = Links.change_link(%Link{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"link" => link_params}) do
    current_account = conn.assigns.current_account

    case Links.create_link(current_account, link_params) do
      {:ok, link} ->
        conn
        |> put_flash(:info, "Link created successfully.")
        |> redirect(to: ~p"/links/#{link}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    current_account = conn.assigns.current_account
    link = Links.get_link!(current_account, id)
    render(conn, :show, link: link)
  end

  def edit(conn, %{"id" => id}) do
    current_account = conn.assigns.current_account
    link = Links.get_link!(current_account, id)
    changeset = Links.change_link(link)
    render(conn, :edit, link: link, changeset: changeset)
  end

  def update(conn, %{"id" => id, "link" => link_params}) do
    current_account = conn.assigns.current_account

    link = Links.get_link!(current_account, id)

    case Links.update_link(link, link_params) do
      {:ok, link} ->
        conn
        |> put_flash(:info, "Link updated successfully.")
        |> redirect(to: ~p"/links/#{link}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, link: link, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    current_account = conn.assigns.current_account
    link = Links.get_link!(current_account, id)
    {:ok, _link} = Links.delete_link(link)

    conn
    |> put_flash(:info, "Link deleted successfully.")
    |> redirect(to: ~p"/links")
  end
end
