#!/usr/bin/env ruby

require "bundler/setup"
require "skywatcher"
require "sightseeing"
require "set"

eflag = !!ARGV.delete("-e")

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
        start_time = EorzeaTime.new(hours.min * 3600).next_occurrence(time: fc.start_time)
        end_time = EorzeaTime.new((hours.max+1) * 3600).next_occurrence(time: fc.start_time)

        if end_time > Time.now
          windows << [vista, fc, hours, start_time, end_time]
          remaining.delete(vista) if start_time > Time.now
        end
      end
    end

    fc = fc.succ
  end
end

windows.sort_by! { |window| window[3] }

puts "%-3s %-26s %-11s %-13s %-10s %-26s %s" % [
  "Id",
  "Local time",
  "ET",
  "Weather",
  "Coords",
  "Zone",
  "Name"
]

et = EorzeaTime.now
puts "Now %-26s %.2d:%.2d" % [
  Time.now.localtime.strftime("%b %d %T"),
  et.hour,
  et.min
]

windows.each do |window|
  vista, fc, hours, start_time, end_time = *window
  local_start_time = start_time.localtime.strftime("%b %d %T")
  local_end_time = end_time.localtime.strftime("%T")
  zone_name = Skywatcher::Localizer.new(:zone, vista.zone)[:en]
  weather_name = Skywatcher::Localizer.new(:weather, fc.weather)[:en]
  puts "#%.2d %s - %s %.2d:00-%.2d:59 %-13s %-10s %-26s %s" % [
    vista.id,
    local_start_time,
    local_end_time,
    hours.min, hours.max,
    weather_name,
    vista.coordinates,
    zone_name,
    vista.name]
end
