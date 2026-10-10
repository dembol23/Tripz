import SwiftUI

struct PassportView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Your passport",
                systemImage: "globe.europe.africa",
                description: Text("The countries and cities you've hiked in will be collected here.")
            )
            .navigationTitle("Passport")
        }
    }
}
