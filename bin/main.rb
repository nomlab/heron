# coding: utf-8
require Dir.pwd + "/lib/command"
require 'date'

calmana = Calmana.new

case ARGV[0]
    
# Usage: bundle exec ruby main.rb show_events CALENDAR_ID
when "show_events" then
  if ARGV[1].nil?
    puts("カレンダIDを指定してください")
  else
    calendar_id = ARGV[1]
    calmana.show_events(calendar_id)
  end

# Usage: bundle exec ruby main.rb get_events CALENDAR_ID
when "get_events" then
  if ARGV[1].nil?
    puts("カレンダIDを指定してください")
  else
    calendar_id = ARGV[1]
    calmana.get_events(calendar_id)
  end

# Usage: bundle exec ruby main.rb delete_event CALENDAR_ID EVENT_ID
when "delete_event" then
  if ARGV.size == 3
    calmana.delete_event(ARGV[1], ARGV[2])
  else
    puts("カレンダIDとイベントIDを指定してください")
  end

# Usage: bundle exec ruby main.rb calendars
when "show_calendars" then
  calmana.show_calendars

# Usage: bundle exec ruby main.rb post_event CALENDAR_ID TITLE START_DATE END_DATE
when "post_event" then
  if ARGV.size() == 5
    calendar_id = ARGV[1]
    title = ARGV[2]
    start_date = Date.strptime(ARGV[3], '%Y-%m-%d')
    end_date = Date.strptime(ARGV[4], '%Y-%m-%d')
    calmana.post_event(calendar_id, title, start_date, end_date)
  else
    puts "カレンダID，予定名，開始日，終了日を指定してください"
  end
  
# Usage: bundle exec ruby main.rb post_heron CALENDAR_ID TITLE HERON_RESULT
when "post_heron" then
  if ARGV.size == 4
    calendar_id = ARGV[1]
    title = ARGV[2]
    File.open(ARGV[3], mode = "rt"){|f|
      f.each_line{|line|
        calmana.post_event(calendar_id, title, line.chomp, line.chomp )
      }
    }
  else
    puts "カレンダID，予定名，heronの予測結果ファイルを指定してください"
  end

when "update_calendar" then
  calendar_id = ARGV[1]
  calmana.update_calendar(calendar_id)
  
else
  puts("定義されていないコマンドです")
end
