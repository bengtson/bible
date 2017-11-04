defmodule Bible.Reader do
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

    <<days>> :: 16 bit unsigned : Days since Jan 1, 2000
    <<start book>> :: 8 bit unsigned : Starting book number
    <<start chapter>> :: 8 bit unsigned : Starting chapter number
    <<start verse>> :: 8 bit unsigned : Starging chapter number
    <<end book>> :: 8 bit unsigned : Ending book number
    <<end chapter>> :: 8 bit unsigned : Ending chapter number
    <<end verse>> :: 8 bit unsigned : Ending chapter number

    <<days since 1/1/2000>><<book>><<chap>><<verse>><<book>><<chap>><<verse>>
    ...
    ...

  There is also a readings map which is a bitmap of all versions in the
  provided version. A bit set indicates the verse has been read.


  Requires that the BibleServer is running.
  """


  @doc """
  This returns the number of verses read and the number of verses in the
  reference range provided.

      info is the info from the Version.
      reference is the string reference such as "John 1-5"
      readings is a list of the reading entries in the internal format
        shown above.

  """
  def reading_metrics(readings, reference, info) do
    ref = Bible.References.exp_bible_reference(reference, info)
    {start,stop} = Bible.Info.get_reference_range(info, ref)
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

  Readings is a list of the readings in the internal compressed format shown
  above.
  """
  def filter_by_date(readings, {start_date, end_date}) do
    {:ok, epoch_date} = Date.new(2000,1,1)
    start_days = Date.Temp.diff(start_date,epoch_date)
    end_days = Date.Temp.diff(end_date,epoch_date)

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

  @doc """
  Returns a verse map given a set of readings and a version (info). The map has a bit for every verse in the Bible version. Each verse that has been read
  according to the readings will be set.
  """

  def to_verse_map(readings, info) do
    x = Bible.Info.get_total_verse_count(info)
    for(<<  days :: unsigned-integer-size(16),
        start_book :: unsigned-integer-size(8),
        start_chap :: unsigned-integer-size(8),
        start_vers :: unsigned-integer-size(8),
        end_book :: unsigned-integer-size(8),
        end_chap :: unsigned-integer-size(8),
        end_vers :: unsigned-integer-size(8) <- readings >>, do:
          { days, start_book, start_chap, start_vers,
            end_book, end_chap, end_vers })
    |>    Enum.reduce(<<0::size(x)>>, fn (reading, acc) -> add_reading(acc, reading, info) end)
  end

  def verse_count(verse_map) do
    for(<< bit::size(1) <- verse_map >>, do: bit) |> Enum.sum
  end

  def add_reading(readings, reading, info) do
    { _, a, b, c, d, e, f } = reading
    { first_v, last_v } = Bible.Info.get_reference_range(info, {a,b,c,d,e,f})
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

#  def load_bible_readings do
#    File.read!(Application.fetch_env!(:bible, :bible_readings_file))
#      |> load_readings_string
#  end

  def load_bible_readings filepath, info do
    load_file filepath, info
  end

  def load_file(filepath, info) do
    File.read!(filepath)
      |> load_readings_string(info)
  end

  def load_readings_string(reads, info) do
    reads
      |> String.split("\n")               # Get list of lines.
      |> Enum.filter(&(String.length(&1) > 0))
      |> Enum.map(&(String.split(&1," : ", parts: 2)))    # Have date and ref.
      |> Enum.map(&(add_ref_days(&1, info)))            # Add reference into entry.
      |> Enum.sort(&(&1["Days"] <= &2["Days"]))
      |> Enum.map( fn map -> map["Readings"] end)
      |> Enum.join
  end

  # Change to accept a multi-reference line after date.
  # Need an entry in the map called Refs that is a list of maps for each
  # individual ref.
  defp add_ref_days([string_date,reading], info) do
    string_date = String.trim(string_date)
#    { :ok, date } = Timex.parse(string_date, "{D}-{Mshort}-{YYYY}")
    { :ok, date } = Date.Temp.parse(string_date)
    {:ok, epoch_date} = Date.new(2000,1,1)
    days = Date.Temp.diff(date,epoch_date)

    refs =
      Bible.References.exp_bible_references(reading, info)
      |> Enum.map(&(add_book_number(&1,days, info)))
      |> Enum.join

    %{"Days" => days, "Readings" => refs}
  end

  defp add_book_number(ref,days, info) do
    start_book_number = Bible.Info.get_book_number(info, ref["Start Book"],:in_bible)
    end_book_number = Bible.Info.get_book_number(info, ref["End Book"],:in_bible)

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

  @doc """
  Returns the following results:
  { % To Target Last 7 days,
    % To Target Last 30 days,
    % To Target Last 365 days,
    [ Last 5 readings ] }
  """
  def read_metrics readings, info do
#    end_date = Timex.now
    {:ok, end_date} = Date.Temp.now()
    days_list = [1,7,30,365]
    target_attainment = days_list
      |> Enum.map(&(to_date_range(&1,end_date)))
      |> Enum.map(&(Bible.Reader.filter_by_date(readings,&1)))
      |> Enum.map(&(Bible.Reader.to_verse_map(&1, info)))
      |> Enum.map(&(Bible.Reader.reading_metrics(&1, "Genesis - Revelation", info)))
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
            { Bible.Info.get_book_name(info, start_book_number), start_chap, start_vers,
              Bible.Info.get_book_name(info, end_book_number), end_chap, end_vers })
        |> Enum.take(-5)
        |> Enum.map(&(Bible.References.reduce_reference(&1, info)))
        |> Enum.reverse
      { target_attainment, latest }
  end

  defp to_date_range(days,end_date) do
#    {Timex.shift(end_date, days: -days+1),end_date}
    {Date.Temp.shift(end_date, days: -days+1),end_date}
  end

end
