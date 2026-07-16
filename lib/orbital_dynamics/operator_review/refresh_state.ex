defmodule OrbitalDynamics.OperatorReview.RefreshState do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def freshness_package(report) do
    {rows, source_artifact_id, provenance} = freshness_package_input(report)

    build_package(rows, "freshness_report.v1", source_artifact_id, provenance)
  end

  def refresh_budget_package(report) do
    {rows, source_artifact_id, provenance} = refresh_budget_package_input(report)

    build_package(rows, "refresh_budget_report.v1", source_artifact_id, provenance)
  end

  def freshness_package_input(report) do
    report = stringify_keys(report || %{})

    {
      freshness_rows(report, "freshness_report"),
      Map.get(report, "id") || Map.get(report, "source") || "freshness_report",
      Map.get(report, "provenance", %{})
    }
  end

  def freshness_rows(nil, _source), do: []

  def freshness_rows(%{} = report, source) do
    report = stringify_keys(report)
    status = Map.get(report, "status")

    if status in ["stale", "unknown"] do
      reason =
        report
        |> freshness_reasons()
        |> case do
          [] -> "candidate refresh freshness is #{status}"
          reasons -> "candidate refresh freshness is #{status}: #{Enum.join(reasons, ", ")}"
        end

      [
        %{
          "id" => review_id(["freshness_review", stable_id_fragment(source), status]),
          "review_type" => "freshness_review",
          "source" => source,
          "subject_id" => "freshness:#{status}",
          "action" => "review_refresh_freshness",
          "required_operator_action" => "review_refresh_freshness",
          "approval_status" => "operator_review_required",
          "reason" => reason,
          "freshness_status" => status,
          "model" => report["model"],
          "generated_at" => report["generated_at"],
          "accepted_at" => report["accepted_at"],
          "accepted_state_quality_level" => report["accepted_state_quality_level"],
          "allowed_state_quality_levels" => report["allowed_state_quality_levels"],
          "state_quality_status" => report["state_quality_status"],
          "current_epoch_s" => report["current_epoch_s"],
          "horizon_starts_at_s" => report["horizon_starts_at_s"],
          "accepted_snapshot_age_s" => report["accepted_snapshot_age_s"],
          "horizon_start_offset_s" => report["horizon_start_offset_s"],
          "max_snapshot_age_s" => report["max_snapshot_age_s"],
          "max_horizon_start_offset_s" => report["max_horizon_start_offset_s"],
          "stale_reasons" => Map.get(report, "stale_reasons", []),
          "unknown_reasons" => Map.get(report, "unknown_reasons", []),
          "source_freshness_report" => report
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  def freshness_rows(_report, _source), do: []

  def refresh_budget_rows(%{} = report, source) do
    report = stringify_keys(report)
    dropped_count = Map.get(report, "dropped_candidate_count", 0)
    invalid_policy? = report["invalid_candidate_limit_policy"] == true

    if (is_number(dropped_count) and dropped_count > 0) or invalid_policy? do
      [
        %{
          "id" => review_id(["refresh_budget_review", stable_id_fragment(source)]),
          "review_type" => "refresh_budget_review",
          "source" => source,
          "subject_id" => "refresh_budget",
          "action" => "review_refresh_budget",
          "required_operator_action" => "review_refresh_budget",
          "approval_status" => "operator_review_required",
          "reason" => refresh_budget_review_reason(report, dropped_count, invalid_policy?),
          "model" => report["model"],
          "input_candidate_count" => report["input_candidate_count"],
          "kept_candidate_count" => report["kept_candidate_count"],
          "dropped_candidate_count" => dropped_count,
          "max_candidate_activities" => report["max_candidate_activities"],
          "invalid_candidate_limit_policy" => report["invalid_candidate_limit_policy"],
          "invalid_candidate_limit_policy_reason" =>
            report["invalid_candidate_limit_policy_reason"],
          "source_candidate_limit_policy" => report["source_candidate_limit_policy"],
          "selection_order" => report["selection_order"],
          "kept_candidate_ids" => Map.get(report, "kept_candidate_ids", []),
          "dropped_candidate_ids" => Map.get(report, "dropped_candidate_ids", []),
          "source_refresh_budget_report" => report
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  def refresh_budget_rows(_report, _source), do: []

  def refresh_budget_package_input(report) do
    report = stringify_keys(report || %{})

    {
      refresh_budget_rows(report, "refresh_budget_report"),
      Map.get(report, "id") || Map.get(report, "source") || "refresh_budget_report",
      Map.get(report, "provenance", %{})
    }
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    candidate_refresh_freshness_rows(artifact) ++
      candidate_refresh_refresh_budget_rows(artifact)
  end

  defp candidate_refresh_freshness_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_freshness_report",
         get_in(artifact, ["accepted_planning_state", "source_freshness_report"])},
        {"candidate_refresh.accepted_planning_state.freshness_report",
         get_in(artifact, ["accepted_planning_state", "freshness_report"])},
        {"candidate_refresh.mission_state.source_freshness_report",
         get_in(artifact, ["mission_state", "source_freshness_report"])},
        {"candidate_refresh.mission_state.freshness_report",
         get_in(artifact, ["mission_state", "freshness_report"])},
        {"candidate_refresh.source_freshness_report", artifact["source_freshness_report"]},
        {"candidate_refresh.freshness_report", artifact["freshness_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_freshness_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_freshness_rows(artifact)
  end

  defp source_freshness_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_freshness_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_freshness_report_rows(%{} = report, source), do: freshness_rows(report, source)
  defp source_freshness_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_freshness_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_freshness_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_freshness_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_freshness_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_freshness_rows(
         %{"schema_contract" => "freshness_report.v1"} = report,
         source
       ) do
    source_freshness_report_rows(report, source)
  end

  defp result_artifact_freshness_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_freshness_report", artifact["source_freshness_report"]},
      {"#{source}.freshness_report", artifact["freshness_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_freshness_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_freshness_rows(_artifact, _source), do: []

  defp candidate_refresh_refresh_budget_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_refresh_budget_report",
         get_in(artifact, ["accepted_planning_state", "source_refresh_budget_report"])},
        {"candidate_refresh.accepted_planning_state.refresh_budget_report",
         get_in(artifact, ["accepted_planning_state", "refresh_budget_report"])},
        {"candidate_refresh.mission_state.source_refresh_budget_report",
         get_in(artifact, ["mission_state", "source_refresh_budget_report"])},
        {"candidate_refresh.mission_state.refresh_budget_report",
         get_in(artifact, ["mission_state", "refresh_budget_report"])},
        {"candidate_refresh.source_refresh_budget_report",
         artifact["source_refresh_budget_report"]},
        {"candidate_refresh.refresh_budget_report", artifact["refresh_budget_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_refresh_budget_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_refresh_budget_rows(artifact)
  end

  defp source_refresh_budget_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_refresh_budget_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_refresh_budget_report_rows(%{} = report, source),
    do: refresh_budget_rows(report, source)

  defp source_refresh_budget_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_refresh_budget_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_refresh_budget_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_refresh_budget_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_refresh_budget_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_refresh_budget_rows(
         %{"schema_contract" => "refresh_budget_report.v1"} = report,
         source
       ) do
    source_refresh_budget_report_rows(report, source)
  end

  defp result_artifact_refresh_budget_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_refresh_budget_report", artifact["source_refresh_budget_report"]},
      {"#{source}.refresh_budget_report", artifact["refresh_budget_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_refresh_budget_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_refresh_budget_rows(_artifact, _source), do: []

  defp freshness_reasons(report) do
    Map.get(report, "stale_reasons", []) ++ Map.get(report, "unknown_reasons", [])
  end

  defp refresh_budget_review_reason(report, _dropped_count, true) do
    "candidate refresh budget policy is invalid: #{report["invalid_candidate_limit_policy_reason"]}"
  end

  defp refresh_budget_review_reason(_report, dropped_count, _invalid_policy?)
       when is_number(dropped_count) and dropped_count > 0 do
    "candidate refresh budget dropped #{dropped_count} candidates"
  end

  defp refresh_budget_review_reason(_report, _dropped_count, _invalid_policy?),
    do: "candidate refresh budget requires review"

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stable_id_fragment(nil), do: nil

  defp stable_id_fragment(value) when is_binary(value) do
    value
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
    |> String.trim("_")
    |> case do
      "" ->
        "root"

      fragment ->
        if Regex.match?(~r/^[A-Za-z0-9]/, fragment) do
          fragment
        else
          "path:#{fragment}"
        end
    end
  end

  defp stable_id_fragment(value), do: encode_value(value)

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
