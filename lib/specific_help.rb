# -*- coding: utf-8 -*-
require "optparse"
require "yaml"
require "my_help/version"

module SpecificHelp
  class Command

    def self.run(file,argv=[])
      new(file, argv).execute
    end

    def initialize(file,argv=[])
      @source_file = file
      @help_cont = YAML.load(File.read(file))
      @help_cont[:head].each{|line| print line.chomp+"\n" } if @help_cont[:head] != nil
      @help_cont[:license].each{|line| print "#{line.chomp}\n" } if @help_cont[:license] != nil
      @argv = argv
    end

    def execute
      if @argv.size==0
        if @source_file.include?('todo')
          @argv << '--all'
        else
          @argv << '--help'
        end
      end
      command_parser = OptionParser.new do |opt|
        opt.on('-v', '--version','show program Version.') { |v|
          opt.version = MyHelp::VERSION
          puts opt.ver
        }
        @help_cont.each_pair{|key,val|
          next if key==:head or key==:license
          opts = val[:opts]
          opt.on(opts[:short],opts[:long],opts[:desc]) {disp_help(key)}
        }
        opt.on('--edit','edit help contents'){edit_help}
        opt.on('--to_hiki','convert to hikidoc format'){to_hiki}
        opt.on('--all','display all helps'){all_help}
        opt.on('--store [item]','store [item] in backfile'){|item| store(item)}
        opt.on('--remove [item]','remove [item] and store in backfile'){|item| remove(item) }
        opt.on('--add [item]','add new [item]'){|item| add(item) }
      end
#      begin
      command_parser.parse!(@argv)
#      rescue=> eval
#       p eval
#      end
      exit
    end

    def mk_backup_file(file)
      path = File.dirname(file)
      base = File.basename(file)
      backup= File.join(path,"."+base)
      FileUtils.touch(backup) unless File.exists?(backup)
      return backup
    end

    def store(item)
      backup=mk_backup_file(@source_file)
      store_item = @help_cont[item.to_sym]
      p store_name = item+"_"+Time.now.strftime("%Y%m%d_%H%M%S")
      cont = {store_name.to_sym => store_item}
      File.open(backup,'a'){|file| file.print(YAML.dump(cont))}
    end

    def add(item='new_item')
      new_item={:opts=>{:short=>'-'+item[0], :long=>'--'+item, :desc=>item},
          :title=>item, :cont=> [item]}
      @help_cont[item.to_sym]=new_item
      File.open(@source_file,'w'){|file| file.print YAML.dump(@help_cont)}
    end

    def remove(item)
      store(item)
      @help_cont.delete(item.to_sym)
      File.open(@source_file,'w'){|file| file.print YAML.dump(@help_cont)}
    end

    def edit_help
      system("emacs #{@source_file}")
    end

    def to_hiki
      @help_cont.each_pair{|key,val|
        if key==:head or key==:license
          hiki_disp(val)
        else
          hiki_help(key)
        end
      }
    end

    def all_help
      @help_cont.each_pair{|key,val|
        if key==:head or key==:license
          disp(val)
        else
          disp_help(key)
        end
      }
    end

    def hiki_help(key_word)
      items =@help_cont[key_word]
      puts "\n!!"+items[:title]+"\n"
      hiki_disp(items[:cont])
    end

    def hiki_disp(lines)
      lines.each{|line| puts "*#{line}"}  if lines != nil
    end

    def disp_help(key_word)
      print_separater
      items =@help_cont[key_word]
      puts items[:title]
      disp(items[:cont])
      print_separater
    end

    def disp(lines)
      lines.each{|line| puts "  *#{line}"} if lines != nil
    end

    def print_separater
      print "---\n"
    end
  end
end
