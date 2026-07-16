defmodule OrbitalDynamics.CandidateRefresh.TargetPriority do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ObservationObjectives
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def resolve(
        refresh,
        scenario_id,
        target_id,
        %{"priority_override_source" => "operational_feedback"} = target,
        fallback,
        numeric_value,
        _operational_feedback,
        refresh_objectives
      ) do
    base_priority =
      case numeric_value.(Map.get(target, "priority", fallback)) do
        value when is_number(value) -> max(value, 0.0)
        _value -> max(fallback, 0.0)
      end

    objective_priority(
      refresh,
      scenario_id,
      target_id,
      base_priority,
      "operational_feedback.target_priority",
      numeric_value,
      refresh_objectives
    )
  end

  def resolve(
        refresh,
        scenario_id,
        target_id,
        target,
        fallback,
        numeric_value,
        operational_feedback,
        refresh_objectives
      ) do
    priorities =
      refresh
      |> operational_feedback.()
      |> Map.get("target_priority_overrides")

    target_id = encode_value(target_id)

    {base_priority, source} =
      cond do
        is_map(priorities) and is_number(Map.get(priorities, target_id)) ->
          {
            priorities
            |> Map.get(target_id)
            |> max(0.0),
            "operational_feedback.target_priority_overrides"
          }

        is_map(target) and is_number(numeric_value.(Map.get(target, "priority"))) ->
          target_priority = numeric_value.(Map.get(target, "priority"))

          {
            max(target_priority, 0.0),
            "candidate_refresh.targets.priority"
          }

        true ->
          {max(fallback, 0.0), "source_window.target_priority"}
      end

    objective_priority(
      refresh,
      scenario_id,
      target_id,
      base_priority,
      source,
      numeric_value,
      refresh_objectives
    )
  end

  defp objective_priority(
         refresh,
         scenario_id,
         target_id,
         base_priority,
         base_source,
         numeric_value,
         refresh_objectives
       ) do
    ObservationObjectives.target_priority(
      refresh,
      scenario_id,
      target_id,
      base_priority,
      base_source,
      &encode_value/1,
      numeric_value,
      refresh_objectives
    )
  end

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
