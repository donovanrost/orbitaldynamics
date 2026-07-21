defmodule OrbitalDynamics.Schema.CampaignPlanHorizonContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, expect_optional_number: 4]

  @direct_schedule_fields [
    "activities",
    "candidate_activities",
    "proposed_contacts",
    "contact_intents"
  ]

  @tolerance 1.0e-9

  def validate(issues, artifact) when is_map(artifact) do
    case Map.get(artifact, "planning_horizon") do
      %{} = horizon -> validate_horizon(issues, horizon, artifact)
      _horizon -> issues
    end
  end

  defp validate_horizon(issues, horizon, artifact) do
    issues
    |> expect_optional_number("$.planning_horizon", horizon, "duration_s")
    |> expect_optional_number("$.planning_horizon", horizon, "output_step_s")
    |> validate_positive_field(horizon, "duration_s")
    |> validate_positive_field(horizon, "output_step_s")
    |> validate_output_step_dependency(horizon)
    |> validate_output_step(horizon)
    |> validate_schedule_envelope(artifact, Map.get(horizon, "duration_s"))
  end

  defp validate_output_step_dependency(
         issues,
         %{"output_step_s" => output_step_s} = horizon
       )
       when not is_nil(output_step_s) and not is_map_key(horizon, "duration_s") do
    [error("$.planning_horizon.duration_s", "is required when output_step_s is present") | issues]
  end

  defp validate_output_step_dependency(issues, _horizon), do: issues

  defp validate_positive_field(issues, horizon, field) do
    case Map.get(horizon, field) do
      value when is_number(value) and value <= 0 ->
        [error("$.planning_horizon.#{field}", "must be greater than 0") | issues]

      _value ->
        issues
    end
  end

  defp validate_output_step(
         issues,
         %{"duration_s" => duration_s, "output_step_s" => output_step_s}
       )
       when is_number(duration_s) and duration_s > 0 and is_number(output_step_s) and
              output_step_s > duration_s do
    [
      error("$.planning_horizon.output_step_s", "must not exceed horizon duration")
      | issues
    ]
  end

  defp validate_output_step(issues, _horizon), do: issues

  defp validate_schedule_envelope(issues, artifact, duration_s)
       when is_number(duration_s) and duration_s > 0 do
    issues
    |> validate_direct_schedule_rows(artifact, duration_s)
    |> validate_ranked_schedule_rows(Map.get(artifact, "ranked_timelines"), duration_s)
  end

  defp validate_schedule_envelope(issues, _artifact, _duration_s), do: issues

  defp validate_direct_schedule_rows(issues, artifact, duration_s) do
    Enum.reduce(@direct_schedule_fields, issues, fn field, acc ->
      validate_rows(acc, "$.#{field}", Map.get(artifact, field), duration_s)
    end)
  end

  defp validate_ranked_schedule_rows(issues, timelines, duration_s) when is_list(timelines) do
    timelines
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{"activities" => activities}, index}, acc ->
        validate_rows(
          acc,
          "$.ranked_timelines[#{index}].activities",
          activities,
          duration_s
        )

      {_timeline, _index}, acc ->
        acc
    end)
  end

  defp validate_ranked_schedule_rows(issues, _timelines, _duration_s), do: issues

  defp validate_rows(issues, path, rows, duration_s) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = row, index}, acc -> validate_row_bounds(acc, "#{path}[#{index}]", row, duration_s)
      {_row, _index}, acc -> acc
    end)
  end

  defp validate_rows(issues, _path, _rows, _duration_s), do: issues

  defp validate_row_bounds(issues, path, row, duration_s) do
    issues
    |> validate_non_negative_start(path, Map.get(row, "starts_at_s"))
    |> validate_end_within_duration(path, Map.get(row, "ends_at_s"), duration_s)
  end

  defp validate_non_negative_start(issues, path, starts_at_s)
       when is_number(starts_at_s) and starts_at_s < -@tolerance,
       do: [error(path <> ".starts_at_s", "must be within the planning horizon") | issues]

  defp validate_non_negative_start(issues, _path, _starts_at_s), do: issues

  defp validate_end_within_duration(issues, path, ends_at_s, duration_s)
       when is_number(ends_at_s) and ends_at_s > duration_s + @tolerance,
       do: [error(path <> ".ends_at_s", "must be within the planning horizon") | issues]

  defp validate_end_within_duration(issues, _path, _ends_at_s, _duration_s), do: issues
end
