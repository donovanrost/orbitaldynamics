defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      entry_value = TimelineTransitionApplicationReports.stringify_keys(entry_value)

      cond do
        TimelineTransitionApplicationReports.summary?(entry_value) ->
          {entry_path, TimelineTransitionApplicationReports.report_from_summary(entry_value)}

        TimelineTransitionApplicationReports.report?(entry_value) ->
          {entry_path, entry_value}

        true ->
          nil
      end
    end)
  end
end
