#
# Be sure to run `pod lib lint AMGCalendarManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AMGCalendarManager'
  s.version          = '1.3'
  s.summary          = 'EventKit helper for Swift 3 '
  s.description      = <<-DESC
EventKit helper for Swift 3 to create, delete and update events in the easiest way!
                       DESC

  s.homepage         = 'https://github.com/AlbertMontserrat/AMGCalendarManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Albert' => 'albert.montserrat.gambus@gmail.com' }
  s.source           = { :git => 'https://github.com/AlbertMontserrat/AMGCalendarManager.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'AMGCalendarManager/Classes/**/*'

end
