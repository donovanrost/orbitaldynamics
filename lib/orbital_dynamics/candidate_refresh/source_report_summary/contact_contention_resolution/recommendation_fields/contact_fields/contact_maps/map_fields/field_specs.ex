defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ContactFields.ContactMaps.MapFields.FieldSpecs do
  @moduledoc false

  @string_list_map_fields [
    "selected_contact_ids_by_group_id",
    "deferred_contact_ids_by_group_id",
    "review_contact_ids_by_group_id",
    "selected_contact_ids_by_selection_reason",
    "selected_contact_ids_by_resource_scope",
    "deferred_contact_ids_by_resource_scope",
    "review_contact_ids_by_resource_scope"
  ]

  def string_list_map_fields, do: @string_list_map_fields
end
