defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.CapacityPack.DemandFields.Rows.CapacityFraction do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Aggregation.Values

  def required_capacity_fraction(contact) do
    contact
    |> first_number([
      "required_capacity_fraction",
      "required_station_capacity_fraction",
      "station_capacity_requirement",
      ["throughput_model", "required_capacity_fraction"],
      ["throughput_model", "required_station_capacity_fraction"],
      ["throughput_model", "station_capacity_requirement"],
      ["capacity_model", "required_capacity_fraction"],
      ["capacity_model", "required_station_capacity_fraction"],
      ["capacity_model", "station_capacity_requirement"],
      ["activity_context", "required_capacity_fraction"],
      ["activity_context", "required_station_capacity_fraction"],
      ["activity_context", "station_capacity_requirement"]
    ])
    |> capacity_unit_interval_or_nil()
    |> case do
      value when is_number(value) ->
        value

      _value ->
        contact
        |> first_number([
          "required_capacity_percent",
          "required_station_capacity_percent",
          "station_capacity_requirement_percent",
          ["throughput_model", "required_capacity_percent"],
          ["throughput_model", "required_station_capacity_percent"],
          ["throughput_model", "station_capacity_requirement_percent"],
          ["capacity_model", "required_capacity_percent"],
          ["capacity_model", "required_station_capacity_percent"],
          ["capacity_model", "station_capacity_requirement_percent"],
          ["activity_context", "required_capacity_percent"],
          ["activity_context", "required_station_capacity_percent"],
          ["activity_context", "station_capacity_requirement_percent"]
        ])
        |> capacity_percent_fraction_or_nil()
    end
  end

  defp first_number(row, paths) do
    paths
    |> Enum.find_value(fn
      path when is_list(path) -> row |> get_in(path) |> Values.numeric_value()
      path -> row |> Map.get(path) |> Values.numeric_value()
    end)
  end

  defp capacity_unit_interval_or_nil(value) do
    case Values.numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp capacity_percent_fraction_or_nil(value) do
    case Values.numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end
end
