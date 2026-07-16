defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields do
  @moduledoc false

  alias __MODULE__.LifecycleRows
  alias __MODULE__.PressureFields
  alias __MODULE__.ReviewRows
  alias __MODULE__.TransitionProvenance

  def put_derived(%{} = summary) do
    rows = LifecycleRows.all(summary)

    if rows == [] do
      summary
    else
      review_rows = LifecycleRows.review_required(rows)

      summary
      |> Map.merge(PressureFields.fields(rows))
      |> Map.merge(ReviewRows.fields(review_rows))
    end
  end

  def put_derived(summary), do: summary

  def review_rows(summary) do
    summary
    |> LifecycleRows.all()
    |> LifecycleRows.review_required()
  end

  def activity_ids(row) do
    PressureFields.activity_ids(row)
  end

  def transition_provenance_fields(summaries) do
    TransitionProvenance.fields(summaries)
  end
end
