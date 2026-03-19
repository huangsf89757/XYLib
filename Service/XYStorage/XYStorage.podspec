#
# Be sure to run `pod lib lint XYStorage.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XYStorage'
  s.version          = '1.0.0'
  s.summary          = 'A short description of XYStorage.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/hsf89757/XYStorage'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hsf89757' => 'hsf89757@gmail.com' }
  s.source           = { :git => 'https://github.com/hsf89757/XYStorage.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  # --- Target --- #
  s.ios.deployment_target = '14.0'
  s.watchos.deployment_target = '9.0'
  
  # --- Frameworks --- #
  s.ios.frameworks = 'UIKit', 'Foundation'
  s.watchos.frameworks = 'WatchKit', 'Foundation'
  
  # --- Dependency --- #
  # Basic
  s.dependency 'XYExtension'
  # Service <--
  s.dependency 'XYLog'
  # Tool
  s.dependency 'XYUtil'
  # Business
  # Third

  # --- Subspec --- #
  # default
  s.default_subspec = 'Core'
  
  # Core
  s.subspec 'Core' do |core|
    core.source_files = 'XYStorage/Classes/Core/**/*.swift'
    core.frameworks = 'Foundation'
  end

  # WCDB
  s.subspec 'WCDB' do |wcdb|
    wcdb.source_files = [
      'XYStorage/Classes/Core/**/*.swift',
      'XYStorage/Classes/WCDB/**/*.swift'
    ]
    wcdb.dependency 'XYStorage/Core'
    wcdb.dependency 'WCDB.swift'
  end

  # GRDB
  s.subspec 'GRDB' do |grdb|
    grdb.source_files = [
      'XYStorage/Classes/Core/**/*.swift',
      'XYStorage/Classes/GRDB/**/*.swift'
    ]
    grdb.dependency 'XYStorage/Core'
    grdb.dependency 'GRDB.swift'
  end

  # Realm
  s.subspec 'Realm' do |realm|
    realm.source_files = [
      'XYStorage/Classes/Core/**/*.swift',
      'XYStorage/Classes/Realm/**/*.swift'
    ]
    realm.dependency 'XYStorage/Core'
    realm.dependency 'RealmSwift'
  end
  
end
