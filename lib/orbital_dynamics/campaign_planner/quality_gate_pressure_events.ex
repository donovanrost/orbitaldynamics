defmodule OrbitalDynamics.CampaignPlanner.QualityGatePressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalReadinessSourceReports,
    QualityGateSourceReports,
    ValueEncoding
  }

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
            "id" => "derived_quality_gate_pressure_#{identity}",
            "label" => "Derived quality-gate review #{identity}",
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
        "type" => "quality_gate_pressure",
        "report_id" => row["report_id"],
        "source_artifact_type" => row["source_artifact_type"],
        "source_artifact_id" => row["source_artifact_id"],
        "source_readiness_report_id" => row["source_readiness_report_id"],
        "readiness_level" => row["readiness_level"],
        "import_classification" => row["import_classification"],
        "quality_gate_status" => row["quality_gate_status"],
        "gate_count" => row["gate_count"],
        "passed_gate_count" => row["passed_gate_count"],
        "review_gate_count" => row["review_gate_count"],
        "analysis_gate_count" => row["analysis_gate_count"],
        "blocked_gate_count" => row["blocked_gate_count"],
        "gate_id" => row["gate_id"],
        "gate_status" => row["gate_status"],
        "gate_classification" => row["gate_classification"],
        "gate_reason" => row["gate_reason"],
        "analysis_mode" => row["analysis_mode"],
        "analysis_mode_source" => row["analysis_mode_source"],
        "required_operator_action" => pressure_action(row["gate_classification"]),
        "derivation_reasons" => ["quality_gate_review"],
        "feedback_source" => source_path,
        "feedback_scope" => "quality_gate",
        "feedback_key" => row["gate_id"] || row["report_id"] || "quality_gate",
        "trust_boundary" => operator_review_trust_boundary.(row),
        "assumptions" => row["assumptions"],
        "source_quality_gate_row" => row["source_quality_gate_row"],
        "source_quality_gate_report" => row["source_quality_gate_report"]
      }
      |> Map.merge(OperationalReadinessSourceReports.operator_training_context(row))
      |> Map.merge(QualityGateSourceReports.import_readiness_context(row))
      |> Map.merge(QualityGateSourceReports.schema_validation_context(row))
      |> Map.merge(QualityGateSourceReports.resource_context(row))
      |> compact_map.()
    end
  end

  def reviewable?(row), do: row["gate_status"] not in [nil, "passed"]

  def pressure_branches_from_sources(sources),
    do: pressure_branches_from_sources(sources, default_callbacks())

  def pressure_branches_from_sources(sources, opts) when is_list(opts) do
    sources
    |> QualityGateSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      pressure_branch(row, source_path, index, opts)
    end)
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      row["gate_id"],
      row["report_id"],
      row["source_artifact_id"],
      row["gate_status"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp pressure_action("analysis_only"), do: "record_operational_readiness_analysis_only"
  defp pressure_action("blocked"), do: "review_blocked_operational_readiness"
  defp pressure_action(_classification), do: "review_operational_readiness"

  defp default_callbacks do
    [
      operator_review_trust_boundary: &operator_review_trust_boundary/1,
      compact_map: &ValueEncoding.compact_map/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1
    ]
  end

  defp operator_review_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
