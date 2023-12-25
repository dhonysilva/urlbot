defmodule Urlbot.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Urlbot.Accounts` context.
  """

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Urlbot.Accounts.create_account()

    account
  end
end
