import Foundation

func getAllSearchableBundles() -> [Bundle] {
    var bundles = Bundle.allBundles + Bundle.allFrameworks
    
    // Also look for .bundle files inside the main bundle (SPM resource bundles)
    if let urls = Bundle.main.urls(forResourcesWithExtension: "bundle", subdirectory: nil) {
        for url in urls {
            if let b = Bundle(url: url), !bundles.contains(b) {
                bundles.append(b)
            }
        }
    }
    return bundles
}
