defmodule OrbitalDynamics.MissionPlan do
  @moduledoc """
  First-class mission timeline that compiles into existing propagation scenarios.

  This is intentionally a thin planning layer. Dynamics-relevant activities
  become maneuvers; other activities stay attached as scenario metadata so
  future scheduling, comms, and operations tooling can reason about them.
  """

  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.MissionPlan.Activity
  alias OrbitalDynamics.{CentralBody, Epoch, Scenario, Spacecraft, StateVector, Timeline}

  @enforce_keys [:id, :spacecraft, :initial_state, :horizon_s, :output_step_s, :central_body]
  defstruct [
    :id,
    :spacecraft,
    :initial_state,
    :horizon_s,
    :output_step_s,
    :central_body,
    activities: [],
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          spacecraft: Spacecraft.t(),
          initial_state: StateVector.t(),
          horizon_s: number(),
          output_step_s: number(),
          central_body: CentralBody.t(),
          activities: [Activity.t()],
          metadata: map()
        }

  def new!(id, %Spacecraft{} = spacecraft, %StateVector{} = initial_state, opts \\ []) do
    horizon_s = Keyword.fetch!(opts, :horizon_s)
    output_step_s = Keyword.get(opts, :output_step_s, horizon_s)
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())
    activities = Keyword.get(opts, :activities, [])
    metadata = Keyword.get(opts, :metadata, %{})

    plan = %__MODULE__{
      id: id,
      spacecraft: spacecraft,
      initial_state: initial_state,
      horizon_s: horizon_s,
      output_step_s: output_step_s,
      central_body: central_body,
      activities: activities,
      metadata: metadata
    }

    case validate(plan) do
      :ok -> plan
      {:error, reason} -> raise ArgumentError, Exception.message(reason_to_exception(reason))
    end
  end

  def to_scenario(%__MODULE__{} = plan) do
    with :ok <- validate(plan) do
      {:ok, compile!(plan)}
    end
  end

  def to_scenario!(%__MODULE__{} = plan) do
    case to_scenario(plan) do
      {:ok, scenario} -> scenario
      {:error, reason} -> raise ArgumentError, Exception.message(reason_to_exception(reason))
    end
  end

  def validate(%__MODULE__{} = plan) do
    cond do
      plan.id in [nil, ""] ->
        {:error, {:invalid_plan, :id}}

      not positive_number?(plan.horizon_s) ->
        {:error, {:invalid_plan, :horizon_s}}

      not positive_number?(plan.output_step_s) ->
        {:error, {:invalid_plan, :output_step_s}}

      not match?(%CentralBody{}, plan.central_body) ->
        {:error, {:invalid_plan, :central_body}}

      not is_map(plan.metadata) ->
        {:error, {:invalid_plan, :metadata}}

      not Enum.all?(plan.activities, &match?(%Activity{}, &1)) ->
        {:error, {:invalid_plan, :activities}}

      true ->
        with :ok <- validate_activity_scope(plan),
             :ok <- validate_activity_bounds(plan),
             :ok <- validate_activity_overlaps(plan.activities),
             :ok <- validate_activity_integrity(plan.activities) do
          :ok
        end
    end
  end

  defp compile!(%__MODULE__{} = plan) do
    Scenario.new!(plan.id, plan.spacecraft, plan.initial_state,
      duration_s: plan.horizon_s,
      output_step_s: plan.output_step_s,
      central_body: plan.central_body,
      maneuvers: maneuvers(plan),
      metadata: metadata(plan)
    )
  end

  defp maneuvers(%__MODULE__{} = plan) do
    plan.activities
    |> Enum.filter(&(&1.type == :impulsive_burn))
    |> Enum.map(fn activity ->
      ImpulsiveBurn.new!(
        activity.id,
        Epoch.shift(plan.initial_state.epoch, activity.epoch_s),
        activity.delta_v_km_s,
        activity.frame || plan.initial_state.frame
      )
    end)
  end

  defp metadata(%__MODULE__{} = plan) do
    %{
      mission_plan: %{
        id: plan.id,
        horizon_s: plan.horizon_s,
        output_step_s: plan.output_step_s,
        activity_count: length(plan.activities),
        activities: Enum.map(plan.activities, &scoped_activity_map(plan, &1)),
        non_dynamics_activities:
          plan.activities
          |> Enum.reject(&(&1.type == :impulsive_burn))
          |> Enum.map(&scoped_activity_map(plan, &1)),
        metadata: plan.metadata
      }
    }
  end

  defp scoped_activity_map(%__MODULE__{} = plan, %Activity{} = activity) do
    activity
    |> Activity.to_map()
    |> Map.put(:scenario_id, activity.scenario_id || plan.id)
    |> Map.put(:spacecraft_id, activity.spacecraft_id || plan.spacecraft.id)
  end

  defp validate_activity_scope(%__MODULE__{} = plan) do
    case Enum.find(plan.activities, &activity_scope_conflict?(&1, plan)) do
      nil -> :ok
      activity -> {:error, {:activity_scope_conflict, activity.id}}
    end
  end

  defp activity_scope_conflict?(%Activity{} = activity, %__MODULE__{} = plan) do
    not scope_matches?(activity.scenario_id, plan.id) or
      not scope_matches?(activity.spacecraft_id, plan.spacecraft.id)
  end

  defp scope_matches?(nil, _expected), do: true
  defp scope_matches?(value, expected), do: to_string(value) == to_string(expected)

  defp validate_activity_bounds(%__MODULE__{} = plan) do
    case Enum.find(plan.activities, &outside_horizon?(&1, plan.horizon_s)) do
      nil -> :ok
      activity -> {:error, {:activity_outside_horizon, activity.id}}
    end
  end

  defp outside_horizon?(%Activity{} = activity, horizon_s) do
    {start_s, end_s} = Activity.interval(activity)
    start_s < 0 or end_s > horizon_s
  end

  defp validate_activity_overlaps(activities) do
    activities
    |> overlapping_pair()
    |> case do
      nil -> :ok
      {left, right} -> {:error, {:overlapping_activities, left.id, right.id}}
    end
  end

  defp overlapping_pair(activities) do
    sorted = Enum.sort_by(activities, fn activity -> Activity.interval(activity) end)

    sorted
    |> Enum.with_index()
    |> Enum.find_value(fn {activity, index} ->
      sorted
      |> Enum.drop(index + 1)
      |> Enum.find(&overlap_not_allowed?(activity, &1))
      |> case do
        nil -> nil
        other -> {activity, other}
      end
    end)
  end

  defp overlap_not_allowed?(%Activity{} = left, %Activity{} = right) do
    overlaps?(left, right) and not (left.allow_overlap? or right.allow_overlap?)
  end

  defp validate_activity_integrity(activities) do
    report =
      activities
      |> Timeline.integrity_report(validate_missing_dependencies?: true)

    review_rows = Map.get(report, "rows", [])

    case List.first(review_rows) do
      nil ->
        :ok

      row ->
        {:error,
         {:activity_timeline_integrity, row["activity_id"],
          Map.get(row, "timeline_integrity_issue_types", [])}}
    end
  end

  defp overlaps?(%Activity{} = left, %Activity{} = right) do
    {left_start, left_end} = Activity.interval(left)
    {right_start, right_end} = Activity.interval(right)

    left_start < right_end and right_start < left_end
  end

  defp reason_to_exception(reason), do: %ArgumentError{message: inspect(reason)}
  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
end
