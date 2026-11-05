defmodule OrbitalDynamics.MissionAnalysis.Scheduling.CommandDelivery do
  @moduledoc "Bounded bridge to existing station calendars, contact allocation and command-window artifacts. Feasibility only."
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  alias OrbitalDynamics.Communications.{StationCalendar, ContactAllocation, CommandWindow}

  def validate!(nil), do: nil

  def validate!(c) do
    S.fields!(
      c,
      ~w(time_scale source_id contacts station_calendar requirements receipts),
      "command delivery"
    )

    unless c["time_scale"] in ~w(utc tai tdb),
      do: raise(ArgumentError, "command time scale required")

    Input.id!(c["source_id"])

    for {key, max} <- [
          {"contacts", 128},
          {"station_calendar", 128},
          {"requirements", 100},
          {"receipts", 100}
        ] do
      unless is_list(c[key]) and length(c[key]) <= max,
        do: raise(ArgumentError, "bounded command #{key} required")
    end

    Enum.each(c["contacts"], fn x ->
      S.fields!(
        x,
        ~w(id type scenario_id ground_station_id starts_at_s ends_at_s source_window_id score),
        "declared command contact"
      )

      Enum.each(~w(id scenario_id ground_station_id source_window_id), &Input.id!(x[&1]))

      unless x["type"] == "command",
        do: raise(ArgumentError, "command contacts must have command type")

      a = Input.number!(x["starts_at_s"], "contact start", -1.0e12, 1.0e12)
      b = Input.number!(x["ends_at_s"], "contact end", -1.0e12, 1.0e12)
      unless b > a, do: raise(ArgumentError, "contact duration must be positive")
      Input.number!(x["score"], "contact priority", 0, 1.0e12)
    end)

    unique!(c["contacts"], "id")

    Enum.each(c["station_calendar"], fn x ->
      S.fields!(
        x,
        ~w(ground_station_id status starts_at_s ends_at_s),
        "declared station interval"
      )

      Input.id!(x["ground_station_id"])

      unless x["status"] in ~w(available unavailable maintenance),
        do: raise(ArgumentError, "unsupported station status")

      a = Input.number!(x["starts_at_s"], "station start", -1.0e12, 1.0e12)
      b = Input.number!(x["ends_at_s"], "station end", -1.0e12, 1.0e12)
      unless b > a, do: raise(ArgumentError, "station interval must be positive")
    end)

    Enum.each(c["requirements"], fn x ->
      S.fields!(
        x,
        ~w(request_id minimum_contact_duration_s lead_time_s deadline_s contact_ids),
        "command prerequisite"
      )

      Input.id!(x["request_id"])
      Input.positive!(x["minimum_contact_duration_s"], "command duration")
      Input.number!(x["lead_time_s"], "command lead time", 0, 1.0e9)
      Input.number!(x["deadline_s"], "command deadline", -1.0e12, 1.0e12)

      unless is_list(x["contact_ids"]) and length(x["contact_ids"]) in 1..128 and
               length(Enum.uniq(x["contact_ids"])) == length(x["contact_ids"]) and
               Enum.all?(x["contact_ids"], fn id ->
                 Enum.any?(c["contacts"], &(&1["id"] == id))
               end),
             do: raise(ArgumentError, "prerequisite must name unique known contacts")
    end)

    unique!(c["requirements"], "request_id")
    claimed = Enum.flat_map(c["requirements"], & &1["contact_ids"])

    unless length(claimed) == length(Enum.uniq(claimed)),
      do: raise(ArgumentError, "one contact can serve only one declared command prerequisite")

    Enum.each(c["receipts"], &validate_receipt!/1)
    unique!(c["receipts"], "request_id")
    c
  end

  def validate_receipt!(r) do
    S.fields!(
      r,
      ~w(request_id asset_id contact_id source_id delivered_at_s kind),
      "command receipt"
    )

    Enum.each(~w(request_id asset_id contact_id source_id), &Input.id!(r[&1]))
    Input.number!(r["delivered_at_s"], "command receipt time", -1.0e12, 1.0e12)

    unless r["kind"] in ~w(observed synthetic_prediction synthetic_execution),
      do: raise(ArgumentError, "explicit command receipt role required")

    r
  end

  def allocation(c) do
    {annotated, calendar} =
      StationCalendar.overlay_contacts(c["contacts"], c["station_calendar"],
        source: c["source_id"]
      )

    {contacts, allocation} =
      ContactAllocation.allocate_contacts(annotated, [], source: c["source_id"])

    windows = CommandWindow.report(contacts, source: c["source_id"])

    %{
      contacts: contacts,
      report: %{
        "station_calendar" => calendar,
        "contact_allocation" => allocation,
        "command_windows" => windows,
        "scope" => "declared_contact_feasibility_no_command_execution",
        "allocation_policy" => "allocate_declared_contacts_before_service_search"
      }
    }
  end

  def apply(reports, nil, _, _, _), do: reports

  def apply(reports, c, assets, requests, attitude) do
    unless attitude && attitude.horizon,
      do: raise(ArgumentError, "command delivery requires an explicit horizon")

    boundary = attitude.horizon.start.seconds_since_j2000
    scale = Atom.to_string(attitude.horizon.start.scale)
    unless c["time_scale"] == scale, do: raise(ArgumentError, "command time scale mismatch")
    ids = Enum.map(assets, & &1.id)

    unless Enum.all?(c["contacts"], &(&1["scenario_id"] in ids)),
      do: raise(ArgumentError, "command contact names unknown asset")

    rm = Map.new(requests, &{&1.id, &1})

    unless Enum.all?(c["requirements"], &Map.has_key?(rm, &1["request_id"])),
      do: raise(ArgumentError, "command prerequisite names inactive demand")

    a = allocation(c)
    receipts!(c, a, boundary)

    busy = %{
      "time_scale" => c["time_scale"],
      "outages" =>
        Enum.with_index(a.contacts, 1)
        |> Enum.map(fn {contact, n} ->
          %{
            "id" => "command_contact_#{n}",
            "asset_id" => contact["scenario_id"],
            "starts_at_s" => contact["starts_at_s"],
            "ends_at_s" => contact["ends_at_s"],
            "scope" => %{"kind" => "all_activities"}
          }
        end)
    }

    reports =
      OrbitalDynamics.MissionAnalysis.Scheduling.Availability.apply(
        reports,
        busy,
        assets,
        requests,
        attitude
      )

    Enum.map(reports, fn report ->
      req = Enum.find(c["requirements"], &(&1["request_id"] == report["request_id"]))

      if req do
        receipt =
          Enum.find(
            c["receipts"],
            &(&1["request_id"] == req["request_id"] and &1["asset_id"] == report["asset_id"])
          )

        contacts =
          Enum.filter(a.contacts, fn contact ->
            eligible?(contact, req, report["asset_id"]) and
              (contact["starts_at_s"] >= boundary or
                 (receipt && receipt["contact_id"] == contact["id"]))
          end)

        request = rm[report["request_id"]]

        contacts =
          if request.segment do
            Enum.filter(
              contacts,
              &(&1["ends_at_s"] + req["lead_time_s"] <= request.segment.starts_at_s)
            )
          else
            contacts
          end

        ready =
          contacts |> Enum.map(&(&1["ends_at_s"] + req["lead_time_s"])) |> Enum.min(fn -> nil end)

        original = report["opportunities"]

        clipped =
          if ready do
            Enum.flat_map(original, fn o ->
              start = max(o["starts_at_s"], ready)

              if start + rm[report["request_id"]].duration_s <= o["ends_at_s"],
                do: [Map.put(o, "starts_at_s", start)],
                else: []
            end)
          else
            []
          end

        report
        |> Map.put("opportunities", clipped)
        |> Map.put("command_delivery_evidence", %{
          "eligible_contact_ids" => Enum.map(contacts, & &1["id"]),
          "earliest_activity_start_s" => ready || :null,
          "receipt" => receipt || :null,
          "reason" =>
            if(ready, do: "eligible_declared_contact", else: "no_eligible_command_contact")
        })
        |> then(fn r ->
          if clipped == [] and original != [],
            do: Map.put(r, "status", "no_command_delivery_opportunity"),
            else: r
        end)
      else
        report
      end
    end)
  end

  def receipts!(c, a, boundary) do
    Enum.each(c["receipts"], fn receipt ->
      req = Enum.find(c["requirements"], &(&1["request_id"] == receipt["request_id"]))
      contact = Enum.find(a.contacts, &(&1["id"] == receipt["contact_id"]))

      unless (req && contact && receipt["asset_id"] == contact["scenario_id"]) and
               receipt["delivered_at_s"] == contact["ends_at_s"] and
               receipt["delivered_at_s"] <= boundary and
               eligible?(contact, req, receipt["asset_id"]),
             do:
               raise(
                 ArgumentError,
                 "command receipt does not match an eligible allocated contact before the boundary"
               )
    end)

    c
  end

  def eligible?(c, r, asset),
    do:
      c["scenario_id"] == asset and c["id"] in r["contact_ids"] and
        c["ends_at_s"] - c["starts_at_s"] >= r["minimum_contact_duration_s"] and
        c["ends_at_s"] <= r["deadline_s"]

  def synthetic_receipts(source, report, t, kind) do
    case source["study"]["scheduling"]["command_delivery"] do
      nil ->
        nil

      c ->
        a = allocation(c)
        old = Map.new(c["receipts"], &{&1["request_id"], &1})

        Enum.reduce(report["activities"], old, fn act, acc ->
          req = Enum.find(c["requirements"], &(&1["request_id"] == act["request_id"]))

          if req && not Map.has_key?(acc, act["request_id"]) do
            contact =
              Enum.filter(
                a.contacts,
                &(eligible?(&1, req, act["asset_id"]) and &1["ends_at_s"] <= t and
                    &1["ends_at_s"] + req["lead_time_s"] <= act["starts_at_s"])
              )
              |> Enum.sort_by(&{&1["ends_at_s"], &1["id"]})
              |> List.first()

            if contact,
              do:
                Map.put(acc, act["request_id"], %{
                  "request_id" => act["request_id"],
                  "asset_id" => act["asset_id"],
                  "contact_id" => contact["id"],
                  "delivered_at_s" => contact["ends_at_s"],
                  "source_id" => "synthetic_declared_contact_execution",
                  "kind" => kind
                }),
              else: acc
          else
            acc
          end
        end)
        |> Map.values()
        |> Enum.sort_by(& &1["request_id"])
    end
  end

  defp unique!(xs, k),
    do:
      unless(length(Enum.uniq_by(xs, & &1[k])) == length(xs),
        do: raise(ArgumentError, "duplicate command #{k}")
      )
end
