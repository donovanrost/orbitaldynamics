defmodule OrbitalDynamics.Schema.CampaignPlanActivityDurationContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @activity_fields ["activities", "candidate_activities"]
  @tolerance 1.0e-9

  def validate(issues, artifact) when is_map(artifact) do
    issues
    |> validate_activity_fields(artifact)
    |> validate_ranked_timelines(Map.get(artifact, "ranked_timelines"))
  end

  defp validate_activity_fields(issues, artifact) do
    Enum.reduce(@activity_fields, issues, fn field, acc ->
      validate_rows(acc, "$.#{field}", Map.get(artifact, field))
    end)
  end

  defp validate_ranked_timelines(issues, timelines) when is_list(timelines) do
    timelines
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = timeline, index}, acc ->
        validate_rows(
          acc,
          "$.ranked_timelines[#{index}].activities",
          Map.get(timeline, "activities")
        )

      {_timeline, _index}, acc ->
        acc
    end)
  end

  defp validate_ranked_timelines(issues, _timelines), do: issues

  defp validate_rows(issues, path, rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = activity, index}, acc -> validate_duration(acc, "#{path}[#{index}]", activity)
      {_activity, _index}, acc -> acc
    end)
  end

  defp validate_rows(issues, _path, _rows), do: issues

  defp validate_duration(issues, path, activity) do
    if Map.has_key?(activity, "duration_s") do
      validate_duration_value(issues, path, activity, Map.get(activity, "duration_s"))
    else
      [error(path <> ".duration_s", "is required") | issues]
    end
  end

  defp validate_duration_value(issues, path, activity, duration_s) when is_number(duration_s) do
    issues
    |> validate_non_negative(path, duration_s)
    |> validate_interval_duration(path, activity, duration_s)
  end

  defp validate_duration_value(issues, path, _activity, _duration_s) do
    [error(path <> ".duration_s", "must be a number") | issues]
  end

  defp validate_non_negative(issues, _path, duration_s) when duration_s >= 0.0, do: issues

  defp validate_non_negative(issues, path, _duration_s) do
    [error(path <> ".duration_s", "must be non-negative") | issues]
  end

  defp validate_interval_duration(
         issues,
         _path,
         _activity,
         duration_s
       )
       when duration_s < 0.0,
       do: issues

  defp validate_interval_duration(
         issues,
         path,
         %{"starts_at_s" => starts_at_s, "ends_at_s" => ends_at_s},
         duration_s
       )
       when is_number(starts_at_s) and is_number(ends_at_s) do
    if abs(duration_s - (ends_at_s - starts_at_s)) <= @tolerance do
      issues
    else
      [error(path <> ".duration_s", "must equal ends_at_s - starts_at_s") | issues]
    end
  end

  defp validate_interval_duration(issues, _path, _activity, _duration_s), do: issues
end
