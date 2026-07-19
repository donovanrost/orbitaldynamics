defmodule OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferHandoffSummary do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar.Availability
  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounteroffer
  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReport
  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReviewSummary

  @counteroffer_schema_contract "provider_counteroffer_report.v1"
  @counteroffer_import_readiness_summary_schema_contract "provider_counteroffer_import_readiness_summary.v1"
  @counteroffer_plan_impact_summary_schema_contract "provider_counteroffer_plan_impact_summary.v1"

  def import_readiness_summary(report, opts) do
    report = stringify_keys(report)
    now_s = opts |> Keyword.get(:now_s) |> numeric_or_nil()

    rows =
      report
      |> provider_counteroffer_report_rows()
      |> Enum.map(&ProviderCounterofferReviewSummary.put_deadline_status(&1, now_s))
      |> Enum.map(&put_provider_counteroffer_import_status/1)

    review_rows = Enum.filter(rows, &(&1["reviewable"] == true))
    no_import_rows = Enum.reject(rows, &(&1["reviewable"] == true))

    %{
      "schema_contract" => @counteroffer_import_readiness_summary_schema_contract,
      "model" => "artifact_only_provider_counteroffer_import_readiness_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @counteroffer_schema_contract),
      "source" => report["source"],
      "source_counteroffer_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "counteroffer_count" => length(rows),
      "reviewable_count" => length(review_rows),
      "import_readiness_status" => if(review_rows == [], do: "clear", else: "review_required"),
      "import_classification" => if(review_rows == [], do: "not_applicable", else: "review_only"),
      "ready_for_import_count" => 0,
      "review_required_before_import_count" => length(review_rows),
      "no_import_required_count" => length(no_import_rows),
      "counteroffer_status_counts" => count_by(rows, "provider_counteroffer_status"),
      "counteroffer_negotiation_state_counts" =>
        count_by(rows, "provider_counteroffer_negotiation_state"),
      "required_import_action_counts" => count_by(rows, "required_operator_action"),
      "provider_counteroffer_import_status_counts" =>
        count_by(rows, "provider_counteroffer_import_status"),
      "counteroffer_lock_deadline_status_counts" =>
        count_by(rows, "provider_counteroffer_lock_deadline_status"),
      "counteroffer_ids_by_required_import_action" =>
        counteroffer_ids_by(rows, "required_operator_action"),
      "counteroffer_ids_by_import_status" =>
        counteroffer_ids_by(rows, "provider_counteroffer_import_status"),
      "counteroffer_ids_by_lock_deadline_status" =>
        counteroffer_ids_by(rows, "provider_counteroffer_lock_deadline_status"),
      "review_counteroffer_ids" => counteroffer_ids(review_rows),
      "no_import_required_counteroffer_ids" => counteroffer_ids(no_import_rows),
      "import_readiness_rows" => rows,
      "assumptions" =>
        %{
          "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
          "source" => "provider_counteroffer_report.v1",
          "operator_authority" => "not_granted_by_import_readiness_summary",
          "provider_write" => "not_performed_by_summary",
          "cadence_write" => "not_performed_by_summary",
          "offer_acceptance" => "not_performed_by_summary",
          "deadline_evaluation" =>
            if(is_number(now_s), do: "relative_to_now_s", else: "not_evaluated")
        }
        |> maybe_put("now_s", now_s)
    }
    |> compact_map()
  end

  def plan_impact_summary(report, opts) do
    report = stringify_keys(report)
    now_s = opts |> Keyword.get(:now_s) |> numeric_or_nil()

    rows =
      report
      |> provider_counteroffer_report_rows()
      |> Enum.map(&ProviderCounterofferReviewSummary.put_deadline_status(&1, now_s))
      |> Enum.map(&provider_counteroffer_plan_impact_row/1)

    review_rows = Enum.filter(rows, &(&1["reviewable"] == true))
    shifted_rows = Enum.filter(rows, &provider_counteroffer_timing_shift?/1)

    cost_delta_rows =
      Enum.filter(rows, &is_number(numeric_or_nil(&1["provider_counteroffer_cost_delta"])))

    %{
      "schema_contract" => @counteroffer_plan_impact_summary_schema_contract,
      "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @counteroffer_schema_contract),
      "source" => report["source"],
      "source_counteroffer_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "counteroffer_count" => length(rows),
      "reviewable_count" => length(review_rows),
      "plan_impact_status" => if(review_rows == [], do: "clear", else: "review_required"),
      "timing_shift_counteroffer_count" => length(shifted_rows),
      "counteroffer_cost_delta_count" =>
        numeric_value_count(rows, "provider_counteroffer_cost_delta"),
      "counteroffer_cost_delta_total" =>
        numeric_value_sum(rows, "provider_counteroffer_cost_delta"),
      "counteroffer_lock_deadline_status_counts" =>
        count_by(rows, "provider_counteroffer_lock_deadline_status"),
      "affected_station_calendar_entry_ids" =>
        rows |> Enum.map(& &1["station_calendar_entry_id"]) |> sorted_values(),
      "affected_provider_entry_ids" =>
        rows |> Enum.map(& &1["station_calendar_provider_entry_id"]) |> sorted_values(),
      "impact_counteroffer_ids" => counteroffer_ids(review_rows),
      "timing_shift_counteroffer_ids" => counteroffer_ids(shifted_rows),
      "cost_delta_counteroffer_ids" => counteroffer_ids(cost_delta_rows),
      "counteroffer_ids_by_lock_deadline_status" =>
        counteroffer_ids_by(rows, "provider_counteroffer_lock_deadline_status"),
      "rows" => rows,
      "impact_rows" => review_rows,
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

  defp provider_counteroffer_plan_impact_row(row) do
    row
    |> Map.put(
      "provider_counteroffer_start_delta_s",
      numeric_delta(row["provider_counteroffer_starts_at_s"], row["starts_at_s"])
    )
    |> Map.put(
      "provider_counteroffer_end_delta_s",
      numeric_delta(row["provider_counteroffer_ends_at_s"], row["ends_at_s"])
    )
    |> Map.put(
      "provider_counteroffer_duration_delta_s",
      duration_delta(row)
    )
    |> compact_map()
  end

  defp put_provider_counteroffer_import_status(%{"reviewable" => true} = row),
    do: Map.put(row, "provider_counteroffer_import_status", "review_required_before_import")

  defp put_provider_counteroffer_import_status(row),
    do: Map.put(row, "provider_counteroffer_import_status", "not_applicable")

  defp provider_counteroffer_timing_shift?(row) do
    Enum.any?(
      [
        row["provider_counteroffer_start_delta_s"],
        row["provider_counteroffer_end_delta_s"],
        row["provider_counteroffer_duration_delta_s"]
      ],
      fn value -> is_number(value) and value != 0.0 end
    )
  end

  def duration_delta(row) do
    with start when is_number(start) <- numeric_or_nil(row["starts_at_s"]),
         finish when is_number(finish) <- numeric_or_nil(row["ends_at_s"]),
         counter_start when is_number(counter_start) <-
           provider_counteroffer_starts_at_s(row),
         counter_finish when is_number(counter_finish) <-
           provider_counteroffer_ends_at_s(row) do
      counter_finish - counter_start - (finish - start)
    else
      _value -> nil
    end
  end

  def numeric_delta(left, right) do
    with left when is_number(left) <- numeric_or_nil(left),
         right when is_number(right) <- numeric_or_nil(right) do
      left - right
    else
      _value -> nil
    end
  end

  defp provider_counteroffer_report_rows(report) do
    ProviderCounterofferReport.rows(report)
  end

  defp numeric_value_count(rows, field) do
    rows
    |> numeric_values(field)
    |> length()
  end

  defp numeric_value_sum(rows, field) do
    rows
    |> numeric_values(field)
    |> Enum.sum()
  end

  defp numeric_values(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
  end

  defp provider_counteroffer_starts_at_s(entry),
    do: ProviderCounteroffer.starts_at_s(entry)

  defp provider_counteroffer_ends_at_s(entry),
    do: ProviderCounteroffer.ends_at_s(entry)

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
    |> Enum.reject(fn {key, _ids} -> is_nil(key) end)
    |> Map.new(fn {key, ids} -> {key, sorted_values(ids)} end)
  end

  defp sorted_values(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp numeric_or_nil(value), do: Availability.numeric_or_nil(value)

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
