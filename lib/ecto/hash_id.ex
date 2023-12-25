defmodule Urlbot.Ecto.HashId do
  @behaviour Ecto.Type
  @hash_id_length 8

  # Called when creating an Ecto.Changeset
  @spec cast(any) :: Map.t()
  def cast(value), do: hash_id_format(value)

  # Accepts a value that has been directly placed into the ecto struct after a changeset
  @spec dump(any) :: Map.t()
  def dump(value), do: hash_id_format(value)

  # Changes a value from the default type into the HashId type
  @spec load(any) :: Map.t()
  def load(value), do: hash_id_format(value)

  # A callback invoked by autogenerate fields
  @spec autogenerate() :: String.t()
  def autogenerate, do: generate()

  # The Ecto type that is being converted
  def type, do: :string

  @spec hash_id_format(any) :: Map.t()
  def hash_id_format(value) do
    case validate_hash_id(value) do
      true -> {:ok, value}
      _ -> {:error, "'#{value}' is not a string"}
    end
  end

  # Validation of given value to be of type "String"
  def validate_hash_id(string) when is_binary(string), do: true
  def validate_hash_id(_other), do: false

  # The function that generates a HashId
  @spec generate() :: String.t()
  def generate do
    @hash_id_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, @hash_id_length)
  end
end
