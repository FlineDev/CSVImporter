Pod::Spec.new do |s|

  s.name         = "CSVImporter"
  s.version      = "1.2.0"
  s.summary      = "Import CSV files line by line with ease."

  s.description  = <<-DESC
    CSVImporter works both asynchronously (prevents delays) and reads your CSV file line by line
    instead of loading the entire String into memory (prevents memory issues). On top of that it is
    easy to use and provides beautiful callbacks for indicating failure, progress, completion and
    even data mapping if you desire to.
                   DESC

  s.homepage     = "https://github.com/Flinesoft/CSVImporter"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }

  s.author             = { "Cihat Gündüz" => "CihatGuenduez@posteo.de" }
  s.social_media_url   = "https://twitter.com/Dschee"

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/Flinesoft/CSVImporter.git", :tag => "#{s.version}" }
  s.source_files  = "Sources", "Sources/**/*.swift"
  s.framework  = "Foundation"
  s.dependency "HandySwift", "~> 1.2"
  s.dependency "Dschee-FileKit", "~> 3.0"

end
