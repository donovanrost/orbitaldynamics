defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.ContactNetworkFields.ContactFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields,
    as: ContactAllocationFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields,
    as: ContactFilterFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields,
    as: ContactIntentFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields,
    as: LinkCapacityFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields,
    as: ProviderCounterofferFields

  def source_report_fields(source_reports) do
    ProviderCounterofferFields.source_report_summary_fields(source_reports)
    |> Map.merge(ContactAllocationFields.source_report_summary_fields(source_reports))
    |> Map.merge(ContactIntentFields.source_report_fields(source_reports))
    |> Map.merge(LinkCapacityFields.source_report_summary_fields(source_reports))
    |> Map.merge(ContactFilterFields.source_report_summary_fields(source_reports))
  end
end
