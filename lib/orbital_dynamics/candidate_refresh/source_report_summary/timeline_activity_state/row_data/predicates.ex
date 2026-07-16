defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData.Predicates do
  @moduledoc false

  def review_required?(%{} = row) do
    Map.get(row, "review_required") == true or
      Map.get(row, "requires_operator_review") == true
  end

  def review_required?(_row), do: false

  def present_action?(%{} = row), do: present_action?(Map.get(row, "required_operator_action"))
  def present_action?(action) when action in [nil, "", "none"], do: false
  def present_action?(_action), do: true
end
