class Screenshot

  attr_accessor :platform, :driver

  def initialize options
    Flick::Checker.platform options[:platform]
    self.platform = options[:platform]
    case platform
    when "ios"
      options[:todir] = options[:outdir]
      self.driver = Flick::Ios.new options
    when "android"
      self.driver = Flick::Android.new options
    end
    setup
  end

  def screenshot
    driver.screenshot driver.name
    driver.pull_file "#{driver.dir_name}/#{driver.name}.png", driver.outdir if android
    if File.exists? "#{driver.outdir}/#{driver.name}.png"
      puts "Saved image to: #{driver.outdir}/#{driver.name}.png" 
      return { path: "#{driver.outdir}/#{driver.name}.png", udid: driver.udid }
    else
      puts "\nThere appears to be an issue capturing the #{platform} image. Run flick with --trace for more details.\n".red
      abort
    end
  end

  private

  def android
    platform == "android"
  end

  def setup
    driver.clear_files
  end
end