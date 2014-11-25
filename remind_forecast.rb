#!/usr/bin/ruby
#
# remind_forecast.rb
# print upcoming events from remind(1) in a nicer way
#
# Copyright (c) 2010, 2014 joshua stein <jcs@jcs.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require "date"

# number of weeks we'll look in advance
WEEKS_OUT = 3

# file to have remind look at
REMIND_FILE = "~/.reminders"

# day to do everything relative to
TODAY = Date.today

# discard events that ended before today and then print them
Calendar.events.reject{|e| e.end < TODAY }.reverse.each do |e|
  puts e.to_s(TODAY)
end

BEGIN {
  class Calendar
    def self.events
      evs = []

      if RUBY_PLATFORM.match(/darwin/)
        desc = nil

        IO.popen("icalBuddy -b '' -nc " <<
        "-eep attendees,location,notes,url,priority,uid -nrd " <<
        "eventsToday+#{WEEKS_OUT * 7}").each_line do |line|
          if m = line.match(/^    (... ..?, ....)( (at|-) (.+))?/)
            e = Event.new
            e.desc = desc
            e.start = Date.parse(m[1])

            # "12:00"
            # "14:00 - 15:00"
            # "Nov 29, 2014"
            if m[4]
              if n = m[4].match(/^(\d\d?:\d+)/)
                e.time = n[1]
              else
                e.end = Date.parse(m[4])
              end
            end

            evs.push e
          else
            desc = line.strip
          end
        end
      else
        prev_fileinfo = nil
        continue_last = false

        IO.popen("remind -q -g -s+#{WEEKS_OUT} -b1 -l #{REMIND_FILE}").
        each_line do |line|
          # "# fileinfo 8 /path/.reminders"
          if m = line.match(/^# fileinfo (.+)$/)
            continue_last = (prev_fileinfo && prev_fileinfo == m[1])
            prev_fileinfo = m[1]

          # "2010/08/03 * * * 450 7:30am some event"
          else
            date, junk, junk, junk, time, event = line.strip.split(" ", 6)

            if continue_last
              evs.last.end = Date.parse(date)
            else
              e = Event.new
              e.desc = event
              e.start = Date.parse(date)

              if time != "*"
                # i'm not sure how a time field of "450" corresponds to
                # "07:30", so take the time out of the description
                e.time, e.desc = e.desc.split(" ", 2)
              end

              evs.push e
            end
          end
        end
      end

      evs
    end
  end

  class Event
    BOLD = "\e[1;1m"
    UNBOLD = "\e[0;0m"
    GRAY = "\e[38;5;239m"
    LIGHTGRAY = "\e[38;5;242m"
    RESET = "\e[0;0m"

    attr_accessor :start
    attr_accessor :end
    attr_accessor :desc
    attr_accessor :time

    def start=(d)
      @start = d
      @end = d
    end

    def to_s(from_day = Date.today)
      weeks = 0
      if (days = (self.start - from_day).to_i) > 7
        weeks = (days.to_f / 7.0).floor
        days = days - (weeks * 7)
      end

      out = ""
      if weeks == 0 && days == 0
        out << BOLD
      elsif weeks == 1
        out << GRAY
      elsif weeks > 1
        out << LIGHTGRAY
      end

      out << self.desc << " "

      if weeks > 0
        out << "in #{weeks} week#{weeks == 1 ? '' : 's'}"

        if days > 0
          out << ", #{days} day#{days == 1 ? '' : 's'}"
        end
      else
        if days < -1
          out << "#{days.abs} day#{days == -1 ? '' : 's'} ago"
        elsif days == -1
          out << "yesterday"
        elsif days == 0
          out << "today"
        elsif days == 1
          out << "tomorrow"
        else
          out << "in #{days} day#{days == 1 ? '' : 's'}"
        end
      end

      if self.time
        out << " at #{self.time}"
      end

      if weeks == 0 && days == 0
        out << UNBOLD
      end

      out << " (" << self.start.strftime("%a #{self.start.day} %b").downcase
      if self.start != self.end
        out << " to " << self.end.strftime("%a #{self.end.day} %b").downcase
      end
      out << ")"

      out << RESET

      out
    end
  end
}
