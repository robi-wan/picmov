# "C:\Program Files\Shoes\0.r970\shoes.exe" D:\home\docs\dev\picmov\picmov-gui.rb
require 'yaml'
require 'picmov'

# installiert benï¿½tigte gems beim Start
Shoes.setup do
  gem 'exifr'
end

Shoes.app :title => "A Picture Mover", :width => 520, :height => 500, :resizable => true do

  background white
#  background "#F90".."#F3F"
  background tan, :height => 62
#  style(Link, :underline => false, :stroke => white)
#  style(LinkHover, :underline => false, :stroke => white, :fill => nil)
stack do
  caption "A Picture Mover", :margin => 8, :stroke => white
  inscription "Kopieren und umbenennen von Bildern", :stroke => white
end
  begin

    stack :margin => 10 do
      #para "You need to", :stroke => red, :fill => yellow

      #    stack :margin_left => 5, :margin_right => 10, :width => 1.0, :height => 200, :scroll => true do
      #     background white
      #      border white, :strokewidth => 3
      #      @gui_todo = para
      #    end

      stack :margin_top => 10 do
        para "1. Bilder auswählen"
        para "Quellverzeichnis:"
        flow do
          @source_folder = edit_line(:width => 250, :margin_right => 10)
          button("Auswaehlen...") { dir = ask_open_folder; @source_folder.text = dir if dir}
        end
        flow :margin_left => 20, :hidden => true do
          @source_include_subfolders = check
          para "Bilder in Unterverzeichnissen einschließen"
        end
      end

      stack :margin_top => 10 do
        para "2. Speicherort für Bilder auswählen"
        para "Zielverzeichnis:"
        flow do
          @target_folder = edit_line(:width => 250, :margin_right => 10)
          button("Auswaehlen..."){ dir = ask_open_folder; @target_folder.text = dir if dir }
        end
      end

#      flow do
#        inscription "Die Bilder werden nach diesem Muster umbenannt:"
#        time_mapper = TimeMapper.new
#        now = Time.now
#        file = "DSC2134_#{now.strftime(time_mapper.file_pattern)}.jpg"
#        inscription "DSC2134.jpg => #{File.join(now.strftime(time_mapper.folder_pattern), file)}"
#      end
      #    stack :margin_top => 5 do
      #      background darkgray
      #      para strong(link("Erweiterte Optionen"){ @more_options.toggle})
      #    end

      # todo show example
      @more_options = stack :width => 1.0, :hidden => true do
        para "3. Namen fuer Bilder auswaehlen"
        flow :margin_top => 10 do
          para "Muster fuer Ordner"
          @folder_pattern = edit_line( :margin_left => 10, :width => 180)
        end

        flow :margin_top => 10 do
          para "Muster fuer Dateien"
          @file_pattern = edit_line( :margin_left => 10, :width => 180)
        end

        flow :margin_left => 10 do
          @delete_originals = check
          para "Originalbilder nach erfolgreichem Verschieben löschen"
        end

      end

      flow :margin => 20, :margin_left => 320 do
        # todo fehlerbehandlung
        @start_button = button("Start", :margin_right => 4) do
          refresh_setting()
          #todo verschieben im Hintergrund, besser: Fortschritt (siehe simple-downloader.rb))
          @progress_message.text = "Beginne verschieben."
          @progress_area.show
          Thread.start(@progress, @progress_message) do |progress, message|
            begin
              mover = PictureMover.new(@setting.source_folder, @setting.target_folder)
              save_setting()
              mover.move do |file, percent|
                progress.fraction = percent
                message.text = "Verschiebe Datei #{file.source}"
              end
              message.text ="Verschieben beendet."
            rescue Exception => e
              Shoes.error(e)
              Shoes.show_log
              @progress_area.hide
            #ensure
            end
          end
        end
        @exit_button = button("Beenden") do
          close()
        end
      end

      @progress_area = stack :margin_right => 20, :hidden => true do
        background "#eee".."#ccd"
        stack :margin => 10 do
          @progress_message = inscription
          @progress = progress :width => 1.0, :margin_right => 10
        end
      end

    end

  rescue Exception => e
    Shoes.error(e)
    Shoes.show_log
  end

  #  stack :margin => 10, :margin_top => 50 do
  #    para "You need to", :stroke => red, :fill => yellow
  #
  #    stack :margin_left => 5, :margin_right => 10, :width => 1.0, :height => 200, :scroll => true do
  #      background white
  #      border white, :strokewidth => 3
  #      @gui_todo = para
  #    end
  #
  #    flow :margin_top => 10 do
  #      para "Remember to"
  #      @add = edit_line(:margin_left => 10, :width => 180)
  #      button("Add", :margin_left => 5)  { add_todo(@add.text); @add.text = '' }
  #    end
  #  end

  #  stack :margin_top => 10 do
  #    background darkgray
  #    para strong('Completed'), :stroke => white
  #  end

  #  @gui_completed = stack :width => 1.0, :height => 207, :margin_right => 20


  def settings_path
    if RUBY_PLATFORM =~ /win32/
      if ENV['USERPROFILE']
        if File.exist?(File.join(File.expand_path(ENV['USERPROFILE']), "Application Data"))
          user_data_directory = File.join File.expand_path(ENV['USERPROFILE']), "Application Data", "PicMov"
        else
          user_data_directory = File.join File.expand_path(ENV['USERPROFILE']), "PicMov"
        end
      else
        user_data_directory = File.join File.expand_path(Dir.getwd), "data"
      end
    else
      user_data_directory = File.expand_path(File.join("~", ".picmov"))
    end

    unless File.exist?(user_data_directory)
      Dir.mkdir(user_data_directory)
    end

    return File.join(user_data_directory, "settings.yaml")
  end


  #  def refresh_todo
  #    @gui_todo.replace *(
  #        @todo.map { |item|
  #          [ item, '  ' ] + [ link('Done') { complete_todo item } ] + [ '  ' ] +
  #              [ link('Forget it') { forget_todo item } ] + [ "\n" ]
  #        }.flatten
  #    )
  #  end

  def refresh_setting
    @setting.source_folder = @source_folder.text
    @setting.target_folder = @target_folder.text
    @setting.file_pattern = @file_pattern.text
    @setting.folder_pattern = @folder_pattern.text
    @setting.delete_originals = @delete_originals.checked?
    @setting.source_include_subfolders= @source_include_subfolders.checked?
  end

  def refresh
    @source_folder.text = @setting.source_folder
    @target_folder.text = @setting.target_folder
    @file_pattern.text = @setting.file_pattern
    @folder_pattern.text = @setting.folder_pattern
    @delete_originals.checked = @setting.delete_originals
    @source_include_subfolders.checked = @setting.source_include_subfolders

    #    refresh_todo
    #
    #    @gui_completed.clear
    #
    #    @gui_completed.append do
    #      background white
    #
    #      @completed.keys.sort.reverse.each { |day|
    #        stack do
    #          background lightgrey
    #          para strong(Time.at(day).strftime('%B %d, %Y')), :stroke => white
    #        end
    #
    #        stack do
    #          inscription *(
    #              @completed[day].map { |item|
    #                [ item ] + [ '  ' ] + [ link('Not Done') { undo_todo day, item } ] +
    #                    (@completed[day].index(item) == @completed[day].length - 1 ? [ '' ] : [ "\n" ])
    #              }.flatten
    #          )
    #        end
    #
    #      }
    #    end
  end

  #refresh


  #  def complete_todo(item)
  #    day = Time.today.to_i
  #
  #    if @completed.keys.include? day
  #      @completed[day] << item
  #    else
  #      @completed[day] = [ item ]
  #    end
  #
  #    @todo.delete(item)
  #
  #    save_setting
  #
  #    refresh
  #  end


  #  def undo_todo(day, item)
  #    @completed[day].delete item
  #
  #    @completed.delete(day) if @completed[day].empty?
  #
  #    @todo << item unless @todo.include? item
  #
  #    save_setting
  #
  #    refresh
  #  end


  #  def add_todo(item)
  #    item = item.strip
  #
  #    return if item == ''
  #
  #    if @todo.include? item
  #      alert('You have already added that to the list!')
  #      return
  #    end
  #
  #    @todo << item
  #
  #    save_setting
  #
  #    refresh_todo
  #  end


  #  def forget_todo(item)
  #    @todo.delete item
  #
  #    save_setting
  #
  #    refresh_todo
  #  end


  def load
    if File.exist?(settings_path)
      @setting = YAML::load(File.open(settings_path, 'r'))
    else
      @setting = Settings.default_setting
    end
Shoes.error(@setting)
    Shoes.show_log
    refresh
  end


  def save_setting
    refresh_setting

    File.open(settings_path, 'w') { |f|
      f.write @setting.to_yaml
    }
  end

  load
  Shoes.error("load")
  Shoes.show_log

end

class Settings
  attr_accessor :source_folder
  attr_accessor :source_include_subfolders
  attr_accessor :delete_originals
  attr_accessor :target_folder
  attr_accessor :folder_pattern
  attr_accessor :file_pattern


=begin

  def self.load(file)
    if File.exist?(file)
      return YAML::load(File.open(settings_path, 'r'))
    else
      default_setting
    end
  end

=end



=begin

  def self.write(setting, file)
    File.open(file, 'w') { |f|
      f.write setting.to_yaml
    }
  end

=end

  def self.default_setting
    setting = Settings.new
    setting.source_include_subfolders = true
    setting.delete_originals = false
    setting.folder_pattern = ""
    setting.file_pattern = ""
    setting.source_folder=""
    setting.target_folder=""
    setting
  end


end