require 'yaml'

module PicMov
  class Settings

    SOURCE_FOLDER = "source_folder"
    TARGET_FOLDER = "target_folder"
    SETTINGS_FILE = "settings.yml"

    def self.source_folder
      settings[Settings::SOURCE_FOLDER]
    end

    def self.target_folder
      settings[Settings::TARGET_FOLDER]
    end

    def self.settings
      @@settings ||= load_settings
    end

    def self.configured?
      File.exists?(settings_file_path)
    end

    def self.save_settings(source_folder, target_folder)
      begin
        File.open(settings_file_path, "w") do |f|
          f.puts({
                  Settings::SOURCE_FOLDER => source_folder,
                  Settings::TARGET_FOLDER => target_folder}.to_yaml)
          return "Successfully saved your settings."
        end
      rescue Exception => e
        return "An error occurred while saving your settings: #{e}."
      end
    end

    private

    def self.settings_file_path

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

      return File.join(user_data_directory, Settings::SETTINGS_FILE)


    end

    def self.load_settings
      if configured?
        @@settings = YAML.load_file(settings_file_path)
      end
    end

  end
end#module PicMov