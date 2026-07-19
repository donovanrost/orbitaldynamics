defmodule OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReviewSummary do
  @moduledoc false

  @counteroffer_schema_contract "provider_counteroffer_report.v1"
  @schema_contract "provider_counteroffer_review_summary.v1"

  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReport

  def build(report, opts) do
    report = stringify_keys(report)
    now_s = opts |> Keyword.get(:now_s) |> numeric_or_nil()

    rows =
      report
      |> ProviderCounterofferReport.rows()
      |> Enum.map(&put_deadline_status(&1, now_s))

    review_rows = Enum.filter(rows, &(&1["reviewable"] == true))

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_provider_counteroffer_review_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @counteroffer_schema_contract),
      "source" => report["source"],
      "source_counteroffer_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "counteroffer_count" => length(rows),
      "reviewable_count" => length(review_rows),
      "counteroffer_review_status" => if(review_rows == [], do: "clear", else: "review_required"),
      "counteroffer_status_counts" => count_by(rows, "provider_counteroffer_status"),
      "counteroffer_negotiation_state_counts" =>
        count_by(rows, "provider_counteroffer_negotiation_state"),
      "counteroffer_lock_deadline_count" =>
        numeric_value_count(rows, "provider_counteroffer_lock_deadline_s"),
      "earliest_counteroffer_lock_deadline_s" =>
        numeric_value_min(rows, "provider_counteroffer_lock_deadline_s"),
      "counteroffer_lock_deadline_status_counts" =>
        count_by(rows, "provider_counteroffer_lock_deadline_status"),
      "counteroffer_ids_by_lock_deadline_status" =>
        counteroffer_ids_by(rows, "provider_counteroffer_lock_deadline_status"),
      "expired_counteroffer_lock_deadline_count" =>
        Enum.count(rows, &(&1["provider_counteroffer_lock_deadline_status"] == "expired")),
      "active_counteroffer_lock_deadline_count" =>
        Enum.count(rows, &(&1["provider_counteroffer_lock_deadline_status"] == "active")),
      "missing_counteroffer_lock_deadline_count" =>
        Enum.count(rows, &(&1["provider_counteroffer_lock_deadline_status"] == "missing")),
      "review_counteroffer_ids" => counteroffer_ids(review_rows),
      "rows" => rows,
      "review_rows" => review_rows,
      "assumptions" =>
        %{
          "execution_boundary" => "artifact_only_no_provider_writes",
          "source" => "provider_counteroffer_report.v1",
          "operator_authority" => "not_granted_by_summary",
          "deadline_evaluation" =>
            if(is_number(now_s), do: "relative_to_now_s", else: "not_evaluated")
        }
        |> maybe_put("now_s", now_s)
    }
    |> compact_map()
  end

  def put_deadline_status(row, now_s) do
    deadline_s = numeric_or_nil(row["provider_counteroffer_lock_deadline_s"])

    status =
      cond do
        is_nil(deadline_s) ->
          "missing"

        is_number(now_s) and deadline_s < now_s ->
          "expired"

        is_number(now_s) ->
          "active"

        true ->
          "declared"
      end

    Map.put(row, "provider_counteroffer_lock_deadline_status", status)
  end

  defp numeric_value_count(rows, field), do: rows |> numeric_values(field) |> length()

  defp numeric_value_min(rows, field),
    do: rows |> numeric_values(field) |> Enum.min(fn -> nil end)

  defp numeric_values(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp counteroffer_ids(rows) do
    rows
    |> Enum.map(& &1["provider_counteroffer_id"])
    |> sorted_values()
  end

  defp counteroffer_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["provider_counteroffer_id"])
    |> Enum.reject(fn {value, _ids} -> is_nil(value) end)
    |> Map.new(fn {value, ids} -> {value, sorted_values(ids)} end)
  end

  defp sorted_values(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
