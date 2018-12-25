
Pod::Spec.new do |spec|
  spec.name         = "VsignFramework"
  spec.version      = "1.0.1"
  spec.summary      = "VsignFramework to verify sign digital"

  spec.description  = "This is framework Vsign allow sign and verify document"

  spec.homepage     = "https://github.com/ngocdtph03070/VsignFramework.git"


  spec.license      = "MIT"
  spec.xcconfig = { "OTHER_LDFLAGS" => "-lz" }
  spec.author       = { "Đỗ Ngọc" => "ngocdtph03070@gmail.com" }

  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/ngocdtph03070/VsignFramework.git", :tag => "#{spec.version}" }
  spec.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }
  spec.source_files  = "VsignFramework/**/*"
  spec.dependency "Alamofire"
  spec.dependency "EVReflection"
  spec.dependency "SwiftyDrop"
  spec.dependency "NVActivityIndicatorView"
end
