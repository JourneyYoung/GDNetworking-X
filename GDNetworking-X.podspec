#
# Be sure to run `pod lib lint GDNetworking-X.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GDNetworking-X'
  s.version          = '0.1.6'
  s.summary          = 'A short description of GDNetworking-X.It is a heavey network frame for iOS bases on Objective-C'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/journeyyoung/GDNetworking-X'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'journey' => 'journey.yu@dingtone.me' }
  s.source           = { :git => 'https://10.88.0.15/journey/GDNetworking-X.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  #s.source_files = 'GDNetworking-X/Classes/**/*'
  
  s.subspec 'Core' do |ss|
    ss.dependency 'GDNetworking-X/DataManager'
    ss.dependency 'GDNetworking-X/NetworkLog'
    ss.dependency 'GDNetworking-X/CoreManager'
    ss.dependency 'GDNetworking-X/Request'
  end

  s.subspec 'DataManager' do |ss|
    ss.source_files = 'NetworkClass/DataManager/**/*'
  end
  
  s.subspec 'NetworkLog' do |ss|
    ss.source_files = 'NetworkClass/NetworkLog/**/*'
  end

  s.subspec 'CoreManager' do |ss|
    ss.source_files = 'NetworkClass/CoreManager/**/*'
  end
  
  s.subspec 'Request' do |ss|
    ss.source_files = 'NetworkClass/Request/**/*'
  end

  # s.resource_bundles = {
  #   'GDNetworking-X' => ['GDNetworking-X/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking'
  s.framework = 'CFNetwork'
end
