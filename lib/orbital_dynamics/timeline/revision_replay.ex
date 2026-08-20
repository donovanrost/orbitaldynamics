defmodule OrbitalDynamics.Timeline.RevisionReplay do
  @moduledoc false

  @schema_contract "timeline_revision.v1"
  @identity_scheme "sha256_canonical_json"
  @canonicalization "timeline_revision_content.v1"
  @revision_id_prefix "timeline_revision.sha256:"
  @batch_id_prefix "timeline_transition_batch.sha256:"

  def schema_contract, do: @schema_contract
  def identity_scheme, do: @identity_scheme
  def canonicalization, do: @canonicalization

  def put_revision_evidence(
        report,
        source_activities,
        opts,
        normalize_activities
      )
      when is_map(report) and is_list(source_activities) and is_list(opts) and
             is_function(normalize_activities, 2) do
    if Keyword.get(opts, :timeline_revision?, false) do
      evidence =
        revision_evidence(
          source_activities,
          Map.get(report, "applications", []),
          Map.get(report, "selected_activities", []),
          opts,
          normalize_activities
        )

      report
      |> Map.update("applications", [], fn applications ->
        Enum.map(applications, &Map.put(&1, "timeline_revision", evidence))
      end)
      |> Map.put("timeline_revision", evidence)
    else
      report
    end
  end

  def replay(
        source_activities,
        replacement_activities,
        replay_report,
        opts,
        report_builder,
        normalize_activities
      )
      when is_list(source_activities) and is_list(replacement_activities) and is_list(opts) and
             is_function(report_builder, 3) and is_function(normalize_activities, 2) do
    with {:ok, expected} <- replay_evidence(replay_report),
         actual_prior_revision_id <-
           revision_id(source_activities, opts, normalize_activities),
         :ok <- prior_revision_matches(expected, actual_prior_revision_id),
         actual_report <-
           report_builder.(
             source_activities,
             replacement_activities,
             Keyword.put(opts, :timeline_revision?, true)
           ),
         {:ok, actual} <- replay_evidence(actual_report),
         :ok <- transition_batch_matches(expected, actual),
         :ok <- replacement_revision_matches(expected, actual) do
      {:ok, actual_report}
    end
  end

  def replay(
        _source_activities,
        _replacement_activities,
        _replay_report,
        _opts,
        _builder,
        _normalizer
      ) do
    {:error,
     %{
       "error_type" => "invalid_replay_input",
       "reason" =>
         "source and replacement activities must be lists and options must be a keyword list"
     }}
  end

  def revision_evidence(
        source_activities,
        applications,
        selected_activities,
        opts,
        normalize_activities
      ) do
    %{
      "schema_contract" => @schema_contract,
      "identity_scheme" => @identity_scheme,
      "canonicalization" => @canonicalization,
      "prior_revision_id" => revision_id(source_activities, opts, normalize_activities),
      "transition_batch_id" =>
        content_id(@batch_id_prefix, canonical_timeline_order(applications)),
      "replacement_revision_id" =>
        content_id(@revision_id_prefix, canonical_timeline_order(selected_activities))
    }
  end

  def replay_evidence(
        %{
          "schema_contract" => "timeline_transition_application_report.v1",
          "timeline_revision" => %{} = evidence
        } = report
      ) do
    with {:ok, evidence} <- validate_evidence(evidence),
         :ok <- validate_replay_row_copies(report, evidence) do
      {:ok, evidence}
    end
  end

  def replay_evidence(%{schema_contract: "timeline_transition_application_report.v1"} = report) do
    report
    |> stringify_keys()
    |> replay_evidence()
  end

  def replay_evidence(
        %{"schema_contract" => "timeline_transition_application_report.v1"} = report
      ) do
    if Map.has_key?(report, "timeline_revision") do
      invalid_evidence("malformed_timeline_revision", "$.timeline_revision")
    else
      invalid_evidence("missing_timeline_revision", "$.timeline_revision")
    end
  end

  def replay_evidence(%{}),
    do: invalid_evidence("invalid_transition_application_report", "$.schema_contract")

  def replay_evidence(_value),
    do: invalid_evidence("transition_application_report_must_be_an_object", "$")

  defp revision_id(activities, opts, normalize_activities) do
    activities
    |> normalize_activities.(opts)
    |> canonical_timeline_order()
    |> then(&content_id(@revision_id_prefix, &1))
  end

  defp canonical_timeline_order(rows) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.sort_by(fn row ->
      {
        Map.get(row, "timeline_id", ""),
        Map.get(row, "activity_id", ""),
        Map.get(row, "id", ""),
        IO.iodata_to_binary(canonical_json(row))
      }
    end)
  end

  defp content_id(prefix, value) do
    digest =
      value
      |> canonical_json()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    prefix <> digest
  end

  defp canonical_json(%{} = map) do
    entries =
      map
      |> Enum.map(fn {key, value} -> {encode_key(key), value} end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {key, value} -> [:json.encode(key), ?:, canonical_json(value)] end)

    [?{, Enum.intersperse(entries, ?,), ?}]
  end

  defp canonical_json(values) when is_list(values) do
    [?[, values |> Enum.map(&canonical_json/1) |> Enum.intersperse(?,), ?]]
  end

  defp canonical_json(nil), do: :json.encode(nil)
  defp canonical_json(value) when is_boolean(value), do: :json.encode(value)
  defp canonical_json(value) when is_atom(value), do: :json.encode(Atom.to_string(value))
  defp canonical_json(value), do: :json.encode(value)

  defp encode_key(key) when is_binary(key), do: key
  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: to_string(key)

  defp validate_evidence(evidence) do
    required = %{
      "schema_contract" => @schema_contract,
      "identity_scheme" => @identity_scheme,
      "canonicalization" => @canonicalization
    }

    cond do
      Enum.any?(required, fn {field, expected} -> Map.get(evidence, field) != expected end) ->
        invalid_evidence("malformed_timeline_revision", "$.timeline_revision")

      not valid_id?(evidence["prior_revision_id"], @revision_id_prefix) ->
        invalid_evidence("malformed_prior_revision_id", "$.timeline_revision.prior_revision_id")

      not valid_id?(evidence["transition_batch_id"], @batch_id_prefix) ->
        invalid_evidence(
          "malformed_transition_batch_id",
          "$.timeline_revision.transition_batch_id"
        )

      not valid_id?(evidence["replacement_revision_id"], @revision_id_prefix) ->
        invalid_evidence(
          "malformed_replacement_revision_id",
          "$.timeline_revision.replacement_revision_id"
        )

      true ->
        {:ok, evidence}
    end
  end

  defp valid_id?(value, prefix) when is_binary(value) do
    String.starts_with?(value, prefix) and byte_size(value) == byte_size(prefix) + 64 and
      value
      |> binary_part(byte_size(prefix), 64)
      |> String.match?(~r/^[0-9a-f]{64}$/)
  end

  defp valid_id?(_value, _prefix), do: false

  defp prior_revision_matches(expected, actual_prior_revision_id) do
    if expected["prior_revision_id"] == actual_prior_revision_id do
      :ok
    else
      {:error,
       %{
         "error_type" => "revision_conflict",
         "conflict_scope" => "prior_revision",
         "expected_prior_revision_id" => expected["prior_revision_id"],
         "actual_prior_revision_id" => actual_prior_revision_id
       }}
    end
  end

  defp validate_replay_row_copies(report, evidence) do
    report
    |> Map.get("applications", [])
    |> Enum.with_index()
    |> Enum.find_value(:ok, fn
      {%{"timeline_revision" => ^evidence}, _index} ->
        false

      {%{}, index} ->
        {:error,
         %{
           "error_type" => "invalid_replay_evidence",
           "reason" => "application_revision_evidence_mismatch",
           "path" => "$.applications[#{index}].timeline_revision"
         }}

      {_row, _index} ->
        false
    end)
  end

  defp transition_batch_matches(expected, actual) do
    if expected["transition_batch_id"] == actual["transition_batch_id"] do
      :ok
    else
      {:error,
       %{
         "error_type" => "batch_conflict",
         "conflict_scope" => "transition_batch",
         "expected_transition_batch_id" => expected["transition_batch_id"],
         "actual_transition_batch_id" => actual["transition_batch_id"]
       }}
    end
  end

  defp replacement_revision_matches(expected, actual) do
    if expected["replacement_revision_id"] == actual["replacement_revision_id"] do
      :ok
    else
      {:error,
       %{
         "error_type" => "revision_conflict",
         "conflict_scope" => "replacement_revision",
         "expected_replacement_revision_id" => expected["replacement_revision_id"],
         "actual_replacement_revision_id" => actual["replacement_revision_id"]
       }}
    end
  end

  defp invalid_evidence(reason, path) do
    {:error,
     %{
       "error_type" => "invalid_replay_evidence",
       "reason" => reason,
       "path" => path
     }}
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
