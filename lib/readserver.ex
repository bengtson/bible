defmodule Bible.ReadServer do
  use Timex
  @moduledoc """
  This module provides services related to what parts of the Bible
  have been read over periods of time. for example; the following information can be obtained:

  1 - Percent of Bible read during a specific period.
  2 - List of readings during a specific time period.
  3 - List of what has not been read during a period of time.

  Information is read from a string or file where entries are:

    dd-mmm-yyyy : citation
    ...

  These are all then put into a binary that has the following format:

    <<days since 1/1/2000>><<book>><<chap>><<verse>><<book>><<chap>><<verse>>
    ...
    ...

  Requires that the BibleServer is running.
  """


  @doc """

  """
  def reading_metrics(readings, reference) do
    ref = Bible.References.exp_bible_reference(reference)
    {start,stop} = Bible.Server.get_ref_verse_range(ref)
    length = stop-start+1
    s1 = start-1
    << <<_::bitstring-size(s1)>>,
       <<bin::bitstring-size(length)>>,
       <<_::bitstring>> >> = readings
    total = bit_size(bin)
    read = for(<< bit::size(1) <- bin >>, do: bit) |> Enum.sum

    {total, read}
  end

  @doc """
  Returns a binary list of readings between the dates specified. Requires that a readings binary be provided.
  """
  def filter_by_date(readings, {start_date, end_date}) do
    epoch_date = Timex.to_date {2000,1,1}
    start_days = Timex.diff(start_date,epoch_date,:days)
    end_days = Timex.diff(end_date,epoch_date,:days)

    for(<<  days :: unsigned-integer-size(16),
        rest :: binary-size(6)
        <- readings >>, do:
          { days, rest })
        |> Enum.filter(&(elem(&1,0) >= start_days && elem(&1,0) <= end_days))
        |> Enum.map(fn {days, bin} -> << days :: unsigned-integer-size(16) >> <> bin end)
        |> Enum.join
  end


  #  def get_readings_between(readings, start_date, end_date, state) do
  #    total_verses = state["Total Verses"]
  #    filter_readings(readings, start_date, end_date)
  #      |> Enum.reduce(<<0::size(total_verses)>>, fn (reading, acc) -> add_reading(acc, reading) end)
  #  end

  def to_verse_map(readings) do
    x = Bible.Server.get_total_verses
    for(<<  days :: unsigned-integer-size(16),
        start_book :: unsigned-integer-size(8),
        start_chap :: unsigned-integer-size(8),
        start_vers :: unsigned-integer-size(8),
        end_book :: unsigned-integer-size(8),
        end_chap :: unsigned-integer-size(8),
        end_vers :: unsigned-integer-size(8) <- readings >>, do:
          { days, start_book, start_chap, start_vers,
            end_book, end_chap, end_vers })
    |>    Enum.reduce(<<0::size(x)>>, fn (reading, acc) -> add_reading(acc, reading) end)
  end

  def verse_count(verse_map) do
    for(<< bit::size(1) <- verse_map >>, do: bit) |> Enum.sum
  end

  defp add_reading(readings, reading) do
    { _, a, b, c, d, e, f } = reading
    { first_v, last_v } = Bible.Server.get_ref_verse_range({a,b,c,d,e,f})
    p1 = first_v - 1
    p2 = last_v - first_v + 1
    p3 = bit_size(readings) - last_v
    << s1 :: size(p1),
       _ :: size(p2),
       s3 :: size(p3) >> = readings
    << <<s1::size(p1)>>::bitstring,
       <<-1::size(p2)>>::bitstring,
       <<s3::size(p3)>>::bitstring >>
  end

  def load_bible_readings do
    File.read!(Application.fetch_env!(:bible, :bible_readings_file))
      |> load_readings_string
  end

  def load_file(filepath) do
    File.read!(filepath)
      |> load_readings_string
  end

  def load_readings_string (reads) do
    reads
      |> String.split("\n")               # Get list of lines.
      |> Enum.filter(&(String.length(&1) > 0))
      |> Enum.map(&(String.split(&1," : ", parts: 2)))    # Have date and ref.
      |> Enum.map(&(add_ref_days(&1)))            # Add reference into entry.
      |> Enum.sort(&(&1["Days"] <= &2["Days"]))
      |> Enum.map( fn map -> map["Readings"] end)
      |> Enum.join
  end

  # Change to accept a multi-reference line after date.
  # Need an entry in the map called Refs that is a list of maps for each
  # individual ref.
  defp add_ref_days ([string_date,reading]) do
    string_date = String.trim(string_date)
    { :ok, date } = Timex.parse(string_date, "{D}-{Mshort}-{YYYY}")
    epoch_date = Timex.to_date {2000,1,1}
    days = Timex.diff(date,epoch_date,:days)

    refs =
      Bible.References.exp_bible_references(reading)
      |> Enum.map(&(add_book_number(&1,days)))
      |> Enum.join

    %{"Days" => days, "Readings" => refs}
  end

  defp add_book_number(ref,days) do
    start_book_number = Bible.Server.get_book_number(ref["Start Book"],:in_bible)
    end_book_number = Bible.Server.get_book_number(ref["End Book"],:in_bible)

    <<
      days :: unsigned-integer-size(16),
      start_book_number :: unsigned-integer-size(8),
      ref["Start Chapter"] :: unsigned-integer-size(8),
      ref["Start Verse"] :: unsigned-integer-size(8),
      end_book_number :: unsigned-integer-size(8),
      ref["End Chapter"] :: unsigned-integer-size(8),
      ref["End Verse"] :: unsigned-integer-size(8)
    >>
  end

end
