defmodule Bible.Reporting do
@moduledoc """
Defines some useful reporting from the bible database.
"""
#use Fonts

  @doc """
  Returns the following results:
  { % To Target Last 7 days,
    % To Target Last 30 days,
    % To Target Last 365 days,
    [ Last 5 readings ] }
  """
  def read_metrics do
    readings = Bible.ReadServer.load_bible_readings
    end_date = Timex.now
    days_list = [1,7,30,365]
    target_attainment = days_list
      |> Enum.map(&(to_date_range(&1,end_date)))
      |> Enum.map(&(Bible.ReadServer.filter_by_date(readings,&1)))
      |> Enum.map(&(Bible.ReadServer.to_verse_map/1))
      |> Enum.map(&(Bible.ReadServer.reading_metrics(&1, "Genesis - Revelation")))
      |> Enum.map(fn {total, read} -> read/total end)
      |> Enum.zip(days_list)
      |> Enum.map(fn {percent, days} -> {days, percent * 365 / days} end)

      latest = for(<< _days :: unsigned-integer-size(16),
          start_book_number :: unsigned-integer-size(8),
          start_chap :: unsigned-integer-size(8),
          start_vers :: unsigned-integer-size(8),
          end_book_number :: unsigned-integer-size(8),
          end_chap :: unsigned-integer-size(8),
          end_vers :: unsigned-integer-size(8) <- readings >>, do:
            { Bible.Server.get_book_name(start_book_number), start_chap, start_vers,
              Bible.Server.get_book_name(end_book_number), end_chap, end_vers })
        |> Enum.take(-5)
        |> Enum.map(&(Bible.References.reduce_reference(&1)))
        |> Enum.reverse
      { target_attainment, latest }
  end

  defp to_date_range(days,end_date) do
    {Timex.shift(end_date, days: -days+1),end_date}
  end


end
