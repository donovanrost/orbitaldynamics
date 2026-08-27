defmodule OrbitalDynamics.CandidateRefresh.BuildProvenance do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.BuildContext
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def build(
        refresh,
        result_set_metadata,
        operational_feedback_provenance,
        source_report_input_provenance,
        accepted_state_evidence_authority \\ nil
      ) do
    run = metadata_value(result_set_metadata, :run, :atom_first) || %{}
    run_metadata = metadata_value(run, :metadata) || %{}

    %{
      "accepted_planning_state" =>
        BuildContext.accepted_planning_state_provenance(
          refresh,
          accepted_state_evidence_authority
        ),
      "operational_feedback" => operational_feedback_provenance.(refresh),
      "prior_candidate_count" => length(Map.get(refresh, "prior_candidate_activities", [])),
      "run_id" => encode_value(metadata_value(run, :id)),
      "manifest" => encode_value(metadata_value(run_metadata, :manifest)),
      "git_revision" => encode_value(metadata_value(run_metadata, :git_revision)),
      "source_reports" => source_report_input_provenance.(refresh),
      "run_input_sources" => Map.get(refresh, "run_input_sources")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp metadata_value(metadata, key, preference \\ :string_first)

  defp metadata_value(metadata, key, :atom_first) when is_atom(key) do
    Map.get(metadata, key) || Map.get(metadata, Atom.to_string(key))
  end

  defp metadata_value(metadata, key, :string_first) when is_atom(key) do
    Map.get(metadata, Atom.to_string(key)) || Map.get(metadata, key)
  end

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
