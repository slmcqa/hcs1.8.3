require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
#require 'date'
require 'spec_helper'
require 'win32/taskscheduler'
require 'win32ole'
include Win32


describe "Scheduler" do
  
  attr_reader :selenium_driver
  alias :slmc :selenium_driver
  
  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

  end
  
  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


 it "Run Task Scheduler" do
#@@run =  1 #CREATE BATCH FILE
@@run =  2 #ADD BATCH FILE TO TASK SCHEDULER
#--@@run =  3 #CREATE AND ADD BATCH FILE TO TASK SCHEDULER
#@@run =  4 #DELETE TASK SCHEDULER
#@@run =  5 #DO NOTHING
source_type = "DB"
#source_type = "excel"
@@x = 26
@@row = 2
if source_type == "excel"
          mypath = ("#{Dir.getwd}""/speclist.xls")
          excel = WIN32OLE.new('excel.application')
          excel.visible = false
          excel.workbooks.open(mypath)
          worksheet = excel.worksheets("specname")
          @workbook = excel.ActiveWorkbook
          @@row =  @@row + 1
end

case @@run
when 1 #CREATE BATCH FILE
          dir_of_spec = Dir.getwd
          if source_type == "excel"
              while @@x != 0
                               spec_name ="D#{@@row}"
                               batch_filepath = "K#{@@row}"
                               @@spec_name = worksheet.range(spec_name).value
                               puts @@spec_name
                               file_path = Schedule.construct_batch_file(:spec_name =>@@spec_name, :dir_of_spec =>dir_of_spec).should be_true
                               worksheet.range(batch_filepath).value = file_path
                               @workbook.Save
                               @@row += 1
                               @@x -=1
                    end
          else
              while @@x != 0
                              @@sched_detail = Database.get_sched_detail(:myrow => @@row)
                               file_path = Schedule.construct_batch_file(:spec_name =>@@sched_detail[:filename], :dir_of_spec =>dir_of_spec).should be_true
                               slmc.update_from_database(:table =>"SLMC.MY_SCHEDULER",:what =>"BATCH_FILENAME",:set1 => file_path, :column1 => "MYROW", :condition1 => @@row )
                               puts @@sched_detail[:filename]
                               @@row += 1
                               @@x -=1
              end
        end
when 2 #ADD BATCH FILE TO TASK SCHEDULER
          if source_type == "excel"
                while @@x != 0
                       spec_name ="D#{@@row}"
                       mydate = "I#{@@row}"
                       myfile = "K#{@@row}"
                       @@spec_name = worksheet.range(spec_name).value
                       @@mydate = worksheet.range(mydate).value
                       #@@mydate = new Date(@@mydate)
                       @@mydate = (@@mydate).gsub("/","-").to_s
                      puts @@mydate
                      #@mydate = Date.strptime(@@mydate,"%m/%d/%Y%") # H:%M")
                       gdate = Date.parse(mydate)
                       puts @@spec_name
                       puts gdate
                      # @@mydate = @@mydate.to_s
                       @@myfile = worksheet.range(myfile).value
                       Schedule.task_scheduler(:mydate => mydate, :sched_name => @@spec_name, :batch_file => @@myfile)
                       @@row += 1
                       @@x -=1
                end
                  @workbook.Save
                  #excel.ActiveWorkbook.Close(0);
                  #excel.Quit();
          else
                while @@x != 0
                              @@sched_detail = Database.get_sched_detail(:myrow => @@row)
                               Schedule.task_scheduler(:mydate => @@sched_detail[:final_date], :sched_name => @@sched_detail[:filename], :batch_file => @@sched_detail[:batch_filename])
                               puts @@sched_detail[:filename]
                               @@row += 1
                               @@x -=1
                end
          end
when 3 #CREATE AND ADD BATCH FILE TO TASK SCHEDULER
                dir_of_spec = Dir.getwd
          if source_type == "excel"
                 while @@x != 0
                            spec_name ="D#{@@row}"
                            mydate = "I#{@@row}"
                            @@spec_name = worksheet.range(spec_name).value
                            @@mydate = worksheet.range(mydate).value
                            fname = Schedule.construct_batch_file(:spec_name =>@@spec_name, :dir_of_spec =>dir_of_spec).should be_true
                            worksheet.range(myfile).value = fname
                            @workbook.Save
                            myfile = "K#{@@row}"
                            @@myfile = worksheet.range(myfile).value
                            Schedule.task_scheduler(:mydate => mydate, :sched_name => @@spec_name, :batch_file => @@myfile)
                            @@row += 1
                            @@x -=1
                end
          else
                 while @@x != 0            
                          @@sched_detail = Database.get_sched_detail(:myrow => @@row)
                          file_path = Schedule.construct_batch_file(:spec_name =>@@sched_detail[:filename], :dir_of_spec =>dir_of_spec).should be_true
                          slmc.update_from_database(:table =>"SLMC.MY_SCHEDULER",:what =>"BATCH_FILENAME",:set1 => file_path, :column1 => "MYROW", :condition1 => @@row )
                          @@sched_detail = Database.get_sched_detail(:myrow => @@row)
                          Schedule.task_scheduler(:mydate => @@sched_detail[:final_date], :sched_name => @@sched_detail[:filename], :batch_file => @@sched_detail[:batch_filename])
                          @@row += 1
                          @@x -=1
                 end
          end
when 4 #DELETE TASK SCHEDULER
            if source_type == "excel"
                while @@x != 0
                        spec_name ="D#{@@row}"
                        @@spec_name = worksheet.range(spec_name).value
                        Schedule.delete_schedule_task(:sched_name => @@spec_name).should be_true
                        @@row += 1
                        @@x -=1
                end
            else
                 while @@x != 0
                          @@sched_detail = Database.get_sched_detail(:myrow => @@row)
                        puts @@sched_detail[:filename]
                        Schedule.delete_schedule_task(:sched_name => @@sched_detail[:filename]).should be_true
                        puts @@sched_detail[:filename]
                          @@row += 1
                          @@x -=1
                 end
            end
else
    puts "DO NOTHING"
end
if source_type == "excel"
      excel.ActiveWorkbook.Close(0);
      excel.Quit();
end
 end
 it "Create Batch File"do
#    if @@Create_Batch_File == true
#              mypath = ("#{Dir.getwd}""/speclist.xls")
#              excel = WIN32OLE.new('excel.application')
#              excel.visible = false
#              excel.workbooks.open(mypath)
#              worksheet = excel.worksheets("specname")
#              #myexcel = excel
#              dir_of_spec = Dir.getwd
#              x = 2
#              row = 2
#              while x != 0
#                     spec_name ="D#{row}"
#                     @@spec_name = worksheet.range(spec_name).value
#                     puts @@spec_name
#                     Schedule.construct_batch_file(:spec_name =>@@spec_name, :dir_of_spec =>dir_of_spec ).should be_true
#                     row += 1
#                     x -=1
#              end
#              excel.ActiveWorkbook.Close(0);
#              excel.Quit();
#    end
  end
 it "Schedule" do
#    if @@Create_Schedule == true
#                mypath = ("#{Dir.getwd}""/speclist.xls")
#                excel = WIN32OLE.new('excel.application')
#                excel.visible = false
#                excel.workbooks.open(mypath)
#                worksheet = excel.worksheets("specname")
#                #myexcel = excel
#                dir_of_spec = Dir.getwd
#                x = 2
#                row = 2
#                while x != 0
#                       spec_name ="D#{row}"
#                       mydate = "I#{row}"
#                       myfile = "K#{row}"
#                       @@spec_name = worksheet.range(spec_name).value
#                       @@mydate = worksheet.range(mydate).value
#                       @@myfile = worksheet.range(myfile).value
#                      Schedule.task_scheduler(:mydate => mydate, :sched_name => @@spec_name, :batch_file => @@myfile)
#                       row += 1
#                       x -=1
#                end
#                excel.ActiveWorkbook.Close(0);
#                excel.Quit();
#    end
#    mydate = ""
#    sched_name = ""
#    batch_file_dir = ""
#    ModuleNameHere.schedule()
  end
 it "Delete Scheduler" do
#                 ts = TaskScheduler.new
#                 ts.delete(task)
  end
end

