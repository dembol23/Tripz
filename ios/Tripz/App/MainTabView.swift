import SwiftUI

enum AppTab: Hashable {
    case feed, hikes, passport, profile
}

struct MainTabView: View {
    let dependencies: AppDependencies
    @State private var selection: AppTab = .feed

    var body: some View {
        TabView(selection: $selection) {
            Tab("Feed", systemImage: "rectangle.stack", value: AppTab.feed) {
                FeedView(dependencies: dependencies)
            }
            Tab("My Hikes", systemImage: "figure.hiking", value: AppTab.hikes) {
                HikesView(dependencies: dependencies)
            }
            Tab("Passport", systemImage: "globe.europe.africa", value: AppTab.passport) {
                PassportView()
            }
            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                ProfileView(dependencies: dependencies)
            }
        }
        .task { await dependencies.activities.run() }
    }
}
