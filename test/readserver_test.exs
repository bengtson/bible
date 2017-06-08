defmodule Read.Server.Test do
  use ExUnit.Case
  use Timex
  doctest Bible.ReadServer

  setup_all do
    info = Bible.Info.get_bible_info("Z")
    {:ok, info: info}
  end

  test "New Readings Module Test", state do
    read =
        """
          02-Oct-2016 : John 1-3
          03-Oct-2016 : John 4:5-8
        """

    start_date = Timex.to_date {2016, 1, 1}
    end_date = Timex.to_date {2016, 12, 31}

    verse_count = Bible.Reader.load_readings_string(read)
    |> Bible.Reader.filter_by_date({start_date,end_date})
    |> Bible.Reader.to_verse_map(state.info)
    |> Bible.Reader.verse_count
    assert 116 == verse_count
  end

  test "Check Setting Of Readings", state do
    read =
        """
          02-Oct-2016 : John 1-3
          03-Oct-2016 : John 4:5-8
        """

    start_date = Timex.to_date {2016, 10, 2}
    end_date = Timex.to_date {2016, 10, 2}

    verse_count = Bible.Reader.load_readings_string(read)
    |> Bible.Reader.filter_by_date({start_date,end_date})
    |> Bible.Reader.to_verse_map(state.info)
    |> Bible.Reader.verse_count
    assert 112 == verse_count
  end

  test "Reading Metrics", state do

    read =
    """
      02-Oct-2016 : John 1-3
    """

    assert {879, 112} ==
      Bible.Reader.load_readings_string(read)
      |> Bible.Reader.to_verse_map(state.info)
      |> Bible.Reader.reading_metrics("John", state.info)

  end

end
