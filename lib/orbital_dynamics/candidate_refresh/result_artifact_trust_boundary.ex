defmodule OrbitalDynamics.CandidateRefresh.ResultArtifactTrustBoundary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common

  def inherit(reports, %{} = artifact) when is_list(reports) do
    Enum.map(reports, &inherit(&1, artifact))
  end

  def inherit(%{} = report, %{} = artifact) do
    report = stringify_keys(report)
    trust_boundary = boundary(artifact)

    if trust_boundary in [nil, ""] or
         OperationalFeedback.source_timeline_feedback_trust_boundaries(report) != [] do
      report
    else
      Map.update(
        report,
        "provenance",
        %{"trust_boundary" => encode_value(trust_boundary)},
        fn
          %{} = provenance ->
            Map.put_new(provenance, "trust_boundary", encode_value(trust_boundary))

          _provenance ->
            %{"trust_boundary" => encode_value(trust_boundary)}
        end
      )
    end
  end

  def inherit(report, _artifact), do: report

  def inherit_quality_gate(reports, %{} = artifact) when is_list(reports) do
    Enum.map(reports, &inherit_quality_gate(&1, artifact))
  end

  def inherit_quality_gate(%{} = report, %{} = artifact) do
    report = inherit(report, artifact)
    trust_boundary = boundary(artifact)

    if trust_boundary in [nil, ""] do
      report
    else
      Map.update(
        report,
        "trust_boundaries",
        [encode_value(trust_boundary)],
        fn trust_boundaries ->
          (list_value(trust_boundaries) ++ [encode_value(trust_boundary)])
          |> Common.sorted_string_values()
        end
      )
    end
  end

  def inherit_quality_gate(report, _artifact), do: report

  def boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
