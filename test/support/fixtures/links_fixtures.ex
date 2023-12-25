defmodule Urlbot.LinksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Urlbot.Links` context.
  """

  @doc """
  Generate a link.
  """
  def link_fixture(attrs \\ %{}) do
    {:ok, link} =
      attrs
      |> Enum.into(%{
        url: "some url",
        visits: 42
      })
      |> Urlbot.Links.create_link()

    link
  end
end
