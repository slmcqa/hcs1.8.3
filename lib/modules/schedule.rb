#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/admission_helper'
require File.dirname(__FILE__) + '/helpers/locators'
require 'win32/taskscheduler'
include Win32
require 'date'
require 'oci8' if DB['db_type'] == 'oracle'

module Schedule
def self.task_scheduler(options={})
            ts = TaskScheduler.new
            mdate = options[:mydate]
          #  mdate = mdate.to_s
            gdate = Date.parse(mdate)
            tdate = Time.parse(mdate)
            sched_name = options[:sched_name]
            batch_file = options[:batch_file]
            trigger = {:start_year   => gdate.year,:start_month  => gdate.month,:start_day=> gdate.day,:start_hour => tdate.hour,:start_minute =>tdate.min,:trigger_type => TaskScheduler::ONCE}
            ts.new_work_item(sched_name, trigger)
            ts.creator=("sandy")
            ts.application_name = batch_file
            ts.activate(sched_name)
      end
def self.construct_batch_file(options={})
          spec_name = options[:spec_name]
          dir_of_spec = options[:dir_of_spec]
          file_path = "#{dir_of_spec}""/batch/#{spec_name}"".bat"
        #  fname = "#{spec_name}"".bat"
          file = File.open(file_path, "w")
          file.write("@Echo on\n")
          file.write("TITLE #{spec_name}\n")
          file.write("cd #{dir_of_spec}\n")
          file.write("rake #{spec_name}\n")
          file.write("pause")
        #  fname = "#{spec_name}"".bat"
          return  file_path
    end
def self.delete_schedule_task(options={})
            ts = TaskScheduler.new
            sched_name = options[:sched_name]
           # if ts.exist?(sched_name) == true
                      ts.delete(sched_name)
          #  else
#                      puts "Task #{sched_name}, not exist"
#            end
#            if ts.exist?(sched_name) == false
#                  puts "Task #{sched_name}, deleted"
                  return true
#            else
#                  return false
#            end
end
def self.get_fname(options={})
          myrow  = options[:myrow]

        Database.connect
              a  = "SELECT * FROM SLMC.MY_SCHEDULER WHERE MYROW = '#{myrow}'"
              ary = Database.select_all_rows a
        Database.logoff
        return {
              :average_runtime => ary[0],
              :average_runtime_round => ary[1],
              :filename => ary[2],
              :set_time => ary[3],
              :mtime => ary[4],
              :mdate => ary[5],
              :dir => ary[6],
              :final_date => ary[7],
              :status => ary[8],
              :batch_filename => ary[9]
        }

end

end
