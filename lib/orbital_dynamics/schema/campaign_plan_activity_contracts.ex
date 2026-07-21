defmodule OrbitalDynamics.Schema.CampaignPlanActivityContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_numeric_map: 3]
  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

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
      {%{} = activity, index}, acc -> validate_activity(acc, "#{path}[#{index}]", activity)
      {_activity, _index}, acc -> acc
    end)
  end

  defp validate_rows(issues, _path, _rows), do: issues

  defp validate_activity(issues, path, activity) do
    issues
    |> validate_duration(path, activity)
    |> validate_score(path, activity)
  end

  defp validate_duration(issues, path, activity) do
    if Map.has_key?(activity, "duration_s") do
      validate_duration_value(issues, path, activity, Map.get(activity, "duration_s"))
    else
      [error(path <> ".duration_s", "is required") | issues]
    end
  end

  defp validate_duration_value(issues, path, activity, duration_s) when is_number(duration_s) do
    issues
    |> validate_non_negative_duration(path, duration_s)
    |> validate_interval_duration(path, activity, duration_s)
  end

  defp validate_duration_value(issues, path, _activity, _duration_s) do
    [error(path <> ".duration_s", "must be a number") | issues]
  end

  defp validate_non_negative_duration(issues, _path, duration_s) when duration_s >= 0.0,
    do: issues

  defp validate_non_negative_duration(issues, path, _duration_s) do
    [error(path <> ".duration_s", "must be non-negative") | issues]
  end

  defp validate_interval_duration(issues, _path, _activity, duration_s)
       when duration_s < 0.0,
       do: issues

  defp validate_interval_duration(
         issues,
         path,
         %{"starts_at_s" => starts_at_s, "ends_at_s" => ends_at_s},
         duration_s
       )
       when is_number(starts_at_s) and is_number(ends_at_s) do
    if close?(duration_s, ends_at_s - starts_at_s) do
      issues
    else
      [error(path <> ".duration_s", "must equal ends_at_s - starts_at_s") | issues]
    end
  end

  defp validate_interval_duration(issues, _path, _activity, _duration_s), do: issues

  defp validate_score(issues, path, activity) do
    issues
    |> require_fields(path, activity, ["score", "score_terms"])
    |> validate_score_type(path, activity)
    |> validate_score_terms(path, activity)
    |> reconcile_score(path, activity)
  end

  defp validate_score_type(issues, path, activity) do
    case Map.fetch(activity, "score") do
      :error -> issues
      {:ok, score} when is_number(score) -> issues
      {:ok, _score} -> [error(path <> ".score", "must be a number") | issues]
    end
  end

  defp validate_score_terms(issues, path, activity) do
    case Map.fetch(activity, "score_terms") do
      :error ->
        issues

      {:ok, score_terms} when is_map(score_terms) ->
        validate_numeric_map(issues, path <> ".score_terms", score_terms)

      {:ok, _score_terms} ->
        [error(path <> ".score_terms", "must be a map") | issues]
    end
  end

  defp reconcile_score(issues, path, %{"score" => score, "score_terms" => score_terms})
       when is_number(score) and is_map(score_terms) do
    values = Map.values(score_terms)

    if Enum.all?(values, &is_number/1) and not close?(score, Enum.sum(values)) do
      [error(path <> ".score", "must equal numeric score_terms sum") | issues]
    else
      issues
    end
  end

  defp reconcile_score(issues, _path, _activity), do: issues

  defp close?(left, right), do: abs(left - right) <= @tolerance
end
