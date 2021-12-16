#
# Be sure to run `pod lib lint FGLargeImageDownsizingView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FGLargeImageDownsizingView'
  s.version          = '0.1.0'
  s.summary          = 'A short description of FGLargeImageDownsizingView.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/FoneG/FGLargeImageDownsizingView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '15757127193@163.com' => 'xisuo@maltbaby.com.cn' }
  s.source           = { :git => 'git@github.com:FoneG/FGLargeImageDownsizingView.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'FGLargeImageDownsizingView/Classes/**/*'
  s.swift_version = '5.0'
  
end
