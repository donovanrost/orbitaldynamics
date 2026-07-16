defmodule OrbitalDynamics.CampaignPlanner.ActivitySourceRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshSourceInputs,
    PriorActivityContext,
    SourceRowTuples
  }

  alias __MODULE__.OperationalTimelineRows
  alias __MODULE__.PressureRows
  alias __MODULE__.RealizedRows

  def prior_plan_planned_activity_rows_with_source(prior_plan),
    do: prior_plan_planned_activity_rows_with_source(prior_plan, prior_plan_callbacks())

  def prior_plan_planned_activity_rows_with_source(prior_plan, opts) do
    OperationalTimelineRows.prior_plan_planned_activity_rows_with_source(
      prior_plan,
      opts,
      &stringify_keys/1
    )
  end

  def prior_plan_planned_activity_rows(prior_plan),
    do: prior_plan_planned_activity_rows(prior_plan, prior_plan_callbacks())

  def prior_plan_planned_activity_rows(prior_plan, opts) do
    prior_plan
    |> prior_plan_planned_activity_rows_with_source(opts)
    |> SourceRowTuples.rows()
  end

  def mission_state_planned_activity_rows_with_source(mission_state),
    do: mission_state_planned_activity_rows_with_source(mission_state, default_callbacks())

  def mission_state_planned_activity_rows_with_source(mission_state, opts) do
    OperationalTimelineRows.mission_state_planned_activity_rows_with_source(
      mission_state,
      opts,
      &stringify_keys/1
    )
  end

  def mission_state_planned_activity_rows(mission_state),
    do: mission_state_planned_activity_rows(mission_state, default_callbacks())

  def mission_state_planned_activity_rows(mission_state, opts) do
    mission_state
    |> mission_state_planned_activity_rows_with_source(opts)
    |> SourceRowTuples.rows()
  end

  def prior_plan_proposed_contact_rows_with_source(prior_plan),
    do: prior_plan_proposed_contact_rows_with_source(prior_plan, prior_plan_callbacks())

  def prior_plan_proposed_contact_rows_with_source(prior_plan, opts) do
    OperationalTimelineRows.prior_plan_proposed_contact_rows_with_source(
      prior_plan,
      opts,
      &stringify_keys/1
    )
  end

  def prior_plan_proposed_contact_rows(prior_plan),
    do: prior_plan_proposed_contact_rows(prior_plan, prior_plan_callbacks())

  def prior_plan_proposed_contact_rows(prior_plan, opts) do
    prior_plan
    |> prior_plan_proposed_contact_rows_with_source(opts)
    |> SourceRowTuples.rows()
  end

  def mission_state_proposed_contact_rows_with_source(mission_state),
    do: mission_state_proposed_contact_rows_with_source(mission_state, default_callbacks())

  def mission_state_proposed_contact_rows_with_source(mission_state, opts) do
    OperationalTimelineRows.mission_state_proposed_contact_rows_with_source(
      mission_state,
      opts,
      &stringify_keys/1
    )
  end

  def mission_state_proposed_contact_rows(mission_state),
    do: mission_state_proposed_contact_rows(mission_state, default_callbacks())

  def mission_state_proposed_contact_rows(mission_state, opts) do
    mission_state
    |> mission_state_proposed_contact_rows_with_source(opts)
    |> SourceRowTuples.rows()
  end

  def prior_plan_planned_activity_pressure_rows_with_source(prior_plan),
    do: prior_plan_planned_activity_pressure_rows_with_source(prior_plan, prior_plan_callbacks())

  def prior_plan_planned_activity_pressure_rows_with_source(prior_plan, opts) do
    prior_plan
    |> prior_plan_planned_activity_rows_with_source(opts)
    |> PressureRows.operational_timeline_pressure_rows_with_source()
  end

  def mission_state_planned_activity_pressure_rows_with_source(mission_state),
    do:
      mission_state_planned_activity_pressure_rows_with_source(
        mission_state,
        default_callbacks()
      )

  def mission_state_planned_activity_pressure_rows_with_source(mission_state, opts) do
    mission_state
    |> mission_state_planned_activity_rows_with_source(opts)
    |> PressureRows.operational_timeline_pressure_rows_with_source()
  end

  def prior_plan_proposed_contact_pressure_rows_with_source(prior_plan),
    do: prior_plan_proposed_contact_pressure_rows_with_source(prior_plan, prior_plan_callbacks())

  def prior_plan_proposed_contact_pressure_rows_with_source(prior_plan, opts) do
    prior_plan
    |> prior_plan_proposed_contact_rows_with_source(opts)
    |> PressureRows.operational_timeline_pressure_rows_with_source()
  end

  def mission_state_proposed_contact_pressure_rows_with_source(mission_state),
    do:
      mission_state_proposed_contact_pressure_rows_with_source(
        mission_state,
        default_callbacks()
      )

  def mission_state_proposed_contact_pressure_rows_with_source(mission_state, opts) do
    mission_state
    |> mission_state_proposed_contact_rows_with_source(opts)
    |> PressureRows.operational_timeline_pressure_rows_with_source()
  end

  def prior_plan_realized_activity_rows_with_source(prior_plan),
    do: prior_plan_realized_activity_rows_with_source(prior_plan, prior_plan_callbacks())

  def prior_plan_realized_activity_rows_with_source(prior_plan, opts) do
    RealizedRows.prior_plan_realized_activity_rows_with_source(
      prior_plan,
      opts,
      &stringify_keys/1
    )
  end

  def prior_plan_realized_activity_rows(prior_plan),
    do: prior_plan_realized_activity_rows(prior_plan, prior_plan_callbacks())

  def prior_plan_realized_activity_rows(prior_plan, opts) do
    prior_plan
    |> prior_plan_realized_activity_rows_with_source(opts)
    |> SourceRowTuples.rows()
  end

  def prior_plan_realized_activity_pressure_rows_with_source(prior_plan),
    do: prior_plan_realized_activity_pressure_rows_with_source(prior_plan, prior_plan_callbacks())

  def prior_plan_realized_activity_pressure_rows_with_source(prior_plan, opts) do
    prior_plan
    |> prior_plan_realized_activity_rows_with_source(opts)
    |> PressureRows.realized_activity_pressure_rows_with_source()
  end

  def mission_state_realized_activity_rows_with_source(mission_state, prior_plan),
    do:
      mission_state_realized_activity_rows_with_source(
        mission_state,
        prior_plan,
        default_callbacks()
      )

  def mission_state_realized_activity_rows_with_source(mission_state, prior_plan, opts) do
    RealizedRows.mission_state_realized_activity_rows_with_source(
      mission_state,
      prior_plan,
      opts,
      &stringify_keys/1
    )
  end

  def mission_state_realized_activity_rows(mission_state, prior_plan),
    do: mission_state_realized_activity_rows(mission_state, prior_plan, default_callbacks())

  def mission_state_realized_activity_rows(mission_state, prior_plan, opts) do
    mission_state
    |> mission_state_realized_activity_rows_with_source(prior_plan, opts)
    |> SourceRowTuples.rows()
  end

  def mission_state_realized_activity_pressure_rows_with_source(mission_state, prior_plan),
    do:
      mission_state_realized_activity_pressure_rows_with_source(
        mission_state,
        prior_plan,
        default_callbacks()
      )

  def mission_state_realized_activity_pressure_rows_with_source(mission_state, prior_plan, opts) do
    mission_state
    |> mission_state_realized_activity_rows_with_source(prior_plan, opts)
    |> PressureRows.realized_activity_pressure_rows_with_source()
  end

  defp default_callbacks do
    [
      result_artifacts_with_source: &mission_state_result_artifacts_with_source/1,
      put_inherited_result_artifact_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2,
      enrich_realized_activities_with_planned_context: &PriorActivityContext.enrich/2
    ]
  end

  defp mission_state_result_artifacts_with_source(mission_state) do
    BranchRefreshSourceInputs.result_artifacts_with_source(mission_state, "mission_state")
  end

  defp prior_plan_callbacks do
    [
      result_artifacts_with_source: &prior_plan_result_artifacts_with_source/1,
      put_inherited_result_artifact_trust_boundary:
        &BranchRefreshSourceInputs.put_inherited_result_artifact_trust_boundary/2,
      enrich_realized_activities_with_planned_context: &PriorActivityContext.enrich/2
    ]
  end

  defp prior_plan_result_artifacts_with_source(prior_plan) do
    BranchRefreshSourceInputs.result_artifacts_with_source(prior_plan, "prior_plan")
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
