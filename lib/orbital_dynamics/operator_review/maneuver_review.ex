defmodule OrbitalDynamics.OperatorReview.ManeuverReview do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "maneuver_review_report.v1", source_artifact_id, provenance)
  end

  def recommendation_package(recommendation) do
    {rows, source_artifact_id, provenance} = recommendation_package_input(recommendation)

    build_package(rows, "maneuver_recommendation.v1", source_artifact_id, provenance)
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_maneuver_review_report",
         artifact["source_maneuver_review_report"]},
        {"candidate_refresh.maneuver_review_report", artifact["maneuver_review_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(Map.get(report, "rows", [])),
      Map.get(report, "id") || Map.get(report, "source_artifact_id") ||
        Map.get(report, "source") || "maneuver_review_report",
      Map.get(report, "provenance", %{})
    }
  end

  def recommendation_package_input(recommendation) do
    recommendation = stringify_keys(recommendation || %{})

    {
      recommendation_rows(recommendation),
      Map.get(recommendation, "id") || Map.get(recommendation, "maneuver_id") ||
        "maneuver_recommendation",
      Map.get(recommendation, "provenance", %{})
    }
  end

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> rows("#{source}.rows")
  end

  def source_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_report_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_report_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_report_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_report_rows(
         %{"schema_contract" => "maneuver_review_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_report_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_maneuver_review_report", artifact["source_maneuver_review_report"]},
      {"#{source}.maneuver_review_report", artifact["maneuver_review_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_report_rows(_artifact, _source), do: []

  def recommendation_rows(recommendation, source \\ "maneuver_recommendation") do
    report =
      OrbitalDynamics.ManeuverReview.report([recommendation],
        source: source,
        source_artifact_id:
          Map.get(recommendation, "id") || Map.get(recommendation, "maneuver_id")
      )

    report
    |> Map.get("rows", [])
    |> rows(source)
  end

  def result_artifact_rows(artifact) do
    review_rows = result_artifact_maneuver_review_rows(artifact)
    recommendation_rows = result_artifact_maneuver_recommendation_rows(artifact)
    review_keys = MapSet.new(review_rows, &identity/1)

    review_rows ++
      Enum.reject(recommendation_rows, fn row ->
        MapSet.member?(review_keys, identity(row))
      end)
  end

  defp result_artifact_maneuver_review_rows(artifact) do
    artifact
    |> get_in(["maneuver_review_report", "rows"])
    |> List.wrap()
    |> rows("result_artifact.maneuver_review_report.rows")
  end

  defp result_artifact_maneuver_recommendation_rows(artifact) do
    recommendations = Map.get(artifact, "maneuver_recommendations", [])

    if recommendations == [] do
      []
    else
      recommendations
      |> OrbitalDynamics.ManeuverReview.report(
        source: "result_artifact.maneuver_recommendations",
        source_artifact_id: result_artifact_id(artifact)
      )
      |> Map.get("rows", [])
      |> rows("result_artifact.maneuver_recommendations")
    end
  end

  def rows(rows, source \\ "maneuver_review_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = preferred_rule_match(row)
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["maneuver_review", row["scenario_id"], row["maneuver_id"], index]),
        "review_type" => "maneuver_review",
        "source" => source,
        "subject_id" => row["maneuver_id"],
        "maneuver_id" => row["maneuver_id"],
        "scenario_id" => row["scenario_id"],
        "maneuver_type" => row["maneuver_type"],
        "epoch_s" => row["epoch_s"],
        "epoch_scale" => row["epoch_scale"],
        "frame" => row["frame"],
        "delta_v_km_s" => row["delta_v_km_s"],
        "delta_v_magnitude_km_s" => row["delta_v_magnitude_km_s"],
        "maneuver_model" => row["maneuver_model"],
        "maneuver_success_factor" => row["maneuver_success_factor"],
        "maneuver_success_factor_source" => row["maneuver_success_factor_source"],
        "approval_status" => row["approval_status"],
        "action" => row["required_operator_action"],
        "required_operator_action" => row["required_operator_action"],
        "reason" => row["reason"],
        "execution_boundary" => row["execution_boundary"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_recommendation" => row["source_recommendation"],
        "source_maneuver_review" => row
      }
      |> compact_map()
    end)
  end

  defp preferred_rule_match(%{"required_operator_action" => action} = row)
       when action == "review_invalid_maneuver_recommendation" do
    row
    |> Map.get("approval_rule_matches", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.find(fn match -> match["rule_id"] == "invalid_maneuver_recommendation_review" end)
    |> case do
      nil -> row["approval_rule_matches"] |> first_map() |> stringify_keys()
      match -> match
    end
  end

  defp preferred_rule_match(row) do
    row["approval_rule_matches"] |> first_map() |> stringify_keys()
  end

  defp matched_policy_escalation(row) do
    preferred_rule_id =
      row
      |> preferred_approval_rule_match()
      |> Map.get("rule_id")

    rule_ids =
      row
      |> Map.get("approval_rule_matches", [])
      |> List.wrap()
      |> Enum.map(&Map.get(&1, "rule_id"))
      |> Enum.reject(&is_nil/1)

    escalations =
      row
      |> get_in(["policy_decision", "escalations"])
      |> List.wrap()
      |> Enum.filter(&is_map/1)

    escalation =
      Enum.find(escalations, &(Map.get(&1, "rule_id") == preferred_rule_id)) ||
        Enum.find(escalations, &(Map.get(&1, "rule_id") in rule_ids)) ||
        List.first(escalations) ||
        row
        |> Map.get("approval_rule_matches", [])
        |> List.wrap()
        |> Enum.find(&policy_escalation_context?/1)

    escalation || %{}
  end

  defp preferred_approval_rule_match(%{} = row) do
    preferred_classification =
      row["approval_status"] || get_in(row, ["policy_decision", "classification"])

    preferred_approval_rule_match(row["approval_rule_matches"], preferred_classification)
  end

  defp preferred_approval_rule_match(rule_matches, preferred_classification)
       when is_list(rule_matches) do
    rule_matches =
      rule_matches
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    Enum.find(rule_matches, &(&1["classification"] == preferred_classification)) ||
      List.first(rule_matches) ||
      %{}
  end

  defp preferred_approval_rule_match(_rule_matches, _preferred_classification), do: %{}

  defp policy_escalation_context?(%{} = row) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(row, &1)
    )
  end

  defp policy_escalation_context?(_row), do: false

  defp identity(row) do
    [
      row["review_type"],
      row["maneuver_id"] || row["subject_id"],
      row["scenario_id"],
      row["epoch_s"],
      row["delta_v_km_s"],
      row["required_operator_action"] || row["action"]
    ]
    |> encode_value()
  end

  defp result_artifact_id(artifact) do
    review_id([
      "result_artifact",
      artifact["study_id"],
      get_in(artifact, ["run", "id"]) || get_in(artifact, ["execution_report", "run_id"])
    ])
  end

  defp first_map(values) when is_list(values), do: Enum.find(values, %{}, &is_map/1)
  defp first_map(_values), do: %{}

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil

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
