require 'json'
require 'fileutils'
require 'shell'
require 'git'
module Builder
  class Script
    FEATURES = ['server', 'hardware', 'multiglass', 'widget', 'extra-apk', 'eyetracker', 'custom-web']
    def self.FEATURES
      FEATURES
    end
    def self.do
      puts "What is the name of your script?"
      puts "\tPlease use kabob case. (your-script-name)"
      name = $stdin.gets.chomp
      ScriptBuilder.new(name).do
    end

    def initialize name
      @manifest = {}
      @manifest[:name] = name
      @name = name
      @manifest[:authors] = []
      @manifest[:tags] = []
      @git = Git.open(Dir.pwd)
    end

    def do
      @manifest[:authors] << Author.do
        begin
          puts "Would you like to add another author? [y/N]"
          another = $stdin.gets.chomp == 'y'
          @manifest[:authors] << Author.do if another
        end while another
        puts "App description:"
        @manifest[:description] = $stdin.gets.chomp
        puts "\nNow we are going to ask what features you will require"
        FEATURES.each do |f|
          puts "Do you use #{f}? [y/N]"
          @manifest[:tags] << f if $stdin.gets.chomp == 'y'
        end
        puts "Enter tags, one each line. Blank line to finish"
        while (tag = $stdin.gets.chomp).length > 0
          @manifest[:tags] << tag
        end
        puts "What would you like your VOICE_TRIGGER to be? (Optional)"
        @manifest[:voice_trigger] = $stdin.gets.chomp
        if @manifest[:voice_trigger].length > 0
          puts "Would you like us to build you an APK version? [y/N]"
          @manifest[:tags] << "apk" if $stdin.gets.chomp == 'y'
        end
        write
        git_new
    end

    def write
      puts "Building your script skeleton"
      @path = "scripts/#{@name}"
      FileUtils.mkdir_p(@path)
      FileUtils.mkdir_p("#{@path}/includes")
      File.open("#{@path}/includes/.gitkeep", 'w') {|f| f.write('')}
      FileUtils.mkdir_p("#{@path}/screenshots")
      File.open("#{@path}/screenshots/.gitkeep", 'w') {|f| f.write('')}
      FileUtils.cp("template.html", "#{@path}/index.html")
      File.open("#{@path}/manifest.json", 'w') {|f| f.write(JSON.pretty_generate(@manifest))}
    end

    def git_new
      @git.pull
      @git.add(@path)
      @git.commit "Skeleton for #{@name}"
    end

    def submit
      @git.remote('origin').fetch
      @git.add(@path)
      @git.commit "Submitting #{@name}"
      system "git rebase origin/master"
      @git.push
    end
    end

    class Author
      def self.do
        puts "Author Information:"
        a = {}
        puts "Github:"
        a[:github] = $stdin.gets.chomp
        if File.file? "authors/#{a[:github]}.json"
          puts "Reusing author data"
          @manifest[:authors] << a[:github]
          return
        end
        puts "Name:"
        a[:name] = $stdin.gets.chomp
        puts "Email:"
        a[:email] = $stdin.gets.chomp
        puts "URL:"
        a[:url] = $stdin.gets.chomp
        File.write("authors/#{a[:github]}.json", JSON.pretty_generate(a))
        return a[:github]
      end
    end
  end
