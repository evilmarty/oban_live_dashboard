# Oban Live Dashboard

[![CI](https://github.com/evilmarty/oban_live_dashboard/actions/workflows/ci.yml/badge.svg)](https://github.com/evilmarty/oban_live_dashboard/actions/workflows/ci.yml)
[![Hex Version](https://img.shields.io/hexpm/v/oban_live_dashboard.svg)](https://hex.pm/packages/oban_live_dashboard)
[![Hex Docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/oban_live_dashboard)
[![Apache 2.0](https://img.shields.io/hexpm/l/oban_live_dashboard)](https://opensource.org/licenses/Apache-2.0)

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

