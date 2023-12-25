defmodule Urlbot.Repo do
  use Ecto.Repo,
    otp_app: :urlbot,
    adapter: Ecto.Adapters.Postgres
end
