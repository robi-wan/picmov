$:.push(File.join(File.dirname(__FILE__), 'lib'))

# installiert benoetigte gems beim Start
Shoes.setup do
  gem 'exifr'
end

require 'yaml'
require 'picmov'
require 'settings'

Shoes.app :title => "A Picture Mover", :width => 520, :height => 520, :resizable => true do

  background "#EEE".."#9AA"
  background tan, :height => 62
  stack do
    caption "A Picture Mover", :margin => 8, :stroke => white
    inscription "Kopieren und umbenennen von Bildern", :stroke => white
  end
  begin

    stack :margin => 10 do

      stack :margin_top => 10 do
        para "1. Bilder auswählen"
        para "Quellverzeichnis:"
        flow do
          @source_folder = edit_line(:width => 300, :margin_right => 10)
          button("Ordner...") { dir = ask_open_folder; @source_folder.text = dir if dir}
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
          @target_folder = edit_line(:width => 300, :margin_right => 10)
          button("Ordner..."){ dir = ask_open_folder; @target_folder.text = dir if dir }
        end
      end

      flow do
        time_mapper = TimeMapper.new
        now = Time.now
        file = "DSC2134_#{now.strftime(time_mapper.file_pattern)}.jpg"
        inscription "Die Bilder werden nach diesem Muster umbenannt:\nDSC2134.jpg => #{File.join(now.strftime(time_mapper.folder_pattern), file)}"
      end

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
        @start_button = button("Start", :margin_right => 4) do
          #todo verschieben im Hintergrund, besser: Fortschritt (siehe simple-downloader.rb))
          @progress_message.text = "Beginne verschieben."
          @progress_area.show
          Thread.start(@progress, @progress_message) do |progress, message|
            begin
              mover = PictureMover.new(@source_folder.text, @target_folder.text)
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

  def load_setting
    if PicMov::Settings.configured?
      @source_folder.text = PicMov::Settings.source_folder
      @target_folder.text = PicMov::Settings.target_folder
    end
  end

  def save_setting
    PicMov::Settings.save_settings(@source_folder.text, @target_folder.text)
  end

  load_setting

end