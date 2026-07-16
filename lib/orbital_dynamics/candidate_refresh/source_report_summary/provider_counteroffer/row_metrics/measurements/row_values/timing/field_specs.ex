defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.RowValues.Timing.FieldSpecs do
  @moduledoc false

  @timing_delta_fields ~w(
    provider_counteroffer_start_delta_s
    provider_counteroffer_end_delta_s
    provider_counteroffer_duration_delta_s
  )

  def timing_delta_fields, do: @timing_delta_fields
end
