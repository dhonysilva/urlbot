defmodule Plausible.Sites do
  @moduledoc """
  Accounts context functions.
  """

  import Ecto.Query

  alias Urlbot.Users.User
  alias Urlbot.Repo
  alias Urlbot.Accounts.Account

  @type list_opt() :: {:filter_by_domain, String.t()}

  def get_by_name(name) do
    Repo.get_by(Account, name: name)
  end

  def get_by_name!(name) do
    Repo.get_by!(Account, name: name)
  end

  def create(user, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:account, Account.new(params))
    |> Ecto.Multi.insert(:account_membership, fn %{account: account} ->
      Urlbot.Accounts.Membership.new(account, user)
    end)
    |> Repo.transaction()
  end
end
