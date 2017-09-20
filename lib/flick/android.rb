module Flick
  class Android
    attr_accessor :udid, :flick_dir, :dir_name, :name, :outdir, :unique, :limit, :specs, :size

    def initialize options
      Flick::Checker.system_dependency "adb"
      if options[:udid].nil?
        self.udid = get_device_udid
      else
        self.udid = options[:udid]
      end
      self.flick_dir = "#{Dir.home}/.flick/#{udid}"
      self.dir_name = "sdcard/flick"
      self.name = remove_bad_characters(options.fetch(:name, self.udid))
      self.outdir = options.fetch(:outdir, Dir.pwd)
      self.unique = options.fetch(:unique, true).to_b
      self.limit = options.fetch(:limit, 180)
      self.specs = options.fetch(:specs, false)
      self.size = options.fetch(:size, "720x1280")
      create_flick_dirs
    end

    def remove_bad_characters string
      string.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')
    end

    def create_flick_dirs
      Flick::System.setup_system_dir "#{Dir.home}/.flick"
      Flick::System.setup_system_dir flick_dir
      message = %x(adb -s #{udid} shell 'mkdir #{dir_name}').split(":").last.strip rescue nil
      if message == "Read-only file system"
        puts "\nDevice: '#{udid}' is a 'Read-only file system'! Flick cannot write to the sdcard folder. Aborting...\n".red
        abort
      end
    end

    def clear_files
      Flick::System.clean_system_dir flick_dir, udid
      %x(adb -s #{udid} shell rm '#{dir_name}/*')
    end

    def devices
      (`adb devices`).scan(/\n(.*)\t/).flatten
    end

    def devices_connected?
      devices.any?
    end

    def check_for_devices
      unless devices_connected?
        puts "\nNo Devices Connected or Authorized!!!\nMake sure at least one device (emulator/simulator) is connected!\n".red
        abort
      end
    end

    def get_device_udid
      check_for_devices
      if devices.size == 1
        devices.first
      else
        puts "\nMultiple android devices '#{devices}' found.\nSpecify a single UDID. e.g. -u #{devices.sample}\n".red
        abort unless specs
      end
    end

    def info
      specs = { os: "ro.build.version.release", manufacturer: "ro.product.manufacturer", model: "ro.product.model", sdk: "ro.build.version.sdk" }
      hash = { udid: udid }
      specs.each do |key, spec|
        value = `adb -s #{udid} shell getprop "#{spec}"`.strip
        hash.merge!({key=> "#{value}"})
      end
      hash
    end
    
    def system_stats
      x = %x(adb -s #{udid} shell top -n 1 -d 1 | grep System).split(",")
      user = x.find { |x| x.include? "User" }.match(/User (.*)%/)[1].to_i
      sys  = x.find { |x| x.include? "System" }.match(/System (.*)%/)[1].to_i
      iow  = x.find { |x| x.include? "IOW" }.match(/IOW (.*)%/)[1].to_i
      irq  = x.find { |x| x.include? "IRQ" }.match(/IRQ (.*)%/)[1].to_i
      { user: user, system: sys, iow: iow, irq: irq }
    end

    def memory package
      (%x(adb -s #{udid} shell dumpsys meminfo | grep #{package} | awk '{print $1}').strip.split.last.to_i * 0.001).round(2)
    end

    def cpu package
      %x(adb -s #{udid} shell top -n 1 -d 1 | grep #{package} | awk '{print $3}').strip.chomp("%").to_i
    end
    
    def get_vitals package
      if app_installed? package
        stats = JSON.generate({ app_stats: { memory_mb: memory(package), cpu_per: cpu(package) }, system_stats: system_stats })
        json = JSON.parse stats
        puts json
        json
      else
        puts packages
        puts "\n#{package} was not found on device #{udid}! Please choose one from above. e.g. #{packages.sample}\n".red
      end
    end
    
    def install app_path
      %x(adb -s #{udid} install -r #{app_path})
    end

    def uninstall package
      if app_installed? package
        %x(adb -s #{udid} shell pm uninstall #{package})
      else
        puts packages
        puts "\n#{package} was not found on device #{udid}! Please choose one from above. e.g. #{packages.sample}\n".red
      end
    end

    def app_version app_path
      manifest(app_path).find {|x| x.name == "versionName" }["value"]
    end

    def package_name app_path
      manifest(app_path).find {|x| x.name == "package" }["value"]
    end

    def manifest app_path
      data = ApkXml.new app_path
      data.parse_xml("AndroidManifest.xml", false, true)
      data.xml_elements[0].attributes
    end

    def app_installed? package
      packages.include? "package:#{package}"
    end

    def packages
      %x(adb -s #{udid} shell pm list packages).split
    end

    def os_version
      %x(adb -s #{udid} shell getprop "ro.build.version.release").strip.to_f
    end

    def screenshot name
      %x(adb -s #{udid} shell screencap #{dir_name}/#{name}.png)
    end

    def log name
      %x(adb -s #{udid} logcat -c)
      %x(adb -s #{udid} logcat -v long > #{outdir}/#{name}.log)
    end

    def recordable?
      if info[:manufacturer] == "Genymotion"
        return false
      else
        %x(adb -s #{udid} shell "ls /system/bin/screenrecord").strip == "/system/bin/screenrecord"
      end
    end

    def screenrecord name
      %x(adb -s #{udid} shell screenrecord --time-limit #{limit} --size #{size} #{dir_name}/#{name}.mp4)
    end

    def pull_file file, dir
      %x(adb -s #{udid} pull #{file} #{dir})
    end

    def unique_files type
      if os_version < 6.0
        command = "md5"
      else
        command = "md5sum"
      end
      files = %x(adb -s #{udid} shell "#{command} #{dir_name}/#{type}*")
      hash = files.split("\r\n").map { |file| { md5: file.match(/(.*) /)[1].strip, file: file.match(/ (.*)/)[1].strip } }
      hash.uniq! { |e| e[:md5] }
      hash.map { |file| file[:file] }
    end
    
    def pull_files type
      if unique
        files = unique_files type
      else
        files = %x(adb -s #{udid} shell "ls #{dir_name}/#{type}*").split("\r\n")
      end
      return if files.empty?
      Parallel.map(files, in_threads: 10) do |file| 
        pull_file file, flick_dir
        #Flick::System.wait_for_file 10, "#{flick_dir}/#{file.split("/").last}"
      end
    end
  end
end