defmodule Urlbot.Repo.Migrations.CreateAccountMemberships do
  use Ecto.Migration

  def change do
    create table(:account_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id)
      add :account_id, references(:accounts, type: :binary_id)
    end

    create unique_index(:account_memberships, [:user_id, :account_id])
  end
end
