module Flick
  class Ios
    attr_accessor :flick_dir, :udid, :name, :outdir, :todir, :specs

    def initialize options
      self.udid = options.fetch(:udid, get_device_udid(options))
      self.flick_dir = "#{Dir.home}/.flick/#{udid}"
      self.todir = options.fetch(:todir, self.flick_dir)
      self.outdir = options.fetch(:outdir, Dir.pwd)
      self.specs = options.fetch(:specs, false)
      create_flick_dirs

      if is_physical_device?
        self.name = remove_bad_characters(options.fetch(:name, self.udid))
      else
        self.name = options.fetch(:name, nil)
        if self.name == nil
          self.name = self.udid
        else
          self.name = remove_bad_characters(self.name)
        end
      end

      is_paired?
    end

    def remove_bad_characters string
      string.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')
    end

    def create_flick_dirs
      Flick::System.setup_system_dir "#{Dir.home}/.flick"
      Flick::System.setup_system_dir flick_dir
    end

    def is_physical_device?
      Flick::Checker.system_dependency "instruments"
      o, e, s = Open3.capture3("instruments -s devices | grep #{self.udid}")
      if "#{s}".include? "exit 0"
        if "#{o}".include? "Simulator"
          return false
        else
          return true
        end
      else
        puts "Could not find a device with udid: #{udid}".red
        abort
      end
    end

    def is_simulator_booted?
      Flick::Checker.system_dependency "xcrun"
      o, e, s = Open3.capture3("xcrun simctl list | grep #{udid} | grep Booted")
      if not "#{s}".include? "exit 0"
        puts "\nSimulator is not Booted\n".red
        abort
      end
    end

    def is_paired?
      if is_physical_device?
        Flick::Checker.system_dependency "idevicename"
        if Open3.capture3("idevicename -u #{udid}")[1].split[0] == "ERROR:"
          puts "\nUDID: #{udid} - Is not paired with your machine!\nOr make sure the device is not locked!\n".red
          puts "Run: idevicepair -u <udid> pair\nIf not working still, see: https://github.com/isonic1/flick/issues/10\n".red
          puts "Read more information about libmobiledevice libraries, see: http://libimobiledevice.org".green
          abort
        end
      else
        is_simulator_booted?
      end
    end

    def devices
      Flick::Checker.system_dependency "idevice_id"
      if not (`idevice_id -l`).empty?
        (`idevice_id -l`).split.uniq.map { |d| d }
      else
        (`xcrun simctl list | grep Booted | awk '{print $(NF-1)}' | tr -d "()"`).split.uniq.map { |d| d }
      end
    end

    def devices_connected?
      devices.any?
    end

    def check_for_devices
      unless devices_connected?
        puts "\nNo iPhone or iPad Devices Connected!!!\n".red
        abort
      end
    end

    def get_device_udid opts_hash
      check_for_devices
      return unless opts_hash[:udid].nil?
      if devices.size == 1
        devices[0]
      else
        puts "\nMultiple iOS devices '#{devices}' found.\nSpecify a single UDID. e.g. -u #{devices.sample}\n".red
        abort unless specs
      end
    end

    def info
      specs = { os: "ProductVersion", name: "DeviceName", arc: "CPUArchitecture", type: "DeviceClass", sdk: "ProductType" }
      if is_physical_device?
        hash = { udid: udid }
        specs.each do |key, spec|
          value = (`ideviceinfo -u #{udid} | grep #{spec} | awk '{$1=""; print $0}'`).strip
          hash.merge!({key=> "#{value}"})
        end
        hash
      end
    end

    def recordable?
      false
    end

    def clear_files
      Flick::System.clean_system_dir flick_dir, udid
    end

    def screenshot name
      if is_physical_device?
        Flick::Checker.system_dependency "idevicescreenshot"
        %x(idevicescreenshot -u #{udid} #{todir}/#{name}.png)
      else
        %x(xcrun simctl io #{udid} screenshot #{todir}/#{name}.png)
      end
    end

    def log name
      loc = #{outdir}/#{name}.log
      if is_physical_device?
        Flick::Checker.system_dependency "idevicesyslog"
        system("idevicesyslog -u #{udid} > #{loc}")
      else
        system("xcrun simctl spawn #{udid} log stream > #{loc}")
      end
      #file = File.open("#{loc}", 'a') { |f| f.puts "\n<<<<<<<<<<<<<<<<<<<<<<<<< FLICK LOG START >>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n" }
      #file.close
    end

    def install app_path
      if is_physical_device?
        Flick::Checker.system_dependency "ideviceinstaller"
        %x(ideviceinstaller -u #{udid} -i #{app_path})
      else
        %x(xcrun simctl install #{udid} #{app_path})
      end
    end

    def uninstall package
      if is_physical_device?
        Flick::Checker.system_dependency "ideviceinstaller"
        if app_installed? package
          %x(ideviceinstaller -u #{udid} -U #{package})
        else
          puts packages
          puts "\n#{package} was not found on device #{udid}! Please choose one from above. e.g. #{packages.sample}\n".red
        end
      else
        o, e, s = Open3.capture3("xcrun simctl uninstall #{udid} #{package}")
        if not "#{s}".include? "exit 0"
          puts packages
          puts "\n#{package} was not found on device #{udid}! Please choose one from above. e.g. #{packages.sample}\n".red
        end
      end
    end

    def app_installed? package
      packages.include? "#{package}"
    end

    def packages
      %x(ideviceinstaller -u #{udid} -l -o list_user).split("\n")[1..100000].map { |p| p.match(/(.*) -/)[1] }
    end

  end
end