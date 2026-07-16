defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewRowSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewRowEncoding

  def embedded_command_window(row) do
    row
    |> embedded_source()
    |> case do
      %{} = command_window -> CommandWindowReviewRowEncoding.stringify_keys(command_window)
      _command_window -> %{}
    end
  end

  defp embedded_source(row) do
    cond do
      is_map(row["source_command_window"]) ->
        row["source_command_window"]

      is_map(get_in(row, ["source_review_row", "source_command_window"])) ->
        get_in(row, ["source_review_row", "source_command_window"])

      true ->
        %{}
    end
  end
end
