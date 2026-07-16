defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewEmbeddedRowSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewEmbeddedRowEncoding

  def embedded_review(row) do
    row
    |> embedded_source()
    |> case do
      %{} = maneuver_review -> ManeuverReviewEmbeddedRowEncoding.stringify_keys(maneuver_review)
      _maneuver_review -> %{}
    end
  end

  defp embedded_source(row) do
    cond do
      is_map(row["source_maneuver_review"]) ->
        row["source_maneuver_review"]

      is_map(get_in(row, ["source_review_row", "source_maneuver_review"])) ->
        get_in(row, ["source_review_row", "source_maneuver_review"])

      true ->
        %{}
    end
  end
end
