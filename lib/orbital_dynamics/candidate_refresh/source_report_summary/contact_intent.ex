defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent do
  @moduledoc false

  alias __MODULE__.ContactIds
  alias __MODULE__.InputSummary

  defdelegate report_input_summary(sources), to: InputSummary
  defdelegate string_list_map_contact_ids(contact_ids_by_group), to: ContactIds
  defdelegate nested_string_list_map_contact_ids(contact_ids_by_outer_group), to: ContactIds
  defdelegate count_unique_contact_ids(contact_ids), to: ContactIds
end
