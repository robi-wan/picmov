require 'fileutils'

module PicMov
  class SimpleFileLister
    def initialize(folder=Dir.pwd)
      @folder = folder
    end

    def list
      files=[]
      FileUtils.cd(@folder) do |path|
        files=Dir.glob("*").select{|f| File.file?(f)}.collect{|f| File.join(@folder, f)}
      end
      files
    end
  end

  class DuplicationFile
    # Enthaelt die Quelle als String
    attr_accessor :source
    # Enthaelt den Namen des Zielordners als String. Dies ist wirklich nur der Name der Ordners, in den die Datei
    # kopiert werden soll (kein voll qualifizierter Pfad)
    attr_accessor :target
    # Der neue Name der Zieldatei
    attr_accessor :new_name
    # Der Name der Zieldatei im Dateisystem (kann von :new_name abweichen)
    attr_accessor :real_new_name
    # Falls es benoetigt wird: Ein File-Objekt der Quelle
    attr_reader :file

    def initialize(file)
      @file=file
      yield self if block_given?
    end

  end

  class FileNameModifier

    def do(file, enhancement)
      extension=File.extname( file )
      name = File.basename( file, extension)
      name << "_" << enhancement << extension
    end

  end

  class PrefixFileNameModifier

    def do(file, enhancement)
      extension=File.extname( file )
      name = File.basename( file, extension)
      enhancement << "_" << name << extension
    end

  end


  class TimeMapper
    attr_reader(:folder_pattern)
    attr_reader(:file_pattern)
    attr_accessor(:modifier)
    def initialize(files=[], time_mapper = CompoundTimeMapper.new(EXIFTimeMapper.new, ModifiedTimeMapper.new, CurrentTimeMapper.new) ,folder_pattern="%Y_%m_%d", file_pattern="%Y-%m-%d_%H-%M-%S")
      @files = files
      @time_mapper = time_mapper
      @folder_pattern=folder_pattern
      @file_pattern=file_pattern
      @duplicates=[]
      @modifier = FileNameModifier.new
    end

    # Liefert ein Array mit DuplicationFiles
    def mapping
      @files.each do |f|
        File.open(f, "r") do |file|
          modified_time = @time_mapper.time_for_mapping(file)
          file_name_enhancement=modified_time.strftime(@file_pattern)
          target_folder_name = modified_time.strftime(@folder_pattern)

          dup = DuplicationFile.new(file) do |d|
            d.source = f
            d.target = target_folder_name
            d.new_name = modify_filename(f, file_name_enhancement)
          end

          @duplicates << dup
        end

      end
      @duplicates
    end

    :private

    def modify_filename(file, enhancement)
      @modifier.do(file, enhancement)
    end

  end

  class CurrentTimeMapper

    def time_for_mapping(file)
      Time.now
    end

  end


  class ModifiedTimeMapper

    def time_for_mapping(file)
        file.mtime
    end

  end

  class EXIFTimeMapper
    require 'exifr'

    def time_for_mapping(file)
        EXIFR::JPEG.new(file.path).date_time_original
    end

  end

  class CompoundTimeMapper

    def initialize(*time_mapper)
      @time_mapper = time_mapper
    end

    def time_for_mapping(file)
      @time_mapper.each do |mapper|
        begin
          time = mapper.time_for_mapping(file)
        raise Exception.new("mapper returned no mapping time") unless time
          return time
        rescue Exception => details
          print("Error while getting time mapping (mapper=#{mapper.class}) for file #{file.path} => #{details}! Using another mapper!\n")
        end
      end
    end

  end


  class DuplicateCopier

    def initialize(target_folder)
      @target_parent=target_folder
    end

    def handle(dup_file)
      target = File.join(@target_parent, dup_file.target)
      #Zielordner erzeugen
      FileUtils.mkdir_p(target)
      # Datei in Zielordner kopieren
      FileUtils.cp(dup_file.source, target, :preserve => true)
      # kopierte Datei umbenennen
      FileUtils.cd(target) do
        new_name = dup_file.new_name
        if File.exist?(new_name) then
          new_name=FileNameModifier.new.do(new_name, "(#{count_file(new_name)})")
        end
        dup_file.real_new_name=new_name
        FileUtils.mv(File.basename(dup_file.source), dup_file.real_new_name, :verbose => false )
      end
    end

    :private

    def count_file(file)
      extension=File.extname( file )
      name = File.basename( file, extension)
      Dir.glob("#{name}*").length
    end

  end


  class PictureMover

    attr_reader :source
    attr_reader :target

    def initialize(source, target)
      PictureMover.check_folder source
      PictureMover.check_folder target
      @source = source
      @target = target
    end

    def move
      files = SimpleFileLister.new(@source).list

      copier = DuplicateCopier.new(@target)

      mapper = TimeMapper.new(files)
      mapper.modifier = PrefixFileNameModifier.new

      mapper.mapping.each_with_index do |dup, index|
        copier.handle(dup)
        if block_given?
          percent = (index +1).to_f / files.length.to_f
          yield(dup, percent)
        end
      end
    end

    def self.check_folder(file)
      raise Exception.new("Angegebener Ordner existiert nicht: #{file}") unless File.directory?(file)
    end


  end
end