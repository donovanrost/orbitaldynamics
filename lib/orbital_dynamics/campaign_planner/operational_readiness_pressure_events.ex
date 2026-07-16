defmodule OrbitalDynamics.CampaignPlanner.OperationalReadinessPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{OperationalReadinessSourceReports, ValueEncoding}

  def pressure_branch(row, source_path, index),
    do: pressure_branch(row, source_path, index, default_callbacks())

  def pressure_branch(row, source_path, index, opts) when is_list(opts) do
    case pressure_event(row, source_path, opts) do
      nil ->
        []

      event ->
        identity = pressure_identity(row, index, opts)

        [
          %{
            "id" => "derived_operational_readiness_pressure_#{identity}",
            "label" => "Derived operational-readiness review #{identity}",
            "events" => [event],
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_event(row, source_path), do: pressure_event(row, source_path, default_callbacks())

  def pressure_event(row, source_path, opts) when is_list(opts) do
    if reviewable?(row) do
      compact_map = Keyword.fetch!(opts, :compact_map)
      operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)

      %{
        "type" => "operational_readiness_pressure",
        "report_id" => row["report_id"],
        "source_artifact_type" => row["source_artifact_type"],
        "source_artifact_id" => row["source_artifact_id"],
        "readiness_level" => row["readiness_level"],
        "import_classification" => row["import_classification"],
        "operational_readiness_status" => row["operational_readiness_status"],
        "gate_count" => row["gate_count"],
        "passed_gate_count" => row["passed_gate_count"],
        "review_gate_count" => row["review_gate_count"],
        "analysis_gate_count" => row["analysis_gate_count"],
        "blocked_gate_count" => row["blocked_gate_count"],
        "readiness_gate_id" => row["readiness_gate_id"],
        "readiness_gate_status" => row["readiness_gate_status"],
        "readiness_gate_classification" => row["readiness_gate_classification"],
        "readiness_gate_reason" => row["readiness_gate_reason"],
        "analysis_mode" => row["analysis_mode"],
        "analysis_mode_source" => row["analysis_mode_source"],
        "gate_status_counts" => row["gate_status_counts"],
        "gate_classification_counts" => row["gate_classification_counts"],
        "passed_gate_ids" => row["passed_gate_ids"],
        "review_required_gate_ids" => row["review_required_gate_ids"],
        "analysis_only_gate_ids" => row["analysis_only_gate_ids"],
        "blocked_gate_ids" => row["blocked_gate_ids"],
        "non_passed_gate_ids" => row["non_passed_gate_ids"],
        "evidence" => row["evidence"],
        "required_operator_action" => row["required_operator_action"],
        "derivation_reasons" => ["operational_readiness_review"],
        "feedback_source" => source_path,
        "feedback_scope" => "operational_readiness",
        "feedback_key" =>
          row["readiness_gate_id"] || row["report_id"] || row["source_artifact_id"] ||
            "operational_readiness",
        "trust_boundary" => operator_review_trust_boundary.(row),
        "assumptions" => row["assumptions"],
        "source_operational_readiness_gate" => row["source_operational_readiness_gate"],
        "source_operational_readiness_report" => row["source_operational_readiness_report"]
      }
      |> Map.merge(OperationalReadinessSourceReports.operator_training_context(row))
      |> Map.merge(OperationalReadinessSourceReports.import_readiness_context(row))
      |> Map.merge(OperationalReadinessSourceReports.schema_validation_context(row))
      |> Map.merge(OperationalReadinessSourceReports.resource_availability_context(row))
      |> compact_map.()
    end
  end

  def reviewable?(row) do
    row["required_operator_action"] in [
      "review_operational_readiness",
      "record_operational_readiness_analysis_only",
      "review_blocked_operational_readiness"
    ] and
      (row["readiness_gate_status"] not in [nil, "passed"] or
         row["import_classification"] in ["review_only", "analysis_only", "blocked"] or
         row["operational_readiness_status"] in ["review_required", "analysis_only", "blocked"])
  end

  def pressure_branches_from_sources(sources),
    do: pressure_branches_from_sources(sources, default_callbacks())

  def pressure_branches_from_sources(sources, opts) when is_list(opts) do
    sources
    |> OperationalReadinessSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      pressure_branch(row, source_path, index, opts)
    end)
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      row["readiness_gate_id"],
      row["report_id"],
      row["source_artifact_id"],
      row["import_classification"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp default_callbacks do
    [
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      operator_review_trust_boundary: &operator_review_trust_boundary/1
    ]
  end

  defp operator_review_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
