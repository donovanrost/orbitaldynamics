defmodule OrbitalDynamics.MissionAnalysis.Opportunity.Endpoints do
  @moduledoc false
  alias OrbitalDynamics.EventSearch.{Context, Function, Source}

  def check(windows, evaluation, source, remaining) do
    previous = Context.current()

    try do
      Context.open(remaining)

      {windows, samples} =
        Enum.map_reduce(windows, [], fn w, samples ->
          if w["status"] == "accepted" do
            probes =
              for t <- [w["starts_at_s"], w["ends_at_s"]] do
                with {:ok, state} <- Source.at(source, t),
                     {:ok, _, _, sample} <- Function.call(evaluation, state) do
                  Map.put(sample, "epoch_s", t)
                else
                  {:unknown, reason} ->
                    %{
                      "epoch_s" => t,
                      "feasible" => false,
                      "checks" => [
                        %{
                          "id" => "opportunity_endpoint_unknown",
                          "passed" => false,
                          "reason" => inspect(reason)
                        }
                      ],
                      "metrics" => %{}
                    }
                end
              end

            passed = Enum.all?(probes, & &1["feasible"])

            {Map.merge(w, %{
               "status" => if(passed, do: "accepted", else: "rejected"),
               "reason" => if(passed, do: "accepted", else: "candidate_endpoint_not_eligible"),
               "endpoint_checks" => probes
             }), probes ++ samples}
          else
            {w, samples}
          end
        end)

      {:ok, windows, samples, Context.counts()}
    catch
      {:event_search_failed, reason} -> {:error, reason}
    after
      Context.restore(previous)
    end
  end
end
