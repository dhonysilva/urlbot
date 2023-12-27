defmodule Urlbot.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  import Ecto.Changeset
  alias Urlbot.Accounts

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    pow_user_fields()

    # To be removed. It needs to be stored on Account schema
    field :account_name, :string, virtual: true

    belongs_to :account, Urlbot.Accounts.Account

    has_many :account_memberships, Urlbot.Accounts.Membership
    has_many :accounts, through: [:account_memberships, :account]

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> pow_changeset(attrs)
    |> cast(attrs, [:account_name])
    |> validate_required([:account_name])
    |> create_user_account(user)
    |> assoc_constraint(:account)
  end

  defp create_user_account(
         %{valid?: true, changes: %{account_name: account_name}} = changeset,
         %{account_id: nil} = _user
       ) do
    with {:ok, account} <- Accounts.create_account(%{name: account_name}) do
      put_assoc(changeset, :account, account)
    else
      _ -> changeset
    end
  end

  defp create_user_account(changeset, _), do: changeset
end
