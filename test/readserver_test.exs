defmodule Read.Server.Test do
  use ExUnit.Case
  use Timex
  doctest Bible.ReadServer

  setup_all do
    metadata = Bible.Server.get_metadata
    {:ok, metadata: metadata}
  end

  test "New Readings Module Test" do
    read =
        """
          02-Oct-2016 : John 1-3
          03-Oct-2016 : John 4:5-8
        """

    start_date = Timex.to_date {2016, 1, 1}
    end_date = Timex.to_date {2016, 12, 31}

    verse_count = Bible.ReadServer.load_readings_string(read)
    |> Bible.ReadServer.filter_by_date({start_date,end_date})
    |> Bible.ReadServer.to_verse_map
    |> Bible.ReadServer.verse_count
    assert 116 == verse_count
  end

  test "Check Setting Of Readings" do
    read =
        """
          02-Oct-2016 : John 1-3
          03-Oct-2016 : John 4:5-8
        """

    start_date = Timex.to_date {2016, 10, 2}
    end_date = Timex.to_date {2016, 10, 2}

    verse_count = Bible.ReadServer.load_readings_string(read)
    |> Bible.ReadServer.filter_by_date({start_date,end_date})
    |> Bible.ReadServer.to_verse_map
    |> Bible.ReadServer.verse_count
    assert 112 == verse_count
  end

  test "Reading Metrics" do

    read =
    """
      02-Oct-2016 : John 1-3
    """

    assert {879, 112} ==
      Bible.ReadServer.load_readings_string(read)
      |> Bible.ReadServer.to_verse_map
      |> Bible.ReadServer.reading_metrics("John")

  end

end
