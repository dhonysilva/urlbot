defmodule UrlbotWeb.Plugs.SetCurrentAccount do
  import Plug.Conn
  alias Urlbot.Repo
  alias Urlbot.Users.User

  def init(options), do: options

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{} = user ->
        %User{account: account} = Repo.preload(user, :account)
        assign(conn, :current_account, account)

      _ ->
        assign(conn, :current_account, nil)
    end
  end
end
