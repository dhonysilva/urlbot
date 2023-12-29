defmodule UrlbotWeb.Live.Accounts do
  @moduledoc """
  LiveView for accounts index.
  """

  use Phoenix.LiveView, global_prefixes: ~w(x-)
  use UrlbotWeb.Live.Flash

  alias Phoenix.LiveView.JS
  use Phoenix.HTML

  alias Urlbot.Users.User
  alias Urlbot.Repo
  alias Urlbot.Accounts.Account
  alias Urlbot.Accounts.Accounts
  alias UrlbotWeb.Router.Helpers, as: Routes

  def mount(params, %{"current_user_id" => user_id}, socket) do
    uri =
      ("/accounts?" <> URI.encode_query(Map.take(params, ["filter_text"])))
      |> URI.new!()

    socket =
      socket
      |> assign(:uri, uri)
      |> assign(:filter_text, params["filter_text"] || "")
      |> assign(:user, Repo.get!(Auth.User, user_id))

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> load_sites()
      |> assign_new(:has_sites?, fn %{user: user} ->
        Urlbot.Accounts.Membership.any_or_pending?(user)
      end)
      |> assign_new(:needs_to_upgrade, fn %{user: user, sites: sites} ->
        user_owns_sites =
          Enum.any?(sites.entries, fn site ->
            List.first(site.memberships ++ site.invitations).role == :owner
          end) ||
            Auth.user_owns_sites?(user)

        user_owns_sites && Urlbot.Billing.check_needs_to_upgrade(user)
      end)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.flash_messages flash={@flash} />
    <div
      x-data={"{selectedInvitation: null, invitationOpen: false, invitations: #{Enum.map(@invitations, &({&1.invitation.invitation_id, &1})) |> Enum.into(%{}) |> Jason.encode!}}"}
      x-on:keydown.escape.window="invitationOpen = false"
      class="container pt-6"
    >
      <UrlbotWeb.Live.Components.Visitors.gradient_defs />
      <.upgrade_nag_screen :if={@needs_to_upgrade == {:needs_to_upgrade, :no_active_subscription}} />

      <div class="mt-6 pb-5 border-b border-gray-200 dark:border-gray-500 flex items-center justify-between">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 dark:text-gray-100 sm:text-3xl sm:leading-9 sm:truncate flex-shrink-0">
          My Sites
        </h2>
      </div>

      <div class="border-t border-gray-200 pt-4 sm:flex sm:items-center sm:justify-between">
        <.search_form :if={@has_sites?} filter_text={@filter_text} uri={@uri} />
        <p :if={not @has_sites?} class="dark:text-gray-100">
          You don't have any sites yet.
        </p>
        <div class="mt-4 flex sm:ml-4 sm:mt-0">
          <a href="/sites/new" class="button">
            + Add Account
          </a>
        </div>
      </div>

      <p
        :if={String.trim(@filter_text) != "" and @acounts.entries == []}
        class="mt-4 dark:text-gray-100"
      >
        No sites found. Please search for something else.
      </p>

      <div :if={@has_sites?}>
        <%!-- <ul class="my-6 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          <%= for account <- @accounts.entries do %>
            <.account
              :if={site.entry_type in ["pinned_site", "site"]}
              site={site}
              hourly_stats={@hourly_stats[site.domain]}
            />
            <.invitation
              :if={site.entry_type == "invitation"}
              site={site}
              invitation={hd(site.invitations)}
              hourly_stats={@hourly_stats[site.domain]}
            />
          <% end %>
        </ul> --%>
      </div>
    </div>
    """
  end

  def upgrade_nag_screen(assigns) do
    ~H"""
    <div class="rounded-md bg-yellow-100 p-4">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg
            class="h-5 w-5 text-yellow-400"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
              clip-rule="evenodd"
            />
          </svg>
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-yellow-800">
            Payment required
          </h3>
          <div class="mt-2 text-sm text-yellow-700">
            <p>
              To access the sites you own, you need to subscribe to a monthly or yearly payment plan. <%= link(
                "Upgrade now →",
                to: "/settings",
                class: "text-sm font-medium text-yellow-800"
              ) %>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :account, Urlbot.Accounts.Account, required: true
  attr :hourly_stats, :map, required: true

  def account(assigns) do
    ~H"""
    <li
      class="group relative hidden"
      id={"site-card-#{hash_domain(@site.domain)}"}
      data-domain={@site.domain}
      data-pin-toggled={
        JS.show(
          transition: {"duration-500", "opacity-0 shadow-2xl -translate-y-6", "opacity-100 shadow"},
          time: 400
        )
      }
      data-pin-failed={
        JS.show(
          transition: {"duration-500", "opacity-0", "opacity-100"},
          time: 200
        )
      }
      phx-mounted={JS.show()}
    >
    </li>
    """
  end

  attr :rest, :global

  def icon_pin(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="16"
      height="16"
      fill="currentColor"
      viewBox="0 0 16 16"
      {@rest}
    >
      <path d="M9.828.722a.5.5 0 0 1 .354.146l4.95 4.95a.5.5 0 0 1 0 .707c-.48.48-1.072.588-1.503.588-.177 0-.335-.018-.46-.039l-3.134 3.134a5.927 5.927 0 0 1 .16 1.013c.046.702-.032 1.687-.72 2.375a.5.5 0 0 1-.707 0l-2.829-2.828-3.182 3.182c-.195.195-1.219.902-1.414.707-.195-.195.512-1.22.707-1.414l3.182-3.182-2.828-2.829a.5.5 0 0 1 0-.707c.688-.688 1.673-.767 2.375-.72a5.922 5.922 0 0 1 1.013.16l3.134-3.133a2.772 2.772 0 0 1-.04-.461c0-.43.108-1.022.589-1.503a.5.5 0 0 1 .353-.146z" />
    </svg>
    """
  end

  attr :hourly_stats, :map, required: true

  def site_stats(assigns) do
    ~H"""
    <div class="md:h-[68px] sm:h-[58px] h-20 pl-8 pr-8 pt-2">
      <div :if={@hourly_stats == :loading} class="text-center animate-pulse">
        <div class="md:h-[34px] sm:h-[30px] h-11 dark:bg-gray-700 bg-gray-100 rounded-md"></div>
        <div class="md:h-[26px] sm:h-[18px] h-6 mt-1 dark:bg-gray-700 bg-gray-100 rounded-md"></div>
      </div>
      <div
        :if={is_map(@hourly_stats)}
        class="hidden h-50px"
        phx-mounted={JS.show(transition: {"ease-in duration-500", "opacity-0", "opacity-100"})}
      >
        <span class="text-gray-600 dark:text-gray-400 text-sm truncate">
          <UrlbotWeb.Live.Components.Visitors.chart intervals={@hourly_stats.intervals} />
          <div class="flex justify-between items-center">
            <p>
              <span class="text-gray-800 dark:text-gray-200">
                <b><%= UrlbotWeb.StatsView.large_number_format(@hourly_stats.visitors) %></b>
                visitor<span :if={@hourly_stats.visitors != 1}>s</span> in last 24h
              </span>
            </p>

            <.percentage_change change={@hourly_stats.change} />
          </div>
        </span>
      </div>
    </div>
    """
  end

  attr :change, :integer, required: true

  def percentage_change(assigns) do
    ~H"""
    <p class="dark:text-gray-100">
      <span :if={@change == 0} class="font-semibold">〰</span>
      <span :if={@change > 0} class="font-semibold text-green-500">↑</span>
      <span :if={@change < 0} class="font-semibold text-red-400">↓</span>
      <%= abs(@change) %>%
    </p>
    """
  end

  attr :filter_text, :string, default: ""
  attr :uri, URI, required: true

  def search_form(assigns) do
    ~H"""
    <form id="filter-form" phx-change="filter" action={@uri} method="GET">
      <div class="text-gray-800 text-sm inline-flex items-center">
        <div class="relative rounded-md flex">
          <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
            <Heroicons.magnifying_glass class="feather mr-1 dark:text-gray-300" />
          </div>
          <input
            type="text"
            name="filter_text"
            id="filter-text"
            phx-debounce={200}
            class="pl-8 dark:bg-gray-900 dark:text-gray-300 focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 dark:border-gray-500 rounded-md dark:bg-gray-800"
            placeholder="Press / to search sites"
            autocomplete="off"
            value={@filter_text}
            x-ref="filter_text"
            x-on:keydown.escape="$refs.filter_text.blur(); $refs.reset_filter?.dispatchEvent(new Event('click', {bubbles: true, cancelable: true}));"
            x-on:keydown.prevent.slash.window="$refs.filter_text.focus(); $refs.filter_text.select();"
            x-on:blur="$refs.filter_text.placeholder = 'Press / to search sites';"
            x-on:focus="$refs.filter_text.placeholder = 'Search sites';"
          />
        </div>

        <button
          :if={String.trim(@filter_text) != ""}
          class="phx-change-loading:hidden ml-2"
          phx-click="reset-filter-text"
          id="reset-filter"
          x-ref="reset_filter"
          type="button"
        >
          <Heroicons.backspace class="feather hover:text-red-500 dark:text-gray-300 dark:hover:text-red-500" />
        </button>
      </div>
    </form>
    """
  end

  def favicon(assigns) do
    src = "/favicon/sources/#{assigns.domain}"
    assigns = assign(assigns, :src, src)

    ~H"""
    <img src={@src} class="w-4 h-4 flex-shrink-0 mt-px" />
    """
  end

  def handle_event("pin-toggle", %{"domain" => domain}, socket) do
    site = Enum.find(socket.assigns.sites.entries, &(&1.domain == domain))

    if site do
      socket =
        case Sites.toggle_pin(socket.assigns.user, site) do
          {:ok, preference} ->
            flash_message =
              if preference.pinned_at do
                "Site pinned"
              else
                "Site unpinned"
              end

            socket
            |> put_live_flash(:success, flash_message)
            |> load_sites()
            |> push_event("js-exec", %{
              to: "#site-card-#{hash_domain(site.domain)}",
              attr: "data-pin-toggled"
            })

          {:error, :too_many_pins} ->
            flash_message =
              "Looks like you've hit the pinned sites limit! " <>
                "Please unpin one of your pinned sites to make room for new pins"

            socket
            |> put_live_flash(:error, flash_message)
            |> push_event("js-exec", %{
              to: "#site-card-#{hash_domain(site.domain)}",
              attr: "data-pin-failed"
            })
        end

      {:noreply, socket}
    else
      Sentry.capture_message("Attempting to toggle pin for invalid domain.",
        extra: %{domain: domain, user: socket.assigns.user.id}
      )

      {:noreply, socket}
    end
  end

  def handle_event(
        "filter",
        %{"filter_text" => filter_text},
        %{assigns: %{filter_text: filter_text}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_event("filter", %{"filter_text" => filter_text}, socket) do
    socket =
      socket
      |> reset_pagination()
      |> set_filter_text(filter_text)

    {:noreply, socket}
  end

  def handle_event("reset-filter-text", _params, socket) do
    socket =
      socket
      |> reset_pagination()
      |> set_filter_text("")

    {:noreply, socket}
  end

  defp load_sites(%{assigns: assigns} = socket) do
    sites =
      Sites.list_with_invitations(assigns.user, assigns.params,
        filter_by_domain: assigns.filter_text
      )

    hourly_stats =
      if connected?(socket) do
        Urlbot.Stats.Clickhouse.last_24h_visitors_hourly_intervals(sites.entries)
      else
        sites.entries
        |> Enum.into(%{}, fn site ->
          {site.domain, :loading}
        end)
      end

    invitations = extract_invitations(sites.entries, assigns.user)

    assign(
      socket,
      sites: sites,
      invitations: invitations,
      hourly_stats: hourly_stats
    )
  end

  defp extract_invitations(sites, user) do
    sites
    |> Enum.filter(&(&1.entry_type == "invitation"))
    |> Enum.flat_map(& &1.invitations)
    |> Enum.map(&check_limits(&1, user))
  end

  defp check_limits(invitation, _), do: %{invitation: invitation}

  defp set_filter_text(socket, filter_text) do
    uri = socket.assigns.uri

    uri_params =
      uri.query
      |> URI.decode_query()
      |> Map.put("filter_text", filter_text)
      |> URI.encode_query()

    uri = %{uri | query: uri_params}

    socket
    |> assign(:filter_text, filter_text)
    |> assign(:uri, uri)
    |> push_patch(to: URI.to_string(uri), replace: true)
  end

  defp reset_pagination(socket) do
    pagination_fields = ["page"]
    uri = socket.assigns.uri

    uri_params =
      uri.query
      |> URI.decode_query()
      |> Map.drop(pagination_fields)
      |> URI.encode_query()

    assign(socket,
      uri: %{uri | query: uri_params},
      params: Map.drop(socket.assigns.params, pagination_fields)
    )
  end

  defp hash_domain(domain) do
    :sha |> :crypto.hash(domain) |> Base.encode16()
  end
end
