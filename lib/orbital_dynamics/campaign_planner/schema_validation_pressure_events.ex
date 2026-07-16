defmodule OrbitalDynamics.CampaignPlanner.SchemaValidationPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{SchemaValidationSourceReports, ValueEncoding}

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
            "id" => "derived_schema_validation_pressure_#{identity}",
            "label" => "Derived schema-validation review #{identity}",
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
        "type" => "schema_validation_pressure",
        "validation_status" => row["validation_status"],
        "validation_mode" => row["validation_mode"],
        "validated_contract" => row["validated_contract"],
        "validated_artifact_family" => row["validated_artifact_family"],
        "artifact_path" => row["artifact_path"],
        "issue_severity" => row["issue_severity"],
        "issue_path" => row["issue_path"],
        "issue_message" => row["issue_message"],
        "error_count" => row["error_count"],
        "warning_count" => row["warning_count"],
        "remediation_count" => row["remediation_count"],
        "remediation_category" => row["remediation_category"],
        "remediation_action" => row["remediation_action"],
        "required_operator_action" => "review_schema_validation",
        "derivation_reasons" => ["schema_validation_review"],
        "feedback_source" => source_path,
        "feedback_scope" => "schema_validation",
        "feedback_key" => row["issue_path"] || row["validated_contract"] || "schema_validation",
        "trust_boundary" => operator_review_trust_boundary.(row),
        "source_validation_issue" => row["source_validation_issue"],
        "source_validation_remediation" => row["source_validation_remediation"],
        "source_schema_validation_report" => row["source_schema_validation_report"]
      }
      |> compact_map.()
    end
  end

  def reviewable?(row) do
    row["required_operator_action"] == "review_schema_validation" and
      row["issue_severity"] in ["error", "warning"]
  end

  def pressure_branches_from_sources(sources),
    do: pressure_branches_from_sources(sources, default_callbacks())

  def pressure_branches_from_sources(sources, opts) when is_list(opts) do
    sources
    |> SchemaValidationSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      pressure_branch(row, source_path, index, opts)
    end)
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      row["validated_contract"],
      row["issue_path"],
      row["artifact_path"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp default_callbacks,
    do: [
      operator_review_trust_boundary: &operator_review_trust_boundary/1,
      compact_map: &ValueEncoding.compact_map/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1
    ]

  defp operator_review_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
