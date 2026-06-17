defmodule OrbitalDynamics.CampaignPlanner.CommandWindowOperationalFeedback do
  @moduledoc false

  def from_reports(reports_with_sources, opts) when is_list(opts) do
    reports_with_sources
    |> rows(opts)
    |> from_rows(opts)
  end

  def rows(reports_with_sources, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    feedback_row? = Keyword.fetch!(opts, :feedback_row?)

    reports_with_sources
    |> Enum.flat_map(fn {report, _source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> Map.get("rows", [])
      |> Enum.map(stringify_keys)
      |> Enum.map(&Map.put_new(&1, "_source_report_trust_boundary", trust_boundary))
    end)
    |> Enum.filter(feedback_row?)
  end

  def from_rows(rows, opts) when is_list(opts) do
    row_success_value = Keyword.fetch!(opts, :row_success_value)
    activity_feedback_average = Keyword.fetch!(opts, :activity_feedback_average)

    rates = activity_feedback_average.(rows, row_success_value)

    case rates do
      rates when map_size(rates) > 0 -> %{"command_success_rate" => rates}
      _rates -> %{}
    end
  end

  def source(%{"source_command_window" => %{} = source} = row, opts)
      when map_size(source) > 0 and is_list(opts) do
    {row(source, row, opts), "source_command_window"}
  end

  def source(row, opts) when is_list(opts), do: {row(row, row, opts), "command_window_review"}

  def operator_review_rows(rows, opts) when is_list(opts) do
    rows
    |> Enum.filter(&(&1["review_type"] == "command_window_review"))
    |> Enum.map(fn row ->
      row(Map.get(row, "source_command_window", row), row, opts)
    end)
  end

  def row(source, row, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    put_default_if_present = Keyword.fetch!(opts, :put_default_if_present)
    put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)

    source
    |> stringify_keys.()
    |> put_default_if_present.("activity_id", row["activity_id"])
    |> put_default_if_present.("id", row["activity_id"])
    |> put_default_if_present.("type", row["activity_type"])
    |> put_default_if_present.("scenario_id", row["scenario_id"])
    |> put_default_if_present.("timeline_id", row["timeline_id"])
    |> put_default_if_present.("starts_at_s", row["starts_at_s"])
    |> put_default_if_present.("ends_at_s", row["ends_at_s"])
    |> put_default_if_present.("direction", row["direction"])
    |> put_default_if_present.("ground_station_id", row["ground_station_id"])
    |> put_default_if_present.("station_id", row["station_id"])
    |> put_default_if_present.("command_success_factor", row["command_success_factor"])
    |> put_default_if_present.("command_success", row["command_success"])
    |> put_default_if_present.("command_result", row["command_result"])
    |> put_default_if_present.("required_operator_action", row["required_operator_action"])
    |> put_default_if_present.("cadence_import_status", row["cadence_import_status"])
    |> put_default_if_present.("trust_boundary", row["trust_boundary"])
    |> put_default_if_present.("provenance", row["provenance"])
    |> put_default_if_present.("station_availability", row["station_availability"])
    |> put_default_if_present.("station_contention_status", row["station_contention_status"])
    |> put_default_if_present.("station_calendar_entry_id", row["station_calendar_entry_id"])
    |> put_default_if_present.(
      "station_calendar_provider_id",
      row["station_calendar_provider_id"]
    )
    |> put_default_if_present.(
      "station_calendar_provider_entry_id",
      row["station_calendar_provider_entry_id"]
    )
    |> put_default_if_present.("station_calendar_directions", row["station_calendar_directions"])
    |> put_default_if_present.("station_calendar_status", row["station_calendar_status"])
    |> put_default_if_present.(
      "station_calendar_trust_boundary_status",
      row["station_calendar_trust_boundary_status"]
    )
    |> put_default_if_present.("station_reservation_id", row["station_reservation_id"])
    |> put_default_if_present.("station_reserved_by", row["station_reserved_by"])
    |> put_default_if_present.("station_reservation_status", row["station_reservation_status"])
    |> put_default_if_present.(
      "station_reservation_match_status",
      row["station_reservation_match_status"]
    )
    |> put_feedback_weight_fields.(row)
  end

  def feedback_row?(row, opts) when is_list(opts) do
    command_activity? = Keyword.fetch!(opts, :command_activity?)
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)

    command_activity?.(row) and realized_feedback_activity_id.(row) not in [nil, ""] and
      not is_nil(success_value(row, opts))
  end

  def success_value(row, opts) when is_list(opts) do
    unit_interval_number_or_nil = Keyword.fetch!(opts, :unit_interval_number_or_nil)
    command_success_value = Keyword.fetch!(opts, :command_success_value)

    case unit_interval_number_or_nil.(row["command_success_factor"]) do
      value when is_number(value) -> value
      _value -> command_success_value.(row)
    end
  end

  def pressure_branch(row, source_path, index, opts) when is_list(opts) do
    case pressure_event(row, source_path, opts) do
      nil ->
        []

      event ->
        [
          %{
            "id" => pressure_branch_id(row, index, opts),
            "label" => "Derived command-window feedback #{pressure_identity(row, index, opts)}",
            "events" => [event],
            "metadata" => %{"derived_source" => source_path}
          }
        ]
    end
  end

  def pressure_event(row, source_path, opts) when is_list(opts) do
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    activity_raw_start = Keyword.fetch!(opts, :activity_raw_start)
    activity_raw_end = Keyword.fetch!(opts, :activity_raw_end)
    clamp_unit_interval = Keyword.fetch!(opts, :clamp_unit_interval)
    provider_result_artifact_value = Keyword.fetch!(opts, :provider_result_artifact_value)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    operator_review_trust_boundary = Keyword.fetch!(opts, :operator_review_trust_boundary)
    put_feedback_weight_fields = Keyword.fetch!(opts, :put_feedback_weight_fields)
    compact_map = Keyword.fetch!(opts, :compact_map)

    with value when is_number(value) <- success_value(row, opts),
         true <- value < 1.0,
         activity_id when activity_id not in [nil, ""] <- realized_feedback_activity_id.(row) do
      %{
        "type" => "command_success_feedback",
        "activity_id" => activity_id,
        "scenario_id" => row["scenario_id"],
        "starts_at_s" => activity_raw_start.(row) || 0.0,
        "ends_at_s" => activity_raw_end.(row),
        "command_success_factor" => clamp_unit_interval.(value),
        "command_result" => provider_result_artifact_value.(row["command_result"]),
        "required_operator_action" => row["required_operator_action"],
        "cadence_import_status" => row["cadence_import_status"],
        "timeline_id" => explicit_timeline_id.(row),
        "direction" => row["direction"],
        "ground_station_id" => row["ground_station_id"] || row["station_id"],
        "station_id" => row["station_id"],
        "station_availability" => row["station_availability"],
        "station_contention_status" => row["station_contention_status"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_calendar_status" => row["station_calendar_status"],
        "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "derivation_reasons" => pressure_reasons(row, opts),
        "feedback_source" => source_path,
        "feedback_scope" => "command_window",
        "feedback_key" => activity_id,
        "trust_boundary" => operator_review_trust_boundary.(row)
      }
      |> put_feedback_weight_fields.(row)
      |> compact_map.()
    else
      _missing -> nil
    end
  end

  def feedback_trust_boundaries(rows, opts) when is_list(opts) do
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    put_feedback_trust_boundary = Keyword.fetch!(opts, :put_feedback_trust_boundary)

    command_boundaries =
      rows
      |> Enum.reduce(%{}, fn row, boundaries ->
        activity_id = realized_feedback_activity_id.(row)
        trust_boundary = feedback_trust_boundary(row)

        if activity_id in [nil, ""] or trust_boundary in [nil, ""] do
          boundaries
        else
          put_feedback_trust_boundary.(
            boundaries,
            "command_success_rate",
            activity_id,
            [trust_boundary]
          )
        end
      end)
      |> Map.get("command_success_rate")

    case command_boundaries do
      %{} = boundaries -> %{"command_success_rate" => boundaries}
      _boundaries -> nil
    end
  end

  defp feedback_trust_boundary(row) do
    row["trust_boundary"] ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp pressure_reasons(row, opts) do
    provider_result_values = Keyword.fetch!(opts, :provider_result_values)

    ["command_window_review_feedback"]
    |> Kernel.++(provider_result_values.(row["command_result"]))
    |> Kernel.++([
      row["required_operator_action"],
      row["station_availability"],
      row["station_calendar_status"],
      row["station_reservation_match_status"]
    ])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp pressure_branch_id(row, index, opts),
    do: "derived_command_window_feedback_#{pressure_identity(row, index, opts)}"

  defp pressure_identity(row, index, opts) do
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    explicit_timeline_id = Keyword.fetch!(opts, :explicit_timeline_id)
    branch_id_fragment = Keyword.fetch!(opts, :branch_id_fragment)

    [
      realized_feedback_activity_id.(row),
      explicit_timeline_id.(row),
      row["id"],
      index
    ]
    |> Enum.find(&(&1 not in [nil, ""]))
    |> branch_id_fragment.()
  end
end
