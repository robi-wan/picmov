#!/usr/bin/ruby

# Created by IntelliJ IDEA.
# User: lede55
# Date: 09.10.2007
# Time: 17:03:35
#
#****************************************************************
# Version 0.0.3
# Datum: 15.04.2008
# Änderungen:
# - CompoundTimeMapper: Erhält eine Liste von TimeMappern. Falls der erste TimeMapper kein Ergebnis liefert, wird der nächste TimeMapper verwendet usw. usw. Also eine Art Chain of Responsibility.
# - TimeMapper verwendet nun als Default einen CompoundTimeMapper mit den Mappern EXIFTimeMapper, ModifiedTimeMapper, CurrentTimeMapper. Somit wird also EXIFTimeMapper als erstes verwendet.
#****************************************************************
# Version 0.0.2
# Datum: 15.04.2008
# Änderungen:
# - TimeMapper bekommt nun ein Objekt hereingereicht, welches über die Methode time_for_mapping(file) aus dem übergebenem File ein Datum liefert, welches für das Mapping verwendet werden soll.
#  Drei Implementierungen für solch ein Objekt bereitgestellt:
#  - CurrentTimeMapper: Liefert das aktuelle Datum.
#  - ModifiedTimeMapper: Liefert das modified-Datum der Datei.
#  - EXIFTimeMapper: Liefert aus den Exif-Informationen des Bildes den Wert von 'DateTimeOriginal'. Benötigt die Bibliothek 'exifr' http://exifr.rubyforge.org/.
#  EXIFTimeMapper ist die Defaultvariante.
#****************************************************************

require 'fileutils'

#Aufruf: skript source_path [target_path]
#Wenn target_path nicht angegeben wird, dann wird das aktuelle Verzeichnis angenommen

# Option: -m --move Verschiebt die Dateien, anstatt sie nur zu kopieren

# FileNameMapper: Muster, nach dem die neuen Dateien benannt werden
# default: <name>_<creation_date>.<file_suffix>
# cration_date: YYYY-MM-DD_HH-mm-ss

#Map, die Dateien zu einem Tagesdatum zuordnet
# einfacher für Ordnererstellung

# Ordnererstellung: wenn keiner vorhanden, neuen erstellen: YYYY_MM_DD
# exakte Suche oder Pattern für Ordner (sinnvoll wenn z.B. ein Ordner YYYY_MM_DD_strand existiert
# bei exakt würde neuer erstellt werden, bei pattern erfolgt append)
# und was ist wenn mehrere ordner auf pattern passen? abfrage ala "gem update"

class SimpleFileLister
  def initialize(folder=Dir.pwd)
    @folder = folder
  end

  def list
    files=[]
    FileUtils.cd(@folder) do |path|
      files=Dir.glob("*").collect{|f| File.join(@folder, f)}
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
  # Falls es benoetigt wird: Ein File-Objekt der Quelle
  attr_reader :file

  def initialize(file)
    @file=file
  end

end

class FileNameModifier

  def do(file, enhancement)
    extension=File.extname( file )
    name = File.basename( file, extension)
    name << "_" << enhancement << extension
  end

end

class TimeMapper
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
      file=File.new(f)
      modified_time = @time_mapper.time_for_mapping(file)
      file_name_enhancement=modified_time.strftime(@file_pattern)
      target_folder_name = modified_time.strftime(@folder_pattern)
      ##      puts file.atime
      ##      puts file.ctime

      dup = DuplicationFile.new(file)
      dup.source = f
      dup.target = target_folder_name
      dup.new_name = modify_filename(f, file_name_enhancement)
      @duplicates << dup

      ## (@sorted_files[target_folder_name]||=[]) << f ##

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
    Date.new
  end
  
end


class ModifiedTimeMapper
  
  def time_for_mapping(file)
      file.mtime
  end
  
end

class EXIFTimeMapper
  require 'rubygems'
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
        return mapper.time_for_mapping(file)
      rescue Exception => details
        print("Error while getting time mapping (mapper=#{mapper.class}) for file #{file.path} => #{details}! Using another mapper!\n")
      end
    end
  end
    
end


#~ class ModifiedTimeMapper < TimeMapper
  
  #~ def time_for_mapping(file)
      #~ file.mtime
  #~ end
  
#~ end

#~ class EXIFTimeMapper < TimeMapper
  #~ require 'rubygems'
  #~ require 'exifr'

  #~ def time_for_mapping(file)
      #~ EXIFR::JPEG.new(file.path).date_time_original
  #~ end

#~ end

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
      FileUtils.mv(File.basename(dup_file.source), new_name, :verbose => true )
    end
  end

  :private

  def count_file(file)
    extension=File.extname( file )
    name = File.basename( file, extension)
    Dir.glob("#{name}*").length
  end

end


def check_folder(file)
  raise Exception.new("Angegebener Ordner existiert nicht: #{file}") unless File.directory?(file)
end

### --- Hauptprogramm ---
if $0 == __FILE__ then

  begin

    raise Exception.new("quell- und zielordner erforderlich") if ARGV.length != 2
    source=ARGV[0]
    target=ARGV[1]
    check_folder source
    check_folder target

    files = SimpleFileLister.new(source).list

    copier = DuplicateCopier.new(target)

    #mapper = ModifiedTimeMapper.new(files)
    mapper = TimeMapper.new(files)
    
    
    mapper.mapping.each do |dup|
#      puts dup.source
#      puts (dup.target + "/" + dup.new_name)
      copier.handle(dup)
    end

  rescue Exception => details
    print("Error, program will exit => #{details}!\n")
    print(details.backtrace().join("\n"))
    exit(1)
  end

end