defmodule ReadMap.Test do
  use ExUnit.Case
  use Timex

  setup_all do
    metadata = Bible.Server.get_metadata
    {:ok, metadata: metadata}
  end

  test "Test Read Map Generation" do
    read =
        """
          02-Oct-2016 : John 1-3
          03-Oct-2016 : John 4:5-8
          04-Oct-2016 : 1 Kings - 2 Kings; Galations
          31-Oct-2016 : Micah
        """

    start_date = Timex.to_date {2016, 1, 1}
    end_date = Timex.to_date {2016, 12, 31}

    Bible.ReadServer.load_readings_string(read)
#    Bible.ReadServer.load_bible_readings
    |> Bible.ReadServer.filter_by_date({start_date,end_date})
    |> Bible.Reporting.ReadMap.read_map
    assert 1 == 1
  end

end
