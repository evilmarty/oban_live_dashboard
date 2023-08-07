System.put_env("PHX_DASHBOARD_TEST", "PHX_DASHBOARD_ENV_VALUE")

Application.put_env(:oban_live_dashboard, Oban.LiveDashboardTest.Endpoint,
  url: [host: "localhost", port: 4000],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  render_errors: [view: Oban.LiveDashboardTest.ErrorView],
  check_origin: false,
  pubsub_server: Oban.LiveDashboardTest.PubSub
)

Application.put_env(:oban_live_dashboard, Oban.LiveDashboardTest.Repo,
  database: System.get_env("SQLITE_DB") || "test.db",
  migration_lock: false
)

defmodule Oban.LiveDashboardTest.Repo do
  use Ecto.Repo, otp_app: :oban_live_dashboard, adapter: Ecto.Adapters.SQLite3
end

_ = Ecto.Adapters.SQLite3.storage_up(Oban.LiveDashboardTest.Repo.config())

defmodule Oban.LiveDashboardTest.ErrorView do
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

defmodule Oban.LiveDashboardTest.Telemetry do
  import Telemetry.Metrics

  def metrics do
    [
      counter("phx.b.c"),
      counter("phx.b.d"),
      counter("ecto.f.g"),
      counter("my_app.h.i")
    ]
  end
end

defmodule Oban.LiveDashboardTest.Router do
  use Phoenix.Router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:fetch_session)
  end

  scope "/", ThisWontBeUsed, as: :this_wont_be_used do
    pipe_through(:browser)

    # Ecto repos will be auto discoverable.
    live_dashboard("/dashboard",
      metrics: Oban.LiveDashboardTest.Telemetry,
      additional_pages: [
        oban: Oban.LiveDashboard
      ]
    )
  end
end

defmodule Oban.LiveDashboardTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :oban_live_dashboard

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger_param_key",
    cookie_key: "request_logger_cookie_key"
  )

  plug(Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"
  )

  plug(Oban.LiveDashboardTest.Router)
end

Supervisor.start_link(
  [
    {Phoenix.PubSub, name: Oban.LiveDashboardTest.PubSub, adapter: Phoenix.PubSub.PG2},
    Oban.LiveDashboardTest.Repo,
    Oban.LiveDashboardTest.Endpoint,
    {Oban, testing: :manual, engine: Oban.Engines.Lite, repo: Oban.LiveDashboardTest.Repo},
    {Ecto.Migrator,
     repos: [Oban.LiveDashboardTest.Repo],
     migrator: fn repo, :up, opts ->
       Ecto.Migrator.run(repo, Path.join([__DIR__, "support", "migrations"]), :up, opts)
     end}
  ],
  strategy: :one_for_one
)

ExUnit.start()
