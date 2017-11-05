defmodule Reader.Test do
  use ExUnit.Case

  setup_all do
    info = Bible.Info.get_bible_info Bible.Versions.ESV
    {:ok, info: info}
  end

  test "New Readings Module Test", state do
    read =
        """
          02-Oct-2016 : John 1-3
          03-Oct-2016 : John 4:5-8
        """

    {:ok, start_date} = Date.new 2016, 1, 1
    {:ok, end_date} = Date.new 2016, 12, 31

    verse_count = Bible.NewReader.load_readings_string(read, state.info)
    |> Bible.NewReader.filter_by_date(start_date,end_date)
    |> Bible.NewReader.to_verse_map(state.info)
    |> Bible.NewReader.verse_count
    assert 116 == verse_count
  end

  test "Check Setting Of Readings", state do
    read =
        """
          02-Oct-2016 : John 1-3
          03-Oct-2016 : John 4:5-8
        """

    {:ok, start_date} = Date.new 2016, 10, 2
    {:ok, end_date} = Date.new 2016, 10, 2

    verse_count = Bible.NewReader.load_readings_string(read, state.info)
    |> Bible.NewReader.filter_by_date(start_date,end_date)
    |> Bible.NewReader.to_verse_map(state.info)
    |> Bible.NewReader.verse_count
    assert 112 == verse_count
  end

  test "Reading Metrics", state do

    read =
    """
      02-Oct-2016 : John 1-3
    """

    assert {879, 112} ==
      Bible.NewReader.load_readings_string(read, state.info)
      |> Bible.NewReader.to_verse_map(state.info)
      |> Bible.NewReader.reading_metrics("John", state.info)

  end

  test "Read Metrics", state do

    read =
    """
      02-Oct-2016 : John 1-3
    """

    {_, [reading]} =
      Bible.NewReader.load_readings_string(read, state.info)
      |> Bible.NewReader.read_metrics(state.info)

    assert "John 1-3" == reading

  end

end
