defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePreservation.ReplayInput do
  @moduledoc false

  def input?(value) when is_list(value) do
    Enum.any?(value, &input?/1)
  end

  def input?(%{} = value) do
    artifact = stringify_keys(value)

    Map.get(artifact, "schema_contract") in [
      "timeline_preservation_report.v1",
      "timeline_preservation_status.v1"
    ] or
      direct_input?(artifact) or
      input?(Map.get(artifact, "candidate_source")) or
      input?(Map.get(artifact, "source_result_artifact")) or
      input?(Map.get(artifact, "result_artifact"))
  end

  def input?(_value), do: false

  def rows_with_source(refresh_or_artifact) do
    case candidate_source(refresh_or_artifact) do
      nil ->
        {rows(refresh_or_artifact), false}

      candidate_source ->
        branch_rows =
          candidate_source
          |> rows()
          |> Enum.map(&branch_replay_row/1)

        case branch_rows do
          [] -> {rows(refresh_or_artifact), false}
          rows -> {rows, true}
        end
    end
  end

  defp rows(refresh_or_artifact) do
    refresh_or_artifact
    |> package()
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "timeline_preservation_review"))
  end

  defp direct_input?(artifact) do
    [
      "source_timeline_preservation_report",
      "timeline_preservation_report",
      "source_timeline_preservation_status",
      "timeline_preservation_status"
    ]
    |> Enum.any?(fn key -> value?(Map.get(artifact, key)) end)
  end

  defp value?(value) when is_list(value),
    do: Enum.any?(value, &value?/1)

  defp value?(%{}), do: true
  defp value?(_value), do: false

  defp candidate_source(refresh_or_artifact) do
    artifact = stringify_keys(refresh_or_artifact)
    candidate_source = Map.get(artifact, "candidate_source")

    cond do
      is_map(candidate_source) and
          Map.has_key?(candidate_source, "candidate_refresh_request_source_report_summary") ->
        candidate_source

      Map.has_key?(artifact, "candidate_refresh_request_source_report_summary") ->
        artifact

      true ->
        nil
    end
  end

  defp branch_replay_row(%{} = row) do
    Map.update(row, "source", nil, fn
      source when is_binary(source) ->
        String.replace_prefix(
          source,
          "candidate_refresh.",
          "candidate_source.candidate_refresh_request."
        )

      source ->
        source
    end)
  end

  defp package(refresh_or_artifact) do
    artifact = stringify_keys(refresh_or_artifact)

    case Map.get(artifact, "schema_contract") do
      "timeline_preservation_report.v1" ->
        OrbitalDynamics.OperatorReview.from_timeline_preservation_report(artifact)

      "timeline_preservation_status.v1" ->
        OrbitalDynamics.OperatorReview.from_timeline_preservation_status(artifact)

      _schema_contract ->
        OrbitalDynamics.OperatorReview.from_candidate_refresh_artifact(artifact)
    end
  end

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
