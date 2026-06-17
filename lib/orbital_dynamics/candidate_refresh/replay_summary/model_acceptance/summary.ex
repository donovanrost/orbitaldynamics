defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance.Summary do
  @moduledoc false

  alias __MODULE__.Counts

  def pressure_fields(model_acceptance_summary) do
    review_required_count =
      Counts.status_count(model_acceptance_summary, "review_required")

    blocked_count = Counts.status_count(model_acceptance_summary, "blocked")

    unknown_model_count =
      Counts.validation_level_count(model_acceptance_summary, "unknown")

    status_counts = Map.get(model_acceptance_summary, "status_counts", %{})

    validation_level_counts =
      Counts.validation_level_counts(model_acceptance_summary)

    model_ids_by_status = Map.get(model_acceptance_summary, "model_ids_by_status", %{})

    model_ids_by_validation_level =
      Map.get(model_acceptance_summary, "model_ids_by_validation_level", %{})

    blocking_pressure =
      blocked_count > 0 or summary_integer(status_counts, "blocked") > 0 or
        Map.get(model_ids_by_status, "blocked", []) != []

    unknown_model_pressure =
      unknown_model_count > 0 or summary_integer(validation_level_counts, "unknown") > 0 or
        Map.get(model_ids_by_validation_level, "unknown", []) != []

    review_pressure =
      review_required_count > 0 or blocking_pressure or unknown_model_pressure or
        summary_integer(status_counts, "review_required") > 0 or
        Map.get(model_ids_by_status, "review_required", []) != []

    %{
      "branch_local_review_pressure" => review_pressure,
      "branch_local_blocking_pressure" => blocking_pressure,
      "branch_local_unknown_model_pressure" => unknown_model_pressure
    }
  end

  def summary(model_acceptance_summary, summary_source, replay_scope) do
    source_report_row_count =
      Counts.count(model_acceptance_summary, "row_count")

    model_count = Counts.count(model_acceptance_summary, "model_count")

    accepted_count = Counts.status_count(model_acceptance_summary, "accepted")

    review_required_count =
      Counts.status_count(model_acceptance_summary, "review_required")

    blocked_count = Counts.status_count(model_acceptance_summary, "blocked")

    unknown_model_count =
      Counts.validation_level_count(model_acceptance_summary, "unknown")

    status_counts = Map.get(model_acceptance_summary, "status_counts", %{})

    validation_level_counts =
      Counts.validation_level_counts(model_acceptance_summary)

    model_ids_by_status = Map.get(model_acceptance_summary, "model_ids_by_status", %{})

    model_ids_by_validation_level =
      Map.get(model_acceptance_summary, "model_ids_by_validation_level", %{})

    model_ids_by_intended_use =
      Map.get(model_acceptance_summary, "model_ids_by_intended_use", %{})

    pressure_fields = pressure_fields(model_acceptance_summary)

    %{
      "model" => "artifact_only_candidate_refresh_model_acceptance_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(model_acceptance_summary, "model_acceptance_report.v1"),
      "source_report_count" => summary_integer(model_acceptance_summary, "count"),
      "source_report_row_count" => source_report_row_count,
      "source_report_record_count" => summary_integer(model_acceptance_summary, "record_count"),
      "source_report_paths" => Map.get(model_acceptance_summary, "paths", []),
      "intended_use_counts" => Map.get(model_acceptance_summary, "intended_use_counts", %{}),
      "status_counts" => status_counts,
      "model_count" => model_count,
      "accepted_count" => accepted_count,
      "review_required_count" => review_required_count,
      "blocked_count" => blocked_count,
      "unknown_model_count" => unknown_model_count,
      "validation_level_counts" => validation_level_counts,
      "model_ids_by_status" => model_ids_by_status,
      "model_ids_by_validation_level" => model_ids_by_validation_level,
      "model_ids_by_intended_use" => model_ids_by_intended_use,
      "trust_boundary_status" => Map.get(model_acceptance_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(model_acceptance_summary, "trust_boundaries", []),
      "branch_local_review_pressure" => Map.get(pressure_fields, "branch_local_review_pressure"),
      "branch_local_blocking_pressure" =>
        Map.get(pressure_fields, "branch_local_blocking_pressure"),
      "branch_local_unknown_model_pressure" =>
        Map.get(pressure_fields, "branch_local_unknown_model_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_model_acceptance_replay_summary",
        "model_certification" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_model_acceptance_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
