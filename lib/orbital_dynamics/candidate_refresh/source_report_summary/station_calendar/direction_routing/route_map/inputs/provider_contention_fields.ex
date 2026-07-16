defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.RouteMap.Inputs.ProviderContentionFields do
  @moduledoc false

  def values(provider_contention_fields) do
    %{
      provider_contention_direction_counts:
        provider_contention_fields["provider_calendar_contention_direction_counts"],
      provider_contention_group_ids_by_direction:
        provider_contention_fields["provider_calendar_contention_group_ids_by_direction"],
      provider_contention_source_entry_ids_by_direction:
        provider_contention_fields["provider_calendar_contention_source_entry_ids_by_direction"],
      provider_contention_provider_ids_by_direction:
        provider_contention_fields["provider_calendar_contention_provider_ids_by_direction"],
      provider_contention_provider_entry_ids_by_direction:
        provider_contention_fields["provider_calendar_contention_provider_entry_ids_by_direction"],
      provider_contention_capacity_fractions_by_direction:
        provider_contention_fields[
          "provider_calendar_contention_capacity_fractions_by_direction"
        ]
    }
  end
end
