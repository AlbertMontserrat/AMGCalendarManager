#
# Be sure to run `pod lib lint AMGCalendarManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AMGCalendarManager'
  s.version          = '1.0'
  s.summary          = 'A short description of AMGCalendarManager.'
  s.description      = <<-DESC
EventKit helper for Swift 3 
                       DESC

  s.homepage         = 'https://github.com/Albert/AMGCalendarManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Albert' => 'albert.montserrat.gambus@gmail.com' }
  s.source           = { :git => 'https://github.com/Albert/AMGCalendarManager.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'AMGCalendarManager/Classes/**/*'

end
