require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-image-filters"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "18.0" }
  s.source       = { :git => "https://github.com/yourusername/react-native-image-filters.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.resources = "ios/**/*.metal"
  
  s.dependency "React-Core"
  
  # Enable New Architecture
  install_modules_dependencies(s)
  
  # Metal shader compilation
  s.xcconfig = {
    'MTL_COMPILER_FLAGS' => '-ffast-math'
  }
  
  # Use frameworks for Swift
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'SWIFT_OPTIMIZATION_LEVEL' => '-O'
  }
  
  s.frameworks = 'Metal', 'MetalKit', 'CoreImage', 'Accelerate', 'UIKit', 'Foundation'
  s.swift_version = '5.9'
end

