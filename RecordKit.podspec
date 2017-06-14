Pod::Spec.new do |s|
  s.name         = "RecordKit"
  s.version      = "1.0.0"
  s.platform     = :ios, "8.0"
  s.summary      = "Record or stream video from the screen, and audio from the app and microphone"
  s.description  = "Record or stream video from the screen, and audio from the app and microphone"
  s.homepage     = "https://github.com/goccy/RecordKit"
  s.license      = { :type => 'MIT' }
  s.author       = { "goccy" => "goccy54@gmail.com" }
  s.requires_arc = true
  s.public_header_files = "RecordKit/RecordKit.h", "RecordKit/RecordKitBridge.h"
  s.ios.frameworks = "OpenGLES", "QuartzCore", "CoreMedia", "CoreVideo", "AVFoundation", "AudioToolbox", "AssetsLibrary"
  s.source_files   = "RecordKit/*.{h,m,mm}"
  s.source = { :git => "git@github.com:goccy/RecordKit.git" }
end
