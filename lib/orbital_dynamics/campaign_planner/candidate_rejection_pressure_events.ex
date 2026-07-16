defmodule OrbitalDynamics.CampaignPlanner.CandidateRejectionPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ScalarValues, ValueEncoding}

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
            "id" => "derived_candidate_rejection_pressure_#{identity}",
            "label" => "Derived candidate-rejection review #{identity}",
            "events" => [event],
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_event(row, source_path), do: pressure_event(row, source_path, default_callbacks())

  def pressure_event(row, source_path, opts) when is_list(opts) do
    stable_id_string? = Keyword.fetch!(opts, :stable_id_string?)
    candidate_id = candidate_id(row)

    if stable_id_string?.(candidate_id) and reviewable?(row) do
      compact_map = Keyword.fetch!(opts, :compact_map)
      operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)

      %{
        "type" => "candidate_rejection_pressure",
        "candidate_id" => candidate_id,
        "activity_id" => row["activity_id"] || candidate_id,
        "activity_type" => row["activity_type"] || row["type"],
        "scenario_id" => row["scenario_id"] || get_in(row, ["activity_context", "scenario_id"]),
        "target_id" => row["target_id"] || get_in(row, ["activity_context", "target_id"]),
        "ground_station_id" =>
          row["ground_station_id"] || get_in(row, ["activity_context", "ground_station_id"]),
        "source_window_id" =>
          row["source_window_id"] || get_in(row, ["activity_context", "source_window_id"]),
        "source_window_type" =>
          row["source_window_type"] || get_in(row, ["activity_context", "source_window_type"]),
        "rejection_status" => row["rejection_status"],
        "primary_rejection_reason" => row["primary_rejection_reason"],
        "rejection_reasons" => row["rejection_reasons"],
        "violated_constraint" => row["violated_constraint"],
        "required_margin" => row["required_margin"],
        "actual_margin" => row["actual_margin"],
        "required_operator_action" => row["required_operator_action"],
        "derivation_reasons" => ["candidate_rejection_review"],
        "feedback_source" => source_path,
        "feedback_scope" => "candidate_rejection",
        "feedback_key" => candidate_id,
        "trust_boundary" => operator_review_trust_boundary.(row),
        "source_candidate_rejection" => Map.get(row, "source_candidate_rejection", row)
      }
      |> compact_map.()
    end
  end

  def candidate_id(row) do
    row["candidate_id"] ||
      row["activity_id"] ||
      get_in(row, ["source_candidate_rejection", "candidate_id"]) ||
      get_in(row, ["source_candidate_rejection", "activity_id"])
  end

  defp reviewable?(row) do
    row["rejection_status"] == "rejected" and
      row["reviewable"] == true and
      row["required_operator_action"] == "review_candidate_rejection"
  end

  defp pressure_identity(row, index, opts) do
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      candidate_id(row),
      row["activity_id"],
      row["id"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end

  defp default_callbacks,
    do: [
      stable_id_string?: &ScalarValues.stable_id_string?/1,
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
