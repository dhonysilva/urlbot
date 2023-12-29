defmodule UrlbotWeb.Router do
  use UrlbotWeb, :router
  use Pow.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UrlbotWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :app_layout do
    plug :put_root_layout, html: {UrlbotWeb.LayoutView, :app}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated, error_handler: Pow.Phoenix.PlugErrorHandler
    plug UrlbotWeb.Plugs.SetCurrentAccount
  end

  scope "/", UrlbotWeb do
    pipe_through [:protected, :browser]

    resources "/links", LinkController
  end

  scope "/" do
    pipe_through :browser

    pow_routes()
  end

  scope "/", UrlbotWeb do
    pipe_through :browser

    get "/", PageController, :home

    get "/links/:id", RedirectController, :show

    scope alias: Live, assigns: %{connect_live_socket: true} do
      pipe_through [:app_layout, UrlbotWeb.RequireAccountPlug]

      live "/accounts", Accounts, :index, as: :account
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", UrlbotWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:urlbot, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: UrlbotWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
