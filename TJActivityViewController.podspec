Pod::Spec.new do |s|

  s.name         = "TJActivityViewController"

  s.version      = "0.0.1"

  s.summary      = "TJActivityViewController is a handy subclass of UIActivityViewController for simple customization for the iOS share sheet."

  s.homepage     = "https://github.com/timonus/TJActivityViewController"

  s.license      = { :type => "BSD 3-Clause License", :file => "LICENSE" }

  s.author       = { "Tim Johnsen" => "https://twitter.com/timonus" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/timonus/TJActivityViewController.git",  :tag => "0.0.1" }

  s.source_files  = "*.{h,m}"

  s.public_header_files = "*.h"

  s.frameworks = "Foundation", "UIKit"

  s.requires_arc = true

end