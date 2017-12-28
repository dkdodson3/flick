class Applitools

  attr_accessor :driver, :screenshot, :eyes

  def initialize options
    self.driver = Screenshot.new options
    self.eyes = Applitools::Images::Eyes.new
    eyes.api_key = options[:apiKey] || ENV['APPLITOOLS_API_KEY']
  end
  
  def upload_to_applitools
    path = driver.screenshot
    eyes.test(app_name: app_name, test_name: test_name) do
      eyes.check_image(image_path: file, tag: File.basename(file))
    end
  end
  
  private

end