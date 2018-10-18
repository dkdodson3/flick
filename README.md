# FLICK
A CLI to capture screenshots, video, logs, device info and device vitals(memory, cpu) for Android (Devices & Emulators) and iOS (Devices).

<img src="https://www.dropbox.com/s/o49et3fhncu3l4v/animacii_09.gif?raw=1" width="600">

Features
--------

* Easily capture screenshots for Android and iOS.
* Video record real android devices. (OS > 4.4)
	* Extend recording past the 180 seconds SDK limit.
* Save video formats in mp4 or gif.
* Flick auto detects if a device is recordable.
	* Falls back to screenshot recording if video record is not available.
* Video record android emulators and **real** iOS devices/simulators.
	* Takes a screenshot every 0.5 seconds (default), then combines the screenshots into a single mp4 or gif.
	* Android pulls only unique (default) screenshots from devices/emulators. e.g. A 1 minute test run might convert to only 30 seconds of video based on unique images. You can change this by passing `-q false` to pull all images instead.
	* iOS example [here](https://www.dropbox.com/s/4pjhhmnsx9gj5pi/ios-flick-example.mp4?dl=0)
	* Android Emulator example [here](https://www.dropbox.com/s/gwunrvgzxkny13z/android-flick-example.mp4?dl=0)
* Flick auto selects device when only one device is connected, per platform.
* Save log output for Android or iOS.
* Display device information or save it to a file.
* Install or Uninstall applications from devices.
* Capture device vitals (Android Only) for app and system performance. 
   * If anyone knows of a tool to capture performance for iOS please let me know and I'll add it to Flick.
* Checkout the latest release notes [here](https://github.com/isonic1/flick/releases).

Reason
------
I wanted an easy way to video record my automation tests for mobile, and I didn't need the video quality to be perfect. Unfortunately, you cannot video record on android emulators, but you can take screenshots! You also cannot video record iOS without using QuickTime, or doing what [this](https://github.com/appium/screen_recording) did, but it's not maintained anymore.

So I created Flick to work for my needs, and included a couple other tools I use frequently. Hopefully this will be as helpful for others too. It's also a CLI and language-agnostic, it can be used with any framework where you can make a system call. See examples [here](https://github.com/isonic1/appium-mobile-grid/blob/flick/ios/spec/spec_helper.rb#L15-L16) and [here](https://github.com/isonic1/appium-mobile-grid/blob/flick/android/spec/spec_helper.rb#L22-L23). I suppose there are use cases for this outside of test automation. I'd love to hear them if so.

If you're looking for high-quality video, then this wouldn't be the tool for you. Take a look at this great tool [androidtool-mac](https://github.com/mortenjust/androidtool-mac) instead.

Prerequisites
-------------
#### System Tools
* Install ffmpeg. [OSX](https://trac.ffmpeg.org/wiki/CompilationGuide/MacOSX)
	* ```$ brew install ffmpeg```
* Install mp4box. [OSX](http://hunterford.me/compiling-mp4box-on-mac-os-x/)
	* ```$ brew install mp4box```

#### Android
* Install [SDK Tools](http://developer.android.com/sdk/installing/index.html?pkg=tools).
* SDK tools are added to your $PATH. [OSX](http://stackoverflow.com/questions/5526470/trying-to-add-adb-to-path-variable-osx)
* Enable [USB Debugging](https://www.kingoapp.com/root-tutorials/how-to-enable-usb-debugging-mode-on-android.htm) on your device(s).
* Emulator or Devices have approximately 1GB of [sdcard space](http://developer.android.com/tools/help/mksdcard.html).

#### iOS
* Install [Xcode](https://developer.apple.com/xcode/download/).
* Install Xcode [Command Line Tools](http://railsapps.github.io/xcode-command-line-tools.html).
* Enable [Developer Mode](http://apple.stackexchange.com/questions/159196/enable-developer-inside-the-settings-app-on-ios) on iPhone or iPad devices.
* Install [libimobiledevice](http://www.libimobiledevice.org/).
	* ```$ brew install libimobiledevice```

#### Known Issues
* IOS:
   * Sometimes ideviceinstaller gets out of sync with your OS due to various reasons. When this happens, screenshots and video will not work for iOS.
      * Follow steps in [here](https://github.com/isonic1/flick/issues/10) to uninstall and reinstall dependencies.
      * Make sure xcode and command line tools are up to date.
      * Make sure iOS device is up to date with latest iOS version.
      * Validate your device is paired to your machine. `$ idevicepair -u <udid> validate`
      * Additionally, try to unpair and pair again.
         * `$ idevicepair -u <udid> unpair`
         * `$ idevicepair -u <udid> pair` Accept the Trust popup on the device.

* Android:
   * Some devices/emulators are read-only. Flick requires access to internal storage of the device/emulator to write files to. If the device is read-only it cannot do this so it will Abort. There is probably a solution to this but I, unfortunately, don't have a lot of time to figure it out. Pull Requests are highly encouragaged if you find this tool useful!

Installation
------------

    $ gem install flick


Usage:
------
    $ flick --help

    DESCRIPTION:

    A CLI to capture screenshots, video, logs, and device info for Android (Devices & Emulators) and iOS (Devices).

	COMMANDS:

    help       Display global or [command] help documentation           
    info       Get device information           
    log        Get device log output            
    manager    Manage apps on devices           
    screenshot Take a screenshot                
    video      Record video             
    vitals     Android Only! Get apps and device vitals - App Memory Used, App CPU %. System Stats: (User, System, IQW, IRQ)
    applitools Validate images with Applitools 

    GLOBAL OPTIONS:

    -h, --help
      Display help documentation

    -v, --version
      Display version information

    -t, --trace
      Display backtrace when an error occurs

	 $ flick info --help

		$ flick info -p (ios or android)
		$ flick info -p (ios or android) -s true -o $HOME


	 $ flick log --help

		$ flick log -a start -p (ios or android) -o $HOME -n iosLog
		$ flick log -a stop -p (ios or android)

	 $ flick screenshot --help

		$ flick screenshot -p (ios or android) -o $HOME -n myImage

	 $ flick video --help

		$ flick video -a start -p (ios or android)
		$ flick video -a stop -p (ios or android) -o /output -n myVideo -f gif
		$ flick video -a start -p android -u emulator-5554 -c 1000
		$ flick video -a stop -p android -u emulator-5554

	 $ flick manager --help
		$ flick manager -a install -p (ios or android) -f ~/myApp/my-awesome-app.apk or .app
		$ flick maanger -a uninstall -p (ios or android) -n com.package.name

	 $ flick vitals --help
		$ flick vitals -p android -n com.awsome-package.name

    $ flick applitools --help
      $ flick applitools -p android --appName Twitter --testName Messages 

##Demo
<img src="https://www.dropbox.com/s/9be37gc1c2dlxa6/flick-demo.gif?raw=1" width="600">

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/isonic1/flick. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://github.com/isonic1/Appium-Native-Crawler/blob/master/CODE_OF_CONDUCT.md) code of conduct.

## TODO
* Dry the code a bit.
* Setup Flick android for cross platform os's (windows & linux)
* Multithread the screenshot and pull process.
* Look into capturing video for iOS similar to [this](https://github.com/mortenjust/androidtool-mac/blob/9347cd9aeca9e7370e323d12f862bc5d8beacc25/AndroidTool/IOSDeviceHelper.swift#L56)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

