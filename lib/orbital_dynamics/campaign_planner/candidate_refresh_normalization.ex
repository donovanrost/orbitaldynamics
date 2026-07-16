defmodule OrbitalDynamics.CampaignPlanner.CandidateRefreshNormalization do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding
  alias OrbitalDynamics.{CandidateRefresh, Schema}

  def artifact(nil), do: nil

  def artifact(candidate_refresh) do
    candidate_refresh = ValueEncoding.stringify_keys(candidate_refresh || %{})

    candidate_refresh =
      case candidate_refresh do
        %{"candidate_refresh" => %{} = nested} -> nested
        %{} -> candidate_refresh
      end
      |> normalize_freshness_report()

    case Schema.validate_artifact(candidate_refresh, schema_contract: "candidate_refresh.v1") do
      {:ok, _report} ->
        candidate_refresh

      {:error, report} ->
        raise ArgumentError, "invalid candidate_refresh.v1 artifact: #{inspect(report)}"
    end
  end

  def request(nil), do: nil

  def request(%{} = request), do: ValueEncoding.stringify_keys(request)

  def request(_request) do
    raise ArgumentError, "candidate_refresh_request must be an object"
  end

  defp normalize_freshness_report(%{"freshness_report" => %{} = report} = refresh) do
    Map.put(refresh, "freshness_report", freshness_report(report))
  end

  defp normalize_freshness_report(refresh), do: refresh

  defp freshness_report(report) do
    report = ValueEncoding.stringify_keys(report)
    state_quality_status = freshness_state_quality_status(report)
    stale_reasons = freshness_stale_reasons(report, state_quality_status)
    unknown_reasons = freshness_unknown_reasons(report, state_quality_status)

    report
    |> Map.put("stale_reasons", stale_reasons)
    |> Map.put("unknown_reasons", unknown_reasons)
    |> Map.put("status", freshness_status(stale_reasons, unknown_reasons))
    |> Map.put("state_quality_status", state_quality_status)
    |> Map.put_new("allowed_state_quality_levels", freshness_allowed_quality_levels(report))
    |> Map.put_new("model_limits", CandidateRefresh.model_limits())
  end

  defp freshness_stale_reasons(report, state_quality_status) do
    []
    |> maybe_append(freshness_snapshot_stale?(report), "accepted_snapshot_older_than_policy")
    |> maybe_append(
      freshness_horizon_stale?(report),
      "remaining_horizon_does_not_start_at_current_epoch"
    )
    |> maybe_append(
      state_quality_status == "not_accepted",
      "accepted_state_quality_below_policy"
    )
  end

  defp freshness_unknown_reasons(report, state_quality_status) do
    []
    |> maybe_append(
      not is_number(Map.get(report, "accepted_snapshot_age_s")),
      "accepted_snapshot_age_unknown"
    )
    |> maybe_append(
      not is_number(Map.get(report, "horizon_start_offset_s")),
      "horizon_alignment_unknown"
    )
    |> maybe_append(state_quality_status == "unknown", "accepted_state_quality_unknown")
  end

  defp freshness_snapshot_stale?(report) do
    age = Map.get(report, "accepted_snapshot_age_s")
    max_age = Map.get(report, "max_snapshot_age_s")

    is_number(age) and is_number(max_age) and age > max_age
  end

  defp freshness_horizon_stale?(report) do
    offset = Map.get(report, "horizon_start_offset_s")
    max_offset = Map.get(report, "max_horizon_start_offset_s")

    is_number(offset) and is_number(max_offset) and abs(offset) > max_offset
  end

  defp freshness_state_quality_status(report) do
    level = Map.get(report, "accepted_state_quality_level")
    allowed_levels = freshness_allowed_quality_levels(report)

    cond do
      not is_binary(level) -> "unknown"
      level in allowed_levels -> "accepted"
      true -> "not_accepted"
    end
  end

  defp freshness_allowed_quality_levels(%{"allowed_state_quality_levels" => levels})
       when is_list(levels) do
    levels
    |> Enum.filter(&is_binary/1)
    |> case do
      [] -> ["accepted", "planning_accepted"]
      values -> values
    end
  end

  defp freshness_allowed_quality_levels(_report), do: ["accepted", "planning_accepted"]

  defp freshness_status(stale_reasons, unknown_reasons) do
    cond do
      stale_reasons != [] -> "stale"
      unknown_reasons != [] -> "unknown"
      true -> "current"
    end
  end

  defp maybe_append(values, true, value), do: values ++ [value]
  defp maybe_append(values, false, _value), do: values
end
