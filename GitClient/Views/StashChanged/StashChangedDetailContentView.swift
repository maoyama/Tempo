//
//  StashChangedDetailContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/15.
//

import SwiftUI

struct StashChangedDetailContentView: View {
    var diff: String
    var parsedDiff: Diff? {
        try? Diff(raw: diff)
    }

    var body: some View {
        ScrollView {
            if let fileDiffs = parsedDiff?.fileDiffs {
                FileDiffsView(fileDiffs: fileDiffs)
                    .padding()
            } else {
                VStack(alignment: .leading) {
                    Text(diff)
                }
            }
        }
        .textSelection(.enabled)
    }
}


#Preview {
    let diff = """
diff --git a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
index ca7d6df..b9d9984 100644
--- a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
+++ b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
@@ -24,7 +24,7 @@
     "repositoryURL": "https://github.com/onevcat/Kingfisher.git",
     "state": {
       "branch": null,
-          "revision": "7ccfb6cefdb6180cde839310e3dbd5b2d6fefee5",
+          "revision": "20d21b3fd7192a42851d7951453e96b41e4e1ed1",
       "version": "5.13.3"
     }
   }
diff --git a/GitBlamePR/View/DetailFooter.swift b/GitBlamePR/View/DetailFooter.swift
index ec290b6..46b0c19 100644
--- a/GitBlamePR/View/DetailFooter.swift
+++ b/GitBlamePR/View/DetailFooter.swift
@@ -6,6 +6,7 @@
//  Copyright © 2020 dev.aoyama. All rights reserved.
//

+// test
import SwiftUI

struct DetailFooter: View {
@@ -36,6 +37,9 @@ struct DetailFooter: View {
 }
}

+
+
+// test2
struct DetailFooter_Previews: PreviewProvider {
 static var previews: some View {
     Group {
diff --git a/testfile6.txt b/testfile6.txt
new file mode 100644
index 0000000..e69de29
"""

    return StashChangedDetailContentView(diff: diff)
}
