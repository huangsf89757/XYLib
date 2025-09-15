#
# Be sure to run `pod lib lint XYCgms.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XYCgms'
  s.version          = '1.0.0'
  s.summary          = 'A short description of XYCgms.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/hsf89757/XYCgms'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hsf89757' => 'hsf89757@gmail.com' }
  s.source           = { :git => 'https://github.com/hsf89757/XYCgms.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  # 公共依赖（所有平台共享）
  s.dependency 'XYExtension'
  s.dependency 'XYUtil'
  s.dependency 'XYLog'
  s.dependency 'XYCoreBluetooth'
  s.dependency 'XYWatchConnectivity'
  s.dependency 'XYStorage'
  s.dependency 'XYNetwork'
  s.dependency 'MTBleCore'
  
  # 公共代码
  shared_files = 'XYCgms/Classes/**/*.swift'

  # iOS 平台配置
  s.ios.deployment_target = '14.0'
  s.ios.source_files = [
    shared_files
  ]
  s.ios.frameworks = 'UIKit', 'Foundation'

  # watchOS 平台配置
  s.watchos.deployment_target = '9.0'
  s.watchos.source_files = [
    shared_files
  ]
  s.watchos.frameworks = 'WatchKit', 'Foundation'

   
end
