#
# Be sure to run `pod lib lint XYGlucose.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XYGlucose'
  s.version          = '1.0.0'
  s.summary          = 'A short description of XYGlucose.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/hsf89757/XYGlucose'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hsf89757' => 'hsf89757@gmail.com' }
  s.source           = { :git => 'https://github.com/hsf89757/XYGlucose.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  # --- Version --- #
  s.swift_version    = '5.7'
  
  # --- Target --- #
  s.ios.deployment_target = '14.0'
  s.watchos.deployment_target = '9.0'
  
  # --- Frameworks --- #
  s.ios.frameworks = 'UIKit', 'Foundation'
  s.watchos.frameworks = 'WatchKit', 'Foundation'
  
  # --- Dependency --- #
  # Basic
  # Service
  s.dependency 'XYLog'
  s.dependency 'XYCoreBluetooth'
  s.dependency 'XYWatchConnectivity'
  s.dependency 'XYStorage'
  s.dependency 'XYNetwork'
  # Tool
  # Business <--
  s.dependency 'XYUser'
  # Third
  s.dependency 'MTBleCore'
  
  # --- SourceFile --- #
  shared_files = 'XYGlucose/Classes/**/*.swift'
  s.ios.source_files = [
    shared_files,
  ]
  s.watchos.source_files = [
    shared_files,
  ]

   
end
