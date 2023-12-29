defmodule Urlbot.Accounts.Account do
  @moduledoc """
  Account schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :name, :string

    many_to_many :members, Urlbot.Users.User, join_through: Urlbot.Accounts.Membership
    has_many :memberships, Urlbot.Accounts.Membership

    has_one :ownership, Urlbot.Accounts.Membership, where: [role: :owner]
    has_one :owner, through: [:ownership, :user]

    # has_many :users, Urlbot.Users.User
    has_many :links, Urlbot.Links.Link

    timestamps()
  end

  def new(params), do: changeset(%__MODULE__{}, params)

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
