defmodule OrbitalDynamics.CampaignPlanner.ModelAcceptancePressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ModelAcceptanceSourceReports, ValueEncoding}

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
            "id" => "derived_model_acceptance_pressure_#{identity}",
            "label" => "Derived model-acceptance review #{identity}",
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
        "type" => "model_acceptance_pressure",
        "report_id" => row["report_id"],
        "intended_use" => row["intended_use"],
        "model_acceptance_status" => row["model_acceptance_status"],
        "model_count" => row["model_count"],
        "accepted_count" => row["accepted_count"],
        "review_required_count" => row["review_required_count"],
        "blocked_count" => row["blocked_count"],
        "unknown_model_count" => row["unknown_model_count"],
        "status_counts" => row["status_counts"],
        "validation_level_counts" => row["validation_level_counts"],
        "model_ids_by_status" => row["model_ids_by_status"],
        "model_ids_by_validation_level" => row["model_ids_by_validation_level"],
        "model_ids_by_intended_use" => row["model_ids_by_intended_use"],
        "model_id" => row["model_id"],
        "validation_level" => row["validation_level"],
        "model_status" => row["model_status"],
        "model_reason" => row["model_reason"],
        "required_operator_action" => pressure_action(row),
        "derivation_reasons" => ["model_acceptance_review"],
        "feedback_source" => source_path,
        "feedback_scope" => "model_acceptance",
        "feedback_key" => row["model_id"] || row["report_id"] || "model_acceptance",
        "trust_boundary" => operator_review_trust_boundary.(row),
        "source_model_acceptance_row" => row["source_model_acceptance_row"],
        "source_model_acceptance_report" => row["source_model_acceptance_report"]
      }
      |> compact_map.()
    end
  end

  def reviewable?(row),
    do:
      row["model_status"] in ["review_required", "blocked"] or
        row["validation_level"] == "unknown"

  def pressure_branches_from_sources(sources),
    do: pressure_branches_from_sources(sources, default_callbacks())

  def pressure_branches_from_sources(sources, opts) when is_list(opts) do
    sources
    |> ModelAcceptanceSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      pressure_branch(row, source_path, index, opts)
    end)
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      row["model_id"],
      row["report_id"],
      row["intended_use"],
      row["model_status"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp pressure_action(%{"model_status" => "blocked"}), do: "review_blocked_model_acceptance"
  defp pressure_action(_row), do: "review_model_acceptance"

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
