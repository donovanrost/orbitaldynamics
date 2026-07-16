defmodule OrbitalDynamics.CampaignPlanner.ValidationSafetyCasePressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ValidationSafetyCaseSourceReports, ValueEncoding}

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
            "id" => "derived_validation_safety_case_pressure_#{identity}",
            "label" => "Derived validation safety-case review #{identity}",
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
        "type" => "validation_safety_case_pressure",
        "report_id" => row["report_id"],
        "validation_safety_case_status" => row["validation_safety_case_status"],
        "evidence_status" => row["evidence_status"],
        "input_contract" => row["input_contract"],
        "input_contracts" => row["input_contracts"],
        "evidence_ref" => row["evidence_ref"],
        "evidence_count" => row["evidence_count"],
        "accepted_evidence_count" => row["accepted_evidence_count"],
        "review_required_evidence_count" => row["review_required_evidence_count"],
        "blocked_evidence_count" => row["blocked_evidence_count"],
        "schema_error_count" => row["schema_error_count"],
        "schema_warning_count" => row["schema_warning_count"],
        "model_blocked_count" => row["model_blocked_count"],
        "quality_gate_review_count" => row["quality_gate_review_count"],
        "quality_gate_blocked_count" => row["quality_gate_blocked_count"],
        "evidence_status_counts" => row["evidence_status_counts"],
        "evidence_refs_by_status" => row["evidence_refs_by_status"],
        "evidence_refs_by_contract" => row["evidence_refs_by_contract"],
        "required_operator_action" => pressure_action(row),
        "derivation_reasons" => ["validation_safety_case_review"],
        "feedback_source" => source_path,
        "feedback_scope" => "validation_safety_case",
        "feedback_key" =>
          row["evidence_ref"] || row["input_contract"] || row["report_id"] ||
            "validation_safety_case",
        "trust_boundary" => operator_review_trust_boundary.(row),
        "source_validation_safety_case_evidence" => row["source_validation_safety_case_evidence"],
        "source_validation_safety_case_summary" => row["source_validation_safety_case_summary"]
      }
      |> compact_map.()
    end
  end

  def reviewable?(row),
    do:
      row["evidence_status"] in ["review_required", "blocked"] or
        row["validation_safety_case_status"] in ["review_required", "blocked"]

  def pressure_branches_from_sources(sources),
    do: pressure_branches_from_sources(sources, default_callbacks())

  def pressure_branches_from_sources(sources, opts) when is_list(opts) do
    sources
    |> ValidationSafetyCaseSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      pressure_branch(row, source_path, index, opts)
    end)
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      row["evidence_ref"],
      row["input_contract"],
      row["report_id"],
      row["evidence_status"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp pressure_action(%{"evidence_status" => "blocked"}),
    do: "review_blocked_validation_safety_case"

  defp pressure_action(%{"validation_safety_case_status" => "blocked"}),
    do: "review_blocked_validation_safety_case"

  defp pressure_action(_row), do: "review_validation_safety_case"

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
