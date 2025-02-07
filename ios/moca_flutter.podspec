Pod::Spec.new do |s|
  s.name             = 'moca_flutter'
  s.version          = '3.8.0'
  s.summary          = 'Flutter package for Moca SDK'
  s.description      = 'Flutter package for Moca SDK. Moca is a geofencing platform for apps. We provide best-in-class, privacy-aware, location-based experiences with SDKs, APIs and dashboards for geofencing, beaconing and analytics.'
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Moca Technologies, LLC' => 'support@mocaplatform.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'MocaSDK', '3.10.5'
  s.platform = :ios, '12.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported. 
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
