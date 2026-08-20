defmodule OrbitalDynamics.OperatorReview.OptimizationReview do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder
  alias OrbitalDynamics.Schema.JsonSafety

  @schema_contract "operator_review_package.v1"

  def ranking_comparison_package(report) do
    {rows, source_artifact_id, provenance} = ranking_comparison_package_input(report)

    build_package(rows, "ranking_comparison_report.v1", source_artifact_id, provenance)
  end

  def score_term_package(report) do
    {rows, source_artifact_id, provenance} = score_term_package_input(report)

    build_package(rows, "score_term_report.v1", source_artifact_id, provenance)
  end

  def objective_tradeoff_package(report) do
    {rows, source_artifact_id, provenance} = objective_tradeoff_package_input(report)

    build_package(rows, "objective_tradeoff_report.v1", source_artifact_id, provenance)
  end

  def pareto_frontier_package(report) do
    {rows, source_artifact_id, provenance} = pareto_frontier_package_input(report)

    build_package(rows, "pareto_frontier_report.v1", source_artifact_id, provenance)
  end

  def local_search_rows(trace, source \\ "campaign_plan.optimizer_search_trace")

  def local_search_rows(nil, _source), do: []

  def local_search_rows(%{} = trace, source) do
    trace = JsonSafety.normalize_input!(trace, "campaign local-search review trace")
    plan_id = trace["plan_id"]

    [
      %{
        "id" => review_id(["local_search", plan_id]),
        "review_type" => "local_search_review",
        "source" => source,
        "subject_id" => plan_id,
        "plan_id" => plan_id,
        "selection_contract" => trace["selection_contract"],
        "base_scoring_policy" => trace["base_scoring_policy"],
        "selected_scoring_policy" => trace["selected_scoring_policy"],
        "selected_alternative_id" => trace["selected_alternative_id"],
        "scenario_id" => trace["selected_timeline_scenario_id"],
        "selected_timeline_scenario_id" => trace["selected_timeline_scenario_id"],
        "selected_timeline_score" => trace["selected_timeline_score"],
        "selected_activity_ids" => trace["selected_activity_ids"],
        "selected_activity_count" => trace["selected_activity_count"],
        "action" => "review_local_search",
        "required_operator_action" => "review_local_search",
        "approval_status" => "operator_review_required",
        "reason" => local_search_reason(trace),
        "source_optimizer_search_trace" => trace
      }
      |> compact_map()
    ]
  end

  def ranking_comparison_package_input(report) do
    report = stringify_keys(report || %{})

    {
      ranking_comparison_rows(Map.get(report, "rows", [])),
      Map.get(report, "id") || Map.get(report, "source") || "ranking_comparison_report",
      Map.get(report, "provenance", %{})
    }
  end

  def score_term_package_input(report) do
    report = stringify_keys(report || %{})

    {
      score_term_rows(Map.get(report, "rows", [])),
      Map.get(report, "id") || Map.get(report, "source") || "score_term_report",
      Map.get(report, "provenance", %{})
    }
  end

  def objective_tradeoff_package_input(report) do
    report = stringify_keys(report || %{})

    {
      objective_tradeoff_rows(Map.get(report, "tradeoffs", [])),
      Map.get(report, "id") || Map.get(report, "source") || "objective_tradeoff_report",
      Map.get(report, "provenance", %{})
    }
  end

  def pareto_frontier_package_input(report) do
    report = stringify_keys(report || %{})

    {
      pareto_frontier_rows(Map.get(report, "rows", [])),
      Map.get(report, "id") || Map.get(report, "source") || "pareto_frontier_report",
      Map.get(report, "provenance", %{})
    }
  end

  def ranking_comparison_rows(rows, source \\ "ranking_comparison_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      scenario_id = Map.get(row, "scenario_id")

      %{
        "id" => review_id(["ranking_comparison", scenario_id, index]),
        "review_type" => "ranking_comparison_review",
        "source" => source,
        "subject_id" => scenario_id,
        "scenario_id" => scenario_id,
        "action" => "review_ranking_comparison",
        "required_operator_action" => "review_ranking_comparison",
        "approval_status" => "operator_review_required",
        "reason" => ranking_comparison_reason(row),
        "status" => Map.get(row, "status"),
        "left_rank" => Map.get(row, "left_rank"),
        "right_rank" => Map.get(row, "right_rank"),
        "rank_delta" => Map.get(row, "rank_delta"),
        "left_value" => Map.get(row, "left_value"),
        "right_value" => Map.get(row, "right_value"),
        "value_delta" => Map.get(row, "value_delta"),
        "source_ranking_comparison" => row
      }
      |> compact_map()
    end)
  end

  def score_term_rows(rows, source \\ "score_term_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      id = row["id"]
      scenario_id = row["scenario_id"]
      term_key = row["term_key"]

      %{
        "id" => review_id(["score_term", id || scenario_id, term_key]),
        "review_type" => "score_term_review",
        "source" => source,
        "subject_id" => id || scenario_id || term_key || "score_term",
        "scenario_id" => scenario_id,
        "branch_id" => row["branch_id"],
        "term_key" => term_key,
        "value" => row["value"],
        "timeline_score" => row["timeline_score"],
        "selected" => row["selected"],
        "action" => "review_score_term",
        "required_operator_action" => "review_score_term",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => score_term_reason(row),
        "source_score_term" => row
      }
      |> compact_map()
    end)
  end

  def objective_tradeoff_rows(rows, source \\ "objective_tradeoff_report.tradeoffs") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      scenario_id = row["scenario_id"]

      %{
        "id" => review_id(["objective_tradeoff", scenario_id, row["rank"]]),
        "review_type" => "objective_tradeoff_review",
        "source" => source,
        "subject_id" => scenario_id || "objective_tradeoff",
        "scenario_id" => scenario_id,
        "branch_id" => row["branch_id"],
        "score" => row["score"],
        "score_delta_from_selected" => row["score_delta_from_selected"],
        "activity_count" => row["activity_count"],
        "selected_observation_count" => row["selected_observation_count"],
        "selected_contact_count" => row["selected_contact_count"],
        "score_terms" => row["score_terms"],
        "activity_ids" => row["activity_ids"],
        "action" => "review_objective_tradeoff",
        "required_operator_action" => "review_objective_tradeoff",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => objective_tradeoff_reason(row),
        "source_objective_tradeoff" => row
      }
      |> compact_map()
    end)
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    candidate_refresh_score_term_rows(artifact) ++
      candidate_refresh_objective_tradeoff_rows(artifact)
  end

  defp candidate_refresh_score_term_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_score_term_report", artifact["source_score_term_report"]},
        {"candidate_refresh.score_term_report", artifact["score_term_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_score_term_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_score_term_rows(artifact)
  end

  defp source_score_term_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_score_term_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_score_term_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> score_term_rows("#{source}.rows")
  end

  defp source_score_term_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_score_term_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_score_term_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_score_term_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_score_term_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_score_term_rows(
         %{"schema_contract" => "score_term_report.v1"} = report,
         source
       ) do
    source_score_term_report_rows(report, source)
  end

  defp result_artifact_score_term_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_score_term_report", artifact["source_score_term_report"]},
      {"#{source}.score_term_report", artifact["score_term_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_score_term_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_score_term_rows(_artifact, _source), do: []

  defp candidate_refresh_objective_tradeoff_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_objective_tradeoff_report",
         artifact["source_objective_tradeoff_report"]},
        {"candidate_refresh.objective_tradeoff_report", artifact["objective_tradeoff_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_objective_tradeoff_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_objective_tradeoff_rows(artifact)
  end

  defp source_objective_tradeoff_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_objective_tradeoff_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_objective_tradeoff_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("tradeoffs", [])
    |> objective_tradeoff_rows("#{source}.tradeoffs")
  end

  defp source_objective_tradeoff_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_objective_tradeoff_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_objective_tradeoff_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_objective_tradeoff_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_objective_tradeoff_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_objective_tradeoff_rows(
         %{"schema_contract" => "objective_tradeoff_report.v1"} = report,
         source
       ) do
    source_objective_tradeoff_report_rows(report, source)
  end

  defp result_artifact_objective_tradeoff_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_objective_tradeoff_report",
       artifact["source_objective_tradeoff_report"]},
      {"#{source}.objective_tradeoff_report", artifact["objective_tradeoff_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_objective_tradeoff_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_objective_tradeoff_rows(_artifact, _source), do: []

  def pareto_frontier_rows(rows, source \\ "pareto_frontier_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      scenario_id = Map.get(row, "scenario_id") || Map.get(row, "id")

      %{
        "id" => review_id(["pareto_frontier", scenario_id, index]),
        "review_type" => "pareto_frontier_review",
        "source" => source,
        "subject_id" => scenario_id,
        "scenario_id" => scenario_id,
        "branch_id" => scenario_id,
        "action" => "review_pareto_frontier",
        "required_operator_action" => "review_pareto_frontier",
        "approval_status" => "operator_review_required",
        "reason" => pareto_frontier_reason(row),
        "frontier" => Map.get(row, "frontier"),
        "objective_keys" => Map.get(row, "objective_keys", []),
        "objective_values" => Map.get(row, "objective_values", %{}),
        "dominated_by_ids" => Map.get(row, "dominated_by_ids", []),
        "dominates_ids" => Map.get(row, "dominates_ids", []),
        "source_pareto_frontier" => row
      }
      |> compact_map()
    end)
  end

  defp ranking_comparison_reason(%{
         "scenario_id" => scenario_id,
         "status" => status,
         "rank_delta" => rank_delta,
         "value_delta" => value_delta
       }) do
    "review ranking comparison for #{scenario_id}: #{status}, rank delta #{encode_value(rank_delta)}, value delta #{encode_value(value_delta)}"
  end

  defp ranking_comparison_reason(_row), do: "review ranking comparison row"

  defp score_term_reason(row) do
    term_key = row["term_key"] || "score_term"
    scenario_id = row["scenario_id"] || row["id"] || "scenario"
    value = encode_value(row["value"])

    "review score term #{term_key} for #{scenario_id}: value #{value}"
  end

  defp objective_tradeoff_reason(row) do
    scenario_id = row["scenario_id"] || "scenario"
    delta = encode_value(row["score_delta_from_selected"])

    "review objective tradeoff for #{scenario_id}: score delta #{delta}"
  end

  defp pareto_frontier_reason(%{
         "scenario_id" => scenario_id,
         "frontier" => true,
         "dominates_ids" => dominates_ids
       })
       when is_list(dominates_ids) do
    "review Pareto frontier branch #{scenario_id}: dominates #{length(dominates_ids)} alternatives"
  end

  defp pareto_frontier_reason(%{
         "scenario_id" => scenario_id,
         "dominated_by_ids" => dominated_by_ids
       })
       when is_list(dominated_by_ids) do
    "review dominated branch #{scenario_id}: dominated by #{Enum.join(dominated_by_ids, ",")}"
  end

  defp pareto_frontier_reason(_row), do: "review Pareto frontier row"

  defp local_search_reason(trace) do
    "review V1 local-search selection #{trace["selected_alternative_id"]} for " <>
      "#{trace["selected_timeline_scenario_id"]}: score #{encode_value(trace["selected_timeline_score"])}"
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

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
