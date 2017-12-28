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
    binding.pry
    puts "Saving to #{driver.outdir}/#{driver.name}.png"
    driver.screenshot driver.name
    driver.pull_file "#{driver.dir_name}/#{driver.name}.png", driver.outdir if android
    return "#{driver.outdir}/#{driver.name}.png"
  end

  private

  def android
    platform == "android"
  end

  def setup
    driver.clear_files
  end
end