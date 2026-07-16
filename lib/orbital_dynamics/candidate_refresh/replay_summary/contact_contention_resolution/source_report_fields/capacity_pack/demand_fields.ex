defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.CapacityPack.DemandFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Aggregation.Values
  alias __MODULE__.Rows

  def required_fraction(report) do
    case Rows.rows(report) do
      [] -> Values.numeric_report_count(report, "capacity_pack_required_capacity_fraction")
      rows -> Rows.total(rows)
    end
  end

  def selected_required_fraction(report) do
    case Rows.rows(report) do
      [] ->
        Values.numeric_report_count(report, "capacity_pack_selected_required_capacity_fraction")

      rows ->
        rows |> Enum.filter(&(&1.status == :selected)) |> Rows.total()
    end
  end

  def deferred_required_fraction(report) do
    case Rows.rows(report) do
      [] ->
        Values.numeric_report_count(report, "capacity_pack_deferred_required_capacity_fraction")

      rows ->
        rows |> Enum.filter(&(&1.status == :deferred)) |> Rows.total()
    end
  end

  def required_by_station(report) do
    case Rows.rows(report) do
      [] ->
        Map.get(report, "capacity_pack_required_capacity_fraction_by_ground_station") ||
          Map.get(report, "capacity_pack_required_capacity_fraction_by_ground_station_id")

      rows ->
        Rows.by_station(rows)
    end
  end

  def selected_by_station(report) do
    case Rows.rows(report) do
      [] ->
        Map.get(report, "capacity_pack_selected_required_capacity_fraction_by_ground_station") ||
          Map.get(
            report,
            "capacity_pack_selected_required_capacity_fraction_by_ground_station_id"
          )

      rows ->
        rows
        |> Enum.filter(&(&1.status == :selected))
        |> Rows.by_station()
    end
  end

  def deferred_by_station(report) do
    case Rows.rows(report) do
      [] ->
        Map.get(report, "capacity_pack_deferred_required_capacity_fraction_by_ground_station") ||
          Map.get(
            report,
            "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
          )

      rows ->
        rows
        |> Enum.filter(&(&1.status == :deferred))
        |> Rows.by_station()
    end
  end
end
