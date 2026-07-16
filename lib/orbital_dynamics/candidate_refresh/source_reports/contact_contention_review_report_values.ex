defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionReviewReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionReviewRows

  def invalid_input_row?(%{} = row) do
    row["invalid_contact_input"] == true or
      row["invalid_contact_input_reason"] not in [nil, ""]
  end

  def invalid_input_ids(invalid_inputs) do
    invalid_inputs
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&stable_id_or_nil(&1["contact_id"] || &1["id"] || &1["subject_id"]))
  end

  def result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil(value) when is_binary(value), do: if(value == "", do: nil, else: value)
  defp stable_id_or_nil(value) when is_atom(value), do: Atom.to_string(value)
  defp stable_id_or_nil(value) when is_integer(value), do: Integer.to_string(value)
  defp stable_id_or_nil(_value), do: nil

  defp stringify_keys(value), do: ContactContentionReviewRows.stringify_keys(value)
end
