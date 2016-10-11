defmodule Read.Server.Test do
  use ExUnit.Case
  use Timex
  doctest Bible.ReadServer

  setup_all do
    metadata = Bible.Server.get_metadata
    {:ok, metadata: metadata}
  end

  test "String Reading Load" do
    read = """
02-Oct-2016 : John 1-3
    """
    Bible.ReadServer.load_readings(read)
    start_date = Timex.to_date {2016, 1, 1}
    end_date = Timex.to_date {2016, 12, 31}
    readings = Bible.ReadServer.get_readings(start_date,end_date)
    verses_read = for(<< bit::size(1) <- readings >>, do: bit) |> Enum.sum
    assert 112 == verses_read
  end

  test "Check Setting Of Readings" do
    start_date = Timex.to_date {2016, 1, 1}
    end_date = Timex.to_date {2016, 12, 31}
    readings = Bible.ReadServer.get_readings(start_date,end_date)
    verses_read = for(<< bit::size(1) <- readings >>, do: bit) |> Enum.sum
#    IO.puts "Readings"
#    IO.inspect readings
#    IO.puts "Verses Read #{verses_read}"
#    IO.inspect verses_read
    assert 1 == 1
  end

  test "Reading Metrics" do
    start_date = Timex.to_date {2016,1,1}
    end_date = Timex.to_date {2016, 12, 31}
    readings = Bible.ReadServer.get_readings(start_date,end_date)
    {total, read} = Bible.ReadServer.reading_metrics(readings, "John")
#    IO.inspect total
#    IO.inspect read
    percent = read / total
#    IO.puts "Percent of John Read = #{percent}"
    assert 1 == 1
  end

end
