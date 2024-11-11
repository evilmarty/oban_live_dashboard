defmodule Oban.LiveDashboardTest do
  use ExUnit.Case, async: true
  # use Oban.Testing, repo: Oban.LiveDashboardTest.Repo, prefix: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint Oban.LiveDashboardTest.Endpoint

  test "menu_link/2" do
    assert {:ok, "Oban"} = Oban.LiveDashboard.menu_link(nil, nil)
  end

  test "shows jobs with limit" do
    for _ <- 1..110, do: job_fixture()
    {:ok, live, rendered} = live(build_conn(), "/dashboard/oban")

    assert rendered |> :binary.matches("<td class=\"oban-jobs-all-worker\"") |> length() ==
             20

    rendered = render_patch(live, "/dashboard/oban?limit=100")

    assert rendered |> :binary.matches("<td class=\"oban-jobs-all-worker\"") |> length() ==
             100
  end

  test "switch between states" do
    Oban.LiveDashboardTest.Repo.delete_all(Oban.Job)
    _executing_job = job_fixture(%{"foo" => "executing"}, "executing")
    _completed_job = job_fixture(%{"foo" => "completed"}, "completed")

    conn = build_conn()
    {:ok, live, rendered} = live(conn, "/dashboard/oban")

    assert rendered |> :binary.matches("<td class=\"oban-jobs-all-worker\"") |> length() == 2

    {:ok, live, rendered} =
      live
      |> element("a", "executing - (1)")
      |> render_click()
      |> follow_redirect(conn)

    assert rendered
           |> :binary.matches("<td class=\"oban-jobs-executing-worker\"")
           |> length() == 1

    {:ok, live, rendered} =
      live
      |> element("a", "completed - (1)")
      |> render_click()
      |> follow_redirect(conn)

    assert rendered
           |> :binary.matches("<td class=\"oban-jobs-completed-worker\"")
           |> length() == 1

    {:ok, _live, rendered} =
      live
      |> element("a", "scheduled - (0)")
      |> render_click()
      |> follow_redirect(conn)

    assert rendered
           |> :binary.matches("<td class=\"oban-jobs-scheduled-worker\"")
           |> length() == 0
  end

  test "shows job info modal" do
    job = job_fixture(%{something: "foobar"})
    {:ok, live, _rendered} = live(build_conn(), "/dashboard/oban?params[job]=#{job.id}")
    rendered = render(live)
    assert rendered =~ "modal-content"
    assert rendered =~ "%{&quot;something&quot; =&gt; &quot;foobar&quot;}"
    refute live |> element("#modal-close") |> render_click() =~ "modal"
  end

  defp job_fixture(args \\ %{}, opts \\ []) do
    opts  = Keyword.put(opts, :worker, "FakeWorker")
    {:ok, job} = Oban.Job.new(args, opts) |> Oban.insert()

    job
  end
end
