defmodule Urlbot.Accounts.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  @roles [:owner, :admin, :viewer]

  @type t() :: %__MODULE__{}

  # Generate a union type for roles
  @type role() :: unquote(Enum.reduce(@roles, &{:|, [], [&1, &2]}))

  schema "account_memberships" do
    field :role, Ecto.Enum, values: @roles
    belongs_to :account, Urlbot.Accounts.Account
    belongs_to :user, Urlbot.Users.User

    timestamps()
  end

  def new(account, user) do
    %__MODULE__{}
    |> change()
    |> put_assoc(:account, account)
    |> put_assoc(:user, user)
  end

  def set_role(changeset, role) do
    changeset
    |> cast(%{role: role}, [:role])
  end
end
