#
# Be sure to run `pod lib lint SKNetMintorLib.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SKNetMintorLib'
  s.version          = '1.0.0'
  s.summary          = '网络日志库，私有化部署'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/shuaikel/SKPodSpace.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'shuaike' => '718401263@qq.com' }
  s.source           = { :git => 'git@github.com:shuaikel/SKNetMintorLib.git', :tag => s.version }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'SKNetMintorLib/Classes/**/*'
  
   s.resource_bundles = {
     'SKNetMintorLib' => ['SKNetMintorLib/Assets/**/*']
   }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit'
   s.dependency 'MJExtension'
   s.dependency 'Reachability'
   s.libraries  = 'sqlite3'
end
