#!/usr/bin/env ruby

require "bundler/setup"
require "skywatcher"
require "sightseeing"
require "set"

eflag = !!ARGV.delete("-e")

now_et = EorzeaTime.now
now_st = Time.now.utc
now_lt = Time.now.localtime

printf "ET: %.2d:%.2d\n" % [now_et.hour, now_et.min]
printf "ST: #{now_st.strftime('%b %d %T %z')}\n"
printf "LT: #{now_lt.strftime('%b %d %T %z')}\n\n"

itinerary = 
  if ARGV.any?
    ids = ARGV.flat_map do |arg|
      arg.split(/[,: ]/).map(&:to_i)
    end
    Sightseeing::Vista.find(*ids)
  else
    Sightseeing::Vista.all
  end

windows = []

itinerary.group_by(&:zone).each do |zone, vistas|
  fc = Skywatcher.forecast(zone)
  remaining = Set.new(vistas)

  while remaining.any?
    (eflag ? vistas : remaining).each do |vista|
      hours = vista.matching_hours(fc)
      if hours.any?
        start_time = EorzeaTime.new(hours.min * 3600).next_occurrence(time: fc.start_time-1)
        end_time = EorzeaTime.new((hours.max+1) * 3600).next_occurrence(time: start_time)

        if end_time > now_st
          windows << [vista, fc, hours, start_time, end_time]
          remaining.delete(vista) if start_time > now_st
        end
      end
    end

    fc = fc.succ
  end
end

windows.sort_by! { |window| window[3] }

puts "%-3s %-11s %-24s %-13s %-10s %-26s %s" % [
  "Id",
  "ET",
  "Local time",
  "Weather",
  "Coords",
  "Zone",
  "Name"
]

windows.each do |window|
  vista, fc, hours, start_time, end_time = *window
  local_start_time = start_time.localtime.strftime("%b %d %T")
  local_end_time = end_time.localtime.strftime("%T")
  zone_name = Skywatcher::Localizer.new(:zone, vista.zone)[:en]
  weather_name = Skywatcher::Localizer.new(:weather, fc.weather)[:en]
  puts "#%.2d %.2d:00-%.2d:59 %s-%s %-13s %-10s %-26s %s" % [
    vista.id,
    hours.min, hours.max,
    local_start_time,
    local_end_time,
    weather_name,
    vista.coordinates,
    zone_name,
    vista.name]

  if start_time < now_lt + 300
    wrapped_comment = vista.comment.scan(/\S.{1,80}(?=\s+|$)/)
    puts wrapped_comment.map { |s| "    #{s}" }
    puts "    Emote: #{vista.emote}\n\n"
  end
end
