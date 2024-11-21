defmodule Oban.LiveDashboard do
  use Phoenix.LiveDashboard.PageBuilder, refresher?: true

  import Phoenix.LiveDashboard.Helpers, only: [format_value: 2]
  import Ecto.Query

  @per_page_limits [20, 50, 100]

  @oban_sorted_job_states [
    "executing",
    "available",
    "scheduled",
    "retryable",
    "cancelled",
    "discarded",
    "completed"
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <h5 class="mb-3">Oban</h5>
    <.live_nav_bar id="oban_states" page={@page} nav_param="job_state" style={:bar} extra_params={["nav"]}>
      <:item :for={{job_state, count} <- @job_state_counts} name={job_state} label={job_state_label(job_state, count)} method="navigate">
        <.live_table id="oban_jobs" limit={per_page_limits()} dom_id={"oban-jobs-#{job_state}"} page={@page} row_attrs={&row_attrs/1} row_fetcher={&fetch_jobs(&1, &2, job_state)} default_sort_by={@timestamp_field} title="" search={false}>
          <:col :let={job} field={:worker} sortable={:desc}>
            <p class="font-weight-bold m-0"><%= job.worker %></p>
            <pre class="font-weight-lighter text-muted m-0"><%= truncate(inspect(job.args)) %></pre>
          </:col>
          <:col :if={job_state == "all"} :let={job} field={:state} sortable={:desc}><%= job_state_label(job.state) %></:col>
          <:col :let={job} field={:attempt} header="Attempt" sortable={:desc}>
            <%= job.attempt %>/<%= job.max_attempts %>
          </:col>
          <:col field={:queue} header="Queue" sortable={:desc} />
          <:col :let={job} field={@timestamp_field} sortable={:desc}>
            <%= format_value(timestamp(job, @timestamp_field)) %>
          </:col>
        </.live_table>
      </:item>
    </.live_nav_bar>

    <.live_modal :if={@job != nil} id="job-modal" title={"Job - #{@job.id}"} return_to={live_dashboard_path(@socket, @page, params: %{})}>
      <div class="mb-4 btn-toolbar" role="toolbar" aria-label="Oban Job actions">
        <div class="btn-group" role="group">
          <button type="button" class="btn btn-primary btn-sm mr-2" phx-click="run_job" phx-value-job={@job.id} disabled={!can_retry_job?(@job)}>Retry Job</button>
        </div>
        <div class="btn-group" role="group">
          <button type="button" class="btn btn-primary btn-sm" phx-click="cancel_job" phx-value-job={@job.id} disabled={!can_cancel_job?(@job)}>Cancel Job</button>
        </div>
      </div>
      <div class="tabular-info">
        <.label_value_list>
          <:elem label="ID"><%= @job.id %></:elem>
          <:elem label="State"><%= @job.state %></:elem>
          <:elem label="Queue"><%= @job.queue %></:elem>
          <:elem label="Worker"><%= @job.worker %></:elem>
          <:elem label="Args"><%= format_value(@job.args, nil) %></:elem>
          <:elem :if={@job.meta != %{}} label="Meta"><%= format_value(@job.meta, nil) %></:elem>
          <:elem :if={@job.tags != []} label="Tags"><%= format_value(@job.tags, nil) %></:elem>
          <:elem :if={@job.errors != []} label="Errors"><%= format_errors(@job.errors) %></:elem>
          <:elem label="Attempts"><%= @job.attempt %>/<%= @job.max_attempts %></:elem>
          <:elem label="Priority"><%= @job.priority %></:elem>
          <:elem label="Attempted at"><%= format_value(@job.attempted_at) %></:elem>
          <:elem :if={@job.cancelled_at} label="Cancelled at"><%= format_value(@job.cancelled_at) %></:elem>
          <:elem :if={@job.completed_at} label="Completed at"><%= format_value(@job.completed_at) %></:elem>
          <:elem :if={@job.discarded_at} label="Discarded at"><%= format_value(@job.discarded_at) %></:elem>
          <:elem label="Inserted at"><%= format_value(@job.inserted_at) %></:elem>
          <:elem label="Scheduled at"><%= format_value(@job.scheduled_at) %></:elem>
        </.label_value_list>
      </div>
    </.live_modal>
    """
  end

  @impl true
  def mount(_params, _, socket) do
    {:ok, socket}
  end

  @impl true
  def menu_link(_, _) do
    {:ok, "Oban"}
  end

  @impl true
  def handle_params(%{"params" => %{"job" => job_id}} = params, _url, socket) do
    socket =
      socket
      |> assign(job_state: Map.get(params, "job_state", "executing"))
      |> assign(sort_by: Map.get(params, "job_state"))
      |> assign(job: nil)
      |> assign_job_state_counts()
      |> assign_timestamp_field()

    case fetch_job(job_id) do
      {:ok, job} ->
        {:noreply, assign(socket, job: job)}

      :error ->
        to = live_dashboard_path(socket, socket.assigns.page, params: %{})
        {:noreply, push_patch(socket, to: to)}
    end
  end

  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(job_state: Map.get(params, "job_state", "executing"))
      |> assign(sort_by: Map.get(params, "job_state"))
      |> assign(job: nil)
      |> assign_job_state_counts()
      |> assign_timestamp_field()

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_job", params, socket) do
    to = live_dashboard_path(socket, socket.assigns.page, params: params)
    {:noreply, push_patch(socket, to: to)}
  end

  def handle_event("run_job", %{"job" => job_id}, socket) do
    with {:ok, job} <- fetch_job(job_id),
         :ok <- Oban.Engine.retry_job(Oban.config(), job),
         # Refresh job
         {:ok, job} <- fetch_job(job.id) do
      {:noreply, assign(socket, :job, job)}
    else
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("cancel_job", %{"job" => job_id}, socket) do
    with {:ok, job} <- fetch_job(job_id),
         :ok <- Oban.Engine.cancel_job(Oban.config(), job) do
      to = live_dashboard_path(socket, socket.assigns.page, params: %{})
      {:noreply, push_patch(socket, to: to)}
    else
      _ ->
        {:noreply, socket}
    end
  end

  defp get_job(id) do
    Oban.Repo.get(Oban.config(), Oban.Job, id)
  end

  @impl true
  def handle_refresh(socket) do
    {:noreply,
     socket
     |> assign_job_state_counts()
     |> Phoenix.Component.update(:job, fn
       nil -> nil
       %{id: job_id} -> get_job(job_id)
     end)}
  end

  defp assign_job_state_counts(socket) do
    job_state_counts_in_db =
      Oban.Repo.all(
        Oban.config(),
        Oban.Job
        |> group_by([j], [j.state])
        |> order_by([j], [j.state])
        |> select([j], {j.state, count(j.id)})
      )
      |> Enum.into(%{})

    job_state_counts =
      for job_state <- @oban_sorted_job_states,
          do: {job_state, Map.get(job_state_counts_in_db, job_state, 0)}

    total_count = Keyword.values(job_state_counts) |> Enum.sum()
    job_state_counts = [{"all", total_count} | job_state_counts]

    assign(socket, job_state_counts: job_state_counts)
  end

  defp job_state_label(job_state, count) do
    "#{job_state_label(job_state)} (#{count})"
  end

  defp job_state_label(job_state) do
    Phoenix.Naming.humanize(job_state)
  end

  defp fetch_jobs(params, _node, job_state) do
    total_jobs = Oban.Repo.aggregate(Oban.config(), jobs_count_query(job_state), :count)

    jobs =
      Oban.Repo.all(Oban.config(), jobs_query(params, job_state)) |> Enum.map(&Map.from_struct/1)

    {jobs, total_jobs}
  end

  defp fetch_job(id) do
    case Oban.Repo.get(Oban.config(), Oban.Job, id) do
      %Oban.Job{} = job ->
        {:ok, job}

      _ ->
        :error
    end
  end

  defp can_retry_job?(%Oban.Job{state: state}), do: state not in ["available", "executing"]

  defp can_cancel_job?(%Oban.Job{state: state}), do: state != "cancelled"

  defp jobs_query(%{sort_by: sort_by, sort_dir: sort_dir, limit: limit}, "all") do
    Oban.Job
    |> limit(^limit)
    |> order_by({^sort_dir, ^sort_by})
  end

  defp jobs_query(params, job_state) do
    Oban.Job
    |> filter_by_job_state(job_state)
    |> filter_by_params(params)
  end

  defp jobs_count_query("all") do
    Oban.Job
  end

  defp jobs_count_query(job_state) do
    filter_by_job_state(Oban.Job, job_state)
  end

  defp filter_by_params(queryable, %{sort_by: sort_by, sort_dir: sort_dir, limit: limit}) do
    queryable
    |> limit(^limit)
    |> order_by({^sort_dir, ^sort_by})
  end

  defp filter_by_job_state(queryable, job_state) do
    where(queryable, [job], job.state == ^job_state)
  end

  defp row_attrs(job) do
    [
      {"phx-click", "show_job"},
      {"phx-value-job", job[:id]},
      {"phx-page-loading", true}
    ]
  end

  defp format_errors(errors) do
    Enum.map(errors, &Map.get(&1, "error"))
  end

  defp format_value(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end

  defp format_value(value), do: value

  defp timestamp(job, timestamp_field) do
    Map.get(job, timestamp_field)
  end

  defp assign_timestamp_field(%{assigns: %{job_state: job_state}} = socket) do
    timestamp_field =
      case job_state do
        "available" -> :scheduled_at
        "cancelled" -> :cancelled_at
        "completed" -> :completed_at
        "discarded" -> :discarded_at
        "executing" -> :attempted_at
        "retryable" -> :scheduled_at
        "scheduled" -> :scheduled_at
        _ -> :inserted_at
      end

    assign(socket, timestamp_field: timestamp_field)
  end

  defp truncate(string, max_length \\ 50) do
    if String.length(string) > max_length do
      String.slice(string, 0, max_length) <> "…"
    else
      string
    end
  end

  defp per_page_limits, do: @per_page_limits
end
