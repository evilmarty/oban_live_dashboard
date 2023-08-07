# Oban Live Dashboard

A simple [Phoenix Live Dashboard](https://github.com/phoenixframework/phoenix_live_dashboard) for [Oban](https://github.com/sorentwo/oban) jobs.

## Installation

Follow these steps to get going.

### 1. Add the `oban_live_dashboard` dependency

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `oban_live_dashboard` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:oban_live_dashboard, "~> 0.1.0"}
  ]
end
```

### 2. Update LiveView router

Next you'll need to update the `live_dashboard` configuration in your router.

```elixir
# lib/my_app_web/router.ex
live_dashboard "/dashboard",
  additional_pages: [
    oban: Oban.LiveDashboard
  ]
```

Then restart the server and access `/dashboard/oban`.

