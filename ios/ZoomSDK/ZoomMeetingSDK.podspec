Pod::Spec.new do |s|
  s.name = 'ZoomMeetingSDK'
  s.version = '6.7.5'
  s.summary = 'Local Zoom Meeting SDK wrapper for LinguFranca iOS builds.'
  s.description = 'Bundles the official Zoom iOS Meeting SDK xcframework and resource bundle for native in-app lesson joins.'
  s.homepage = 'https://developers.zoom.us/docs/meeting-sdk/'
  s.license = { :type => 'Commercial' }
  s.author = { 'Zoom Video Communications' => 'developersupport@zoom.us' }
  s.platform = :ios, '13.0'
  s.source = { :path => '.' }
  s.vendored_frameworks = 'MobileRTC.xcframework'
  s.resources = 'MobileRTCResources.bundle'
  s.frameworks = 'AVFoundation', 'AudioToolbox', 'CoreAudio', 'CoreGraphics', 'CoreMedia', 'SystemConfiguration', 'VideoToolbox'
  s.libraries = 'c++', 'sqlite3', 'z'
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '$(inherited) -ObjC' }
end
